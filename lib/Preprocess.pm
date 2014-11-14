package Preprocess;

use strict;
use warnings;

use Utilities;

sub QC	{
	(my $library, my $global_opt) = @_;

	my $lib_opt = $global_opt->{'library'}->{$library};
	
	print "Starts quality control of the library $library:\t".localtime()."\n";

	$lib_opt->{'qc'} = "original";

	if (defined($lib_opt->{'tm-minlen'}))	{
		&trimmomatic($library, $global_opt);
	}
	if (defined($lib_opt->{'nc-minlen'}))	{
		&nextclip($library, $global_opt);
	}
	if (defined($lib_opt->{'qk-minlen'}))	{
		&quake($library, $global_opt);
	}

	print "Quality control of the library $library finished.\n";

	return;
}

sub trimmomatic	{
	(my $library, my $global_opt) = @_;
	
	my $lib_opt = $global_opt->{'library'}->{$library};

	# set command to convert all fastq to phred33
	my $cmd = "java -jar $global_opt->{'bin'}->{'trimmomatic'} ".uc($lib_opt->{'read_type'})." -threads $global_opt->{'threads'}";
	if ($lib_opt->{'read_type'} eq "se")	{
		$cmd .= " $global_opt->{'out_dir'}/libraries/$library.fq $library.fq TOPHRED33";
	}	else	{
		$cmd .= " $global_opt->{'out_dir'}/libraries/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library\_2.fq $library\_1.fq temp_1.fq $library\_2.fq temp_2.fq TOPHRED33";
	}

	# run phred conversion command
	print "\tConversion to Phred33 starts:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");
	
	# cleanup empty temp files
	unless ($lib_opt->{'read_type'} eq "se")	{
		system("rm temp_1.fq temp_2.fq");
	}
	print "\tConversion to Phred33 finished.\n";

	# set command for Trimmomatic trimming
	$cmd = "java -jar $global_opt->{'bin'}->{'trimmomatic'} ".uc($lib_opt->{'read_type'})." -threads $global_opt->{'threads'}";
	# set input and output file names for SE and PE/MP data separately
	if ($lib_opt->{'read_type'} eq "se")    {
		$cmd .= " $library.fq $library.tm.fq";
	}	else	{
		$cmd .= " $library\_1.fq $library\_2.fq $library\_1.tm.fq $library\_1.tm-se.fq $library\_2.tm.fq $library\_2.tm-se.fq";
	}
	# set quality trimming
	if (defined($lib_opt->{'tm-trailing'}))	{
		$cmd .= " TRAILING:$lib_opt->{'tm-trailing'}";
	}
	# set adapter trimming
	if (defined($lib_opt->{'tm-adatper'}))	{
		$cmd .= " ILLUMINACLIP:$lib_opt->{'tm-adapter'}:2:30:10:1:true";
	}
	# set minimum length
	$cmd .= " MINLEN:$lib_opt->{'tm-minlen'}";

	# run Trimmomatic trimming
	print "\tTrimmomatic trimming starts:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");

	# combine unpaired reads
	system("cat $library\_1.tm-se.fq $library\_2.tm-se.fq > $library.tm.fq");
	system("rm $library\_1.tm-se.fq $library\_2.tm-se.fq");

	# update the last QC task performed
	$lib_opt->{'qc'} = "trimmomatic";
	print "\tTrimmomatic trimming finished.\n";
	
	return;
}

sub nextclip	{
	(my $library, my $global_opt) = @_;
	
	my $lib_opt = $global_opt->{'library'}->{$library};

	# set command
	my $cmd = "$global_opt->{'bin'}->{'nextclip'} -m $lib_opt->{'nc-minlen'} -o $library.nc";
	
	# set input file names for original and Trimmomatic processed data separately
	if ($lib_opt->{'qc'} eq "original")	{
		$cmd .= " -i $global_opt->{'out_dir'}/libraries/$library\_1.fq -j $global_opt->{'out_dir'}/libraries/$library\_2.fq";
	}	elsif ($lib_opt->{'qc'} eq "trimmomatic")	{
		$cmd .= " -i $library\_1.tm.fq -j $library\_2.tm.fq";
	}

	# run NextClip trimming
	print "\tNextClip adapter trimming starts:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");

	# combine output files
	system("cat $library.nc_A_R1.fastq $library.nc_B_R1.fastq $library.nc_C_R1.fastq $library.nc_D_R1.fastq > $library\_1.nc.fq");
	system("cat $library.nc_A_R2.fastq $library.nc_B_R2.fastq $library.nc_C_R2.fastq $library.nc_D_R2.fastq > $library\_2.nc.fq");
	system("rm $library.nc_R1_gc.txt $library.nc_R2_gc.txt $library.nc_duplicates.txt");
	foreach my $suffix (("$library.nc\_A", "$library.nc\_B", "$library.nc_C", "$library.nc_D"))	{
		system("rm $suffix\_pair_hist.txt $suffix\_R1_hist.txt $suffix\_R1.fastq $suffix\_R2_hist.txt $suffix\_R2.fastq");
	}

	# create a soft link for SE reads generate by Trimmomatiic
	if ($lib_opt->{'qc'} eq "trimmomatic")	{
		system("ln -s $library.tm.fq $library.nc.fq");
	}

	# update the last QC task performed
	$lib_opt->{'qc'} = "nextclip";
	print "\tNextClip adapter trimming finished.\n";

	return;	
}

sub quake	{
	(my $library, my $global_opt) = @_;

	my $lib_opt = $global_opt->{'library'}->{$library};
	
	mkdir("quake");
	chdir("quake");
	
	# estimate k-mer size if not provided
	if ($lib_opt->{'qk-kmer'} == 0)	{
		mkdir("quake_tmp");
		my $genomeSize = ($global_opt->{'genome_size'} == 0) ? &Utilities::genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};
		$lib_opt->{'qk-kmer'} = int(log(200*$genomeSize)/log(4) + 0.5);
	}

	# generate file list
	open QUAKE, "> $library.filelist" or die "Can't write to $library.filelist!\n";
	if ($lib_opt->{'qc'} eq "original")	{
		if ($lib_opt->{'read_type'} eq "se")	{
			system("ln -s $global_opt->{'out_dir'}/libraries/$library.fq $library.fq");
			print QUAKE "$library.fq\n";
		}	elsif ($lib_opt->{'read_type'} eq "pe")	{
			system("ln -s $global_opt->{'out_dir'}/libraries/$library\_1.fq $library\_1.fq");
			system("ln -s $global_opt->{'out_dir'}/libraries/$library\_2.fq $library\_2.fq");
			print QUAKE "$library\_1.fq $library\_2.fq\n";
		}
	}	elsif ($lib_opt->{'qc'} eq "trimmomatic")	{
		if ($lib_opt->{'read_type'} eq "se")	{
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq $library.fq");
			print QUAKE "$library.fq\n";
		}	elsif ($lib_opt->{'read_type'} eq "pe")	{
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $library\_1.fq");
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq $library\_2.fq");
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq $library.fq");
			print QUAKE "$library\_1.fq $library\_2.fq\n$library.fq\n";
		}
	}
	close(QUAKE);
	
	# set command
	my $cmd = "$global_opt->{'bin'}->{'quake'} -t $global_opt->{'threads'} -l $lib_opt->{'qk-minlen'} -k $lib_opt->{'qk-kmer'} -f $library.filelist";
	
	# run Quake error correction
	print "\tQuake error correction starts:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");

	# check if Quake runs into error
	my $err = 1;
	if ($lib_opt->{'read_type'} eq "se")	{
		if (-e "$library.cor.fq")	{
			system("mv $library.cor.fq ../$library.qk.fq");
			$err = 0;
		}
	}	elsif ($lib_opt->{'read_type'} eq "pe")	{
		if (-e "$library\_1.cor.fq")	{
			system("mv $library\_1.cor.fq ../$library\_1.qk.fq");
			system("mv $library\_2.cor.fq ../$library\_2.qk.fq");
			system("cat $library\_1.cor_single.fq $library\_2.cor_single.fq > ../$library.qk.fq");
			if ($lib_opt->{'qc'} eq "trimmomatic")	{
				system("cat $library.cor.fq >> ../$library.qk.fq");
			}
			$err = 0;
		}
	}
	
	if ($err)	{
		print "\tWARNING: No corrected reads found, Quake error correction failed.\n\n";
	}	else	{
		$lib_opt->{'qc'} = "quake";
		print "\tQuake error correction finished.\n";
	}

	chdir("..");
	system("rm -rf quake");

	return;
}

1;
