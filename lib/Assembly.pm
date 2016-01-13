package Assembly;

use strict;
use warnings;

use File::Basename;
use Utilities;

sub assemble	{
	(my $protocol, my $global_opt, my $overwrite, my $cleanup) = @_;
	
	# decide whether to redo the protocol
	if (-e "$global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa")	{
		if ($overwrite)	{
			system("rm $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
			if (-e "$global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa")	{
				system("rm $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
			}
		}	else	{
			print "NOTE: the assembly protocol $protocol already finished, skip to the next.\n\n";
			return;
		}
	}
		
	# remove files from previous run
	system("rm -rf *");
	
	# run the protocol
	if ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "abyss")	{
		&abyss($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "allpaths")	{
		&allpaths($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "ca")	{
		&ca($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "discovar")	{
		&discovar($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "masurca")	{
		&masurca($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "meraculous")	{
		&meraculous($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "minia")	{
		&minia($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "platanus")	{
		&platanus($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "sga")	{
		&sga($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "soapdenovo2")	{
		&soapdenovo2($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "spades")	{
		&spades($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "dipspades")	{
		&dipspades($protocol, $global_opt);
	}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "velvet")	{
		&velvet($protocol, $global_opt);
	}

	# clean up the folder
	if ($cleanup)	{
		system("rm -rf *");
	}

	return;
}

sub abyss	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set k-mer
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0, 1, 1, 0, 0);

	# set command
	my $cmd = "$global_opt->{'bin'}->{'abyss'} np=$global_opt->{'threads'} k=$kmer name=$protocol";
	if ($global_opt->{'protocol'}->{$protocol}->{'option'} =~ /\w/)	{
		$cmd .= " $global_opt->{'protocol'}->{$protocol}->{'option'}";
	}

	# set libraries
	my %data = &data($protocol, $global_opt, 0, 1, 1, 1);
	
	# SE libraries
	if (defined($data{'se'}))	{
		$cmd .= " se=\'".(join " ", sort values %{$data{'se'}})."\'";
	}
	
	# PE and HQMP libraries
	my @pe;
	if (defined($data{'pe'}))	{
		push @pe, sort keys %{$data{'pe'}};
	}
	if (defined($data{'hqmp'}))	{
		push @pe, sort keys %{$data{'hqmp'}};
	}
	if (@pe)	{
		my $lib = join " ", @pe;
		$cmd .= " lib=\'$lib\'";
		foreach my $library (@pe)	{
			my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
			$cmd .= " $library=\'$data{$read_type}->{$library}->[0] $data{$read_type}->{$library}->[1]\'";
		}
	}
	
	# MP libraries
	my @mp;
	if (defined($data{'mp'}))	{
		push @mp, sort keys %{$data{'mp'}};
	}
	if (@mp)	{
		my $mp = join " ", @mp;
		$cmd .= " mp=\'$mp\'";
		foreach my $library (@mp)	{
			$cmd .= " $library=\'$data{'mp'}->{$library}->[0] $data{'mp'}->{$library}->[1]\'";
		}
	}

	# run ABYSS
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# copy assembly files
	if (-e "$protocol\-contigs.fa")	{
		system("cp $protocol\-contigs.fa $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("cp $protocol\-scaffolds.fa $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub allpaths	{
	(my $protocol, my $global_opt) = @_;
	
	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# create the in_group.csv file
	open GROUPS, "> in_groups.csv" or die "Can't write to in_group.csv!\n";
	print GROUPS "group_name,library_name,file_name\n";

	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "clr")	{
			print GROUPS "$library,$library,$global_opt->{'out_dir'}/libraries/$library/$library.fq\n";
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} =~ /^(pe|mp|hqmp)$/)	{
			print GROUPS "$library,$library,$global_opt->{'out_dir'}/libraries/$library/$library\_*.fq\n";
		}
	}
	close (GROUPS);

	# create the in_lib.csv file
	open LIBS, "> in_libs.csv" or die "Can't write to in_libs.csv\n";
	print LIBS "library_name,project_name,organism_name,type,paired,frag_size,frag_stddev,insert_size,insert_stddev,read_orientation,genomic_start,genomic_end\n";
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "clr")	{
			print LIBS "$library,iWGS,unnamed,long,0,,,,,,,\n";
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
			print LIBS "$library,iWGS,unnamed,fragment,1,$global_opt->{'library'}->{$library}->{'frag_mean'},$global_opt->{'library'}->{$library}->{'frag_sd'},,,inward,,\n";
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "hqmp")	{
			print LIBS "$library,iWGS,unnamed,jumping,1,$global_opt->{'library'}->{$library}->{'frag_mean'},$global_opt->{'library'}->{$library}->{'frag_sd'},,,inward,,\n";
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
			print LIBS "$library,iWGS,unnamed,jumping,1,,,$global_opt->{'library'}->{$library}->{'frag_mean'},$global_opt->{'library'}->{$library}->{'frag_sd'},outward,,\n";
		}
	}
	close (LIBS);
	
	# preapre the data
	mkdir("mydata");
	my $preapre_bin = dirname($global_opt->{'bin'}->{'allpaths'})."/PrepareAllPathsInputs.pl";
	my $cmd = "$preapre_bin DATA_DIR=$global_opt->{'out_dir'}/protocols/$protocol/mydata PLOIDY=$global_opt->{'protocol'}->{$protocol}->{'ploidy'}";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# run ALLPATHS-LG
	$cmd = "$global_opt->{'bin'}->{'allpaths'} PRE=$global_opt->{'out_dir'}/protocols DATA_SUBDIR=mydata RUN=myrun REFERENCE_NAME=$protocol TARGETS=standard THREADS=$global_opt->{'threads'}";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# create hard link of assembly files
	if (-e "mydata/myrun/ASSEMBLIES/test/final.contigs.fasta")	{
		system("ln mydata/myrun/ASSEMBLIES/test/final.contigs.fasta $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln mydata/myrun/ASSEMBLIES/test/final.assembly.fasta $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub ca	{
	(my $protocol, my $global_opt) = @_;
	
	print "Starts the assembly protocol $protocol:\t".localtime()."\n";

	# set command
	my $cmd;
	my $genomeSize = ($global_opt->{'genome_size'} == 0) ? &Utilities::genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};

	# set libraries
	my %data = &data($protocol, $global_opt, 0, 1, 1, 1);

	# preapre illumina data frg files
	my @frg;
	my $fastqToCA_bin = ((defined($global_opt->{'bin'}->{'pbcr'})) ? dirname($global_opt->{'bin'}->{'pbcr'}) : dirname($global_opt->{'bin'}->{'runca'}))."/fastqToCA";

	# SE libraries
	if (defined($data{'se'}))	{
		foreach my $library (sort keys %{$data{'se'}})	{
			my $technology = ($global_opt->{'library'}->{$library}->{'read_length'} > 160) ? "illumina-long" : "illumina";
			$cmd = "$fastqToCA_bin -libraryname $library -technology $technology -reads $data{'se'}->{$library} > $library.frg";
			&Utilities::execute_cmd2($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
			push @frg, "$global_opt->{'out_dir'}/protocols/$protocol/$library.frg";
		}
	}
	
	# PE and HQMP libraries
	my @pe;
	if (defined($data{'pe'}))	{
		push @pe, sort keys %{$data{'pe'}};
	}
	if (defined($data{'hqmp'}))	{
		push @pe, sort keys %{$data{'hqmp'}};
	}
	if (@pe)	{
		foreach my $library (@pe)	{
			my $technology = ($global_opt->{'library'}->{$library}->{'read_length'} > 160) ? "illumina-long" : "illumina";
			$cmd = "$fastqToCA_bin -libraryname $library -technology $technology -insertsize $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} -mates $data{'pe'}->{$library}->[0],$data{'pe'}->{$library}->[1] > $library.frg";
			&Utilities::execute_cmd2($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
			push @frg, "$global_opt->{'out_dir'}/protocols/$protocol/$library.frg";
		}
	}

	# decide which type of assembly to perform
	if (defined($data{'clr'}))	{
		# merge multiple PacBio CLR libraries to one
		my @clr = keys %{$data{'clr'}};

		if (scalar @clr > 1)	{
			foreach my $library (@clr)	{
				system("cat $data{'clr'}->{$library} >> pacbio_clr.fq");
			}
		}	else	{
			 system("ln $data{'clr'}->{$clr[0]} pacbio_clr.fq");
		}
	
		# create the "pacbio.spec" filfe
		system("touch pacbio.spec");
	
		$cmd = "$global_opt->{'bin'}->{'pbcr'} -threads $global_opt->{'threads'} pbcns=".$global_opt->{'protocol'}->{$protocol}->{'pbcns'};
		if ($global_opt->{'protocol'}->{$protocol}->{'sensitive'}) 	{
			$cmd .= " -sensitive";
		}
		if (@frg)	{
			# hybrid assembly
			$cmd .= " -l $protocol -genomeSize $genomeSize -s pacbio.spec -fastq $global_opt->{'out_dir'}/protocols/$protocol/pacbio_clr.fq ".(join " ", @frg);
		}	else	{
			# PacBio only assembly
			$cmd .= " -l $protocol -genomeSize $genomeSize -s pacbio.spec -fastq $global_opt->{'out_dir'}/protocols/$protocol/pacbio_clr.fq";
		}
	}	else	{
		# illumina only assembly
		# make frg files for MP libraries
		if (defined($data{'mp'}))	{
			foreach my $library (sort keys %{$data{'mp'}})	{
				my $technology = ($global_opt->{'library'}->{$library}->{'read_length'} > 160) ? "illumina-long" : "illumina";
				$cmd = "$fastqToCA_bin -libraryname $library -technology $technology -outtie -insertsize $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} -mates $data{'mp'}->{$library}->[0],$data{'mp'}->{$library}->[1] > $library.frg";
				&Utilities::execute_cmd2($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
				push @frg, "$global_opt->{'out_dir'}/protocols/$protocol/$library.frg";
			}
		}
	
		# make config file
		open CONF, "> config" or die "Can't write to CA configuration file!\n ";	
		print CONF "unitigger = bog\n";
		close (CONF);
		$cmd = "$global_opt->{'bin'}->{'runca'} -d . -p $protocol -s config ".(join " ", @frg);
	}

	# run CA
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# create hard link of assembly files
	if (-e "$protocol/9-terminator/asm.ctg.fasta")	{
		system("ln $protocol/9-terminator/asm.ctg.fasta $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln $protocol/9-terminator/asm.scf.fasta $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		#system("ln $protocol/9-terminator/asm.utg.fasta $global_opt->{'out_dir'}/assemblies/$protocol.utg.fa");
		#system("ln $protocol/9-terminator/asm.deg.fasta $global_opt->{'out_dir'}/assemblies/$protocol.deg.fa");
		#system("ln $protocol/9-terminator/asm.singleton.fasta $global_opt->{'out_dir'}/assemblies/$protocol.singleton.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub discovar	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# DEPRECATED CODE: earlier version of DISCOVAR requires BAM file as input, and only supports a single input library
	# convert FastQ to BAM
	# my $library = ${$global_opt->{'protocol'}->{$protocol}->{'library'}}[0];
	# my $cmd = "java -jar $global_opt->{'bin'}->{'picard'} FastqToSam F1=$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq F2=$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq SM=$library O=$library.bam";
	# &Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	# run DISCOVAR
	# $cmd = "$global_opt->{'bin'}->{'discovar'} READS=$library.bam NUM_THREADS=$global_opt->{'threads'} OUT_DIR=.";
	# &Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# run DISCOVAR
	my $cmd = "$global_opt->{'bin'}->{'discovar'} NUM_THREADS=$global_opt->{'threads'} OUT_DIR=. MAX_MEM_GB=$global_opt->{'memory'} READS=";
	if ($#{$global_opt->{'protocol'}->{$protocol}->{'library'}} == 0)	{
		my $library = ${$global_opt->{'protocol'}->{$protocol}->{'library'}}[0];
		$cmd .= "$global_opt->{'out_dir'}/libraries/$library/$library\_*.fq";
	}	else	{
		my @library;
		foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
			push @library, "sample:$library :: $global_opt->{'out_dir'}/libraries/$library/$library\_*.fq";
		}
		$cmd .= "\"".(join " + ", @library)."\"";
	}
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# create hard link of assembly files
	if (-e "a.final/a.lines.fasta")	{
		system("ln a.final/a.lines.fasta $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln a.final/a.lines.fasta $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}
	
	return;
}

sub masurca	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# create configuration file
	open CONF, "> config" or die "Can't write to MaSuRCA configuration file!\n";
	print CONF "DATA\n";

	# set suffix for each library
	my @name = split //, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
	
	# set libraries
	my %data;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se")	{
			$data{'se'}->{$library} = "$global_opt->{'out_dir'}/libraries/$library/$library.fq";
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
			$data{'pe'}->{$library} = [ ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq") ];
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
			$data{'mp'}->{$library} = [ ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq") ];
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "hqmp")	{
			if (-e "$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq" && -e "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq")	{
				$data{'pe'}->{$library} = [ ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq") ];
				if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq")	{
					$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq";
				}
			}	else	{
				$data{'pe'}->{$library} = [ ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq") ];	
			}
		}
	}

	# SE libraries
	if (defined($data{'se'}))	{
		foreach my $library (sort keys %{$data{'se'}})	{
			print CONF "PE=s$name[0] $global_opt->{'library'}->{$library}->{'read_length'} 1 $data{'se'}->{$library}\n";
			shift @name;
		}
	}
	
	# PE and HQMP libraries
	if (defined($data{'pe'}))	{
		foreach my $library (sort keys %{$data{'pe'}})	{
			print CONF "PE=p$name[0] $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} $data{'pe'}->{$library}->[0] $data{'pe'}->{$library}->[1]\n";
			shift @name;
		}
	}
	
	# MP libraries
	if (defined($data{'mp'}))	{
		foreach my $library (sort keys %{$data{'mp'}})	{
			my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
			print CONF "JUMP=j$name[0] $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} $data{$read_type}->{$library}->[0] $data{$read_type}->{$library}->[1]\n";
			shift @name;
		}
	}

	print CONF "END\n\nPARAMETERS\nUSE_LINKING_MATES = 1\nNUM_THREADS=$global_opt->{'threads'}\n";

	# set k-mer
	if ($global_opt->{'protocol'}->{$protocol}->{'kmer'} == 0)	{
		print CONF "GRAPH_KMER_SIZE = auto\n";
	}	else	{
		print CONF "GRAPH_KMER_SIZE = $global_opt->{'protocol'}->{$protocol}->{'kmer'}\n";
	}

	# set JF_SIZE
	my $genomeSize = ($global_opt->{'genome_size'} == 0) ? &Utilities::genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};
	my $total_cov = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		$total_cov += $global_opt->{'library'}->{$library}->{'depth'};
	}
	print CONF "JF_SIZE=".(10*$genomeSize)."\nEND\n";
	close (CONF);
	
	# run MaSuRCA
	my $cmd = "$global_opt->{'bin'}->{'masurca'} config";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	$cmd = "./assemble.sh";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# copy assembly files
	if (-e "CA/9-terminator/genome.ctg.fasta")	{
		system("ln CA/9-terminator/genome.ctg.fasta $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln CA/9-terminator/genome.scf.fasta $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub meraculous	{
	(my $protocol, my $global_opt) = @_;
			
	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set libraries
	my %data = &data($protocol, $global_opt, 0, 1, 0, 1);
	my $max_rd_len = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		$max_rd_len = ($max_rd_len >= $global_opt->{'library'}->{$library}->{'read_length'}) ? $max_rd_len : $global_opt->{'library'}->{$library}->{'read_length'};
	}
	
	# set configuration file
	open CONF, "> config" or die "Can't write to SOAPdenovo2 configuration file!\n";
	
	my $scaf_rank = 1;
	# PE libraries
	if (defined($data{'pe'}))	{
		foreach my $library (sort keys %{$data{'pe'}})	{
			print CONF "lib_seq $data{'pe'}->{$library}->[0],$data{'pe'}->{$library}->[1] $library $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} $global_opt->{'library'}->{$library}->{'read_length'} 0 0 1 $scaf_rank 1 0 0\n";
		}
		$scaf_rank++;
	}
	
	# HQMP libraries
	if (defined($data{'hqmp'}))	{
		foreach my $library (sort keys %{$data{'hqmp'}})	{
			print CONF "lib_seq $data{'hqmp'}->{$library}->[0],$data{'hqmp'}->{$library}->[1] $library $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} $global_opt->{'library'}->{$library}->{'read_length'} 0 0 1 $scaf_rank 1 0 0\n";
		}
		$scaf_rank++;
	}

	# MP libraries
	if (defined($data{'mp'}))	{
		foreach my $library (sort keys %{$data{'mp'}})	{
			print CONF "lib_seq $data{'mp'}->{$library}->[0],$data{'mp'}->{$library}->[1] $library $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} $global_opt->{'library'}->{$library}->{'read_length'} 0 1 0 $scaf_rank 0 0 0\n";
		}
	}
	
	# set genome size
	my $genomeSize = ($global_opt->{'genome_size'} == 0) ? &Utilities::genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};
	print CONF "genome_size\t".($genomeSize/1000000000)."\n";

	# set diploidy
	print CONF "is_diploid\t$global_opt->{'protocol'}->{$protocol}->{'diploid'}\n";

	# set k-mer
	# use KmerGenie
	#my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0, 0, 1, $global_opt->{'protocol'}->{$protocol}->{'diploid'}, 0);
	#print CONF "mer_size\t$kmer\n";
	# use the ballpark estimation from Meraculous
	print CONF "mer_size\t$global_opt->{'protocol'}->{$protocol}->{'kmer'}\n";
	
	# set other parameters
	print CONF "num_prefix_blocks\t4\n";
	print CONF "no_read_validation\t1\n";
	print CONF "fallback_on_est_insert_size\t1\n";
	print CONF "local_num_procs\t$global_opt->{'threads'}\n";
	print CONF "local_max_memory\t$global_opt->{'memory'}\n";

	close (CONF);

	# set command
	my $cmd = "$global_opt->{'bin'}->{'meraculous'} -dir . -cleanup_level 2 -c config";

	# run SOAPdenovo2
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# create hard link of assembly files
	if (-e "meraculous_merblast/")	{
		system("ln meraculous_merblast/contigs.fa $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln meraculous_final_results/final.scaffolds.fa $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub minia	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set libraries
	my %data = &data($protocol, $global_opt, 0, 0, 1, 1);
	
	# SE libraries
	if (defined($data{'se'}))	{
		foreach my $library (sort keys %{$data{'se'}})	{
			system("cat $data{'se'}->{$library} >> $protocol.fq");
		}
	}
	
	# PE and HQMP libraries
	my @pe;
	if (defined($data{'pe'}))	{
		push @pe, sort keys %{$data{'pe'}};
	}
	if (defined($data{'hqmp'}))	{
		push @pe, sort keys %{$data{'hqmp'}};
	}
	if (@pe)	{
		foreach my $library (@pe)	{
			my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
			system("cat $data{$read_type}->{$library}->[0] $data{$read_type}->{$library}->[1] >> $protocol.fq");
		}
	}
	
	# set k-mer and min-abundance
	my @kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0, 1, 1, 0, 1);
	$kmer[0] = ($kmer[0] > 1) ? $kmer[0] : 2;

	# DEPRECATED CODE: Minia v2.0.1 does not require this parameter any more
	# estimate genome size
	# my $genomeSize = ($global_opt->{'genome_size'} == 0) ? &Utilities::genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};
	# set command
	# my $cmd = "$global_opt->{'bin'}->{'minia'} $protocol.fq $kmer->[0] $kmer->[1] $genomeSize $protocol";
	
	# set command
	my $cmd = "$global_opt->{'bin'}->{'minia'} -in $protocol.fq -kmer-size $kmer[1] -abundance-min $kmer[0] -out $protocol";

	# run Minia
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# copy assembly files
	if (-e "$protocol.contigs.fa")	{
		system("ln $protocol.contigs.fa $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln $protocol.contigs.fa $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub platanus	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set libraries
	my %data = &data($protocol, $global_opt, 0, 1, 1, 1);
	
	# collect all libraries for assembly, and PE/MP/HQMP libraries for scaffolding
	my $assembly_libs = "-f"; my $scaffolding_libs;
	if (defined($data{'se'}))	{
		$assembly_libs .= " ".(join " ", sort values %{$data{'se'}});
	}
	
	# PE nad HQMP libraries
	my @pe;
	if (defined($data{'pe'}))	{
		push @pe, sort keys %{$data{'pe'}};
	}
	if (defined($data{'hqmp'}))	{
		push @pe, sort keys %{$data{'hqmp'}};
	}
	my $pe_num = 1;
	if (@pe)	{
		foreach my $library (@pe)	{
			my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
			$assembly_libs .= " $data{$read_type}->{$library}->[0] $data{$read_type}->{$library}->[1]";
			$scaffolding_libs = " -IP$pe_num $data{$read_type}->{$library}->[0] $data{$read_type}->{$library}->[1]";
			$pe_num++;
		}
	}
	
	# MP libraries
	my $mp_num = 1;
	if (defined($data{'mp'}))	{
		foreach my $library (sort keys %{$data{'mp'}})	{
			$scaffolding_libs = " -OP$mp_num $data{'mp'}->{$library}->[0] $data{'mp'}->{$library}->[1]";
			$mp_num++;
		}
	}

	# Platanus assembly consists of three step: assemble, scaffold, and gap close
	# 1. contig assembly
	my $cmd = "$global_opt->{'bin'}->{'platanus'} assemble -t $global_opt->{'threads'} -m $global_opt->{'memory'} -o $protocol";
	if ($global_opt->{'protocol'}->{$protocol}->{'kmer'})	{
		$cmd .= " -k $global_opt->{'protocol'}->{$protocol}->{'kmer'}";
	}
	if (defined($global_opt->{'protocol'}->{$protocol}->{'option'}))	{
		$cmd .= " $global_opt->{'protocol'}->{$protocol}->{'option'}";
	}
	$cmd .= " $assembly_libs";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# 2. scaffolding
	$cmd = "$global_opt->{'bin'}->{'platanus'} scaffold -t $global_opt->{'threads'} -o $protocol -c $protocol\_contig.fa -b $protocol\_contigBubble.fa $scaffolding_libs";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# 3. gap close
	$cmd = "$global_opt->{'bin'}->{'platanus'} gap_close -t $global_opt->{'threads'} -o $protocol -c $protocol\_scaffold.fa $scaffolding_libs";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");	

	# copy assembly files
	if (-e "$protocol\_contig.fa")	{
		system("ln $protocol\_contig.fa $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln $protocol\_gapClosed.fa $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub sga	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set libraries
	my %lib; my $max_rd_len = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		push @{$lib{$global_opt->{'library'}->{$library}->{'read_type'}}}, $library;
		$max_rd_len = ($max_rd_len >= $global_opt->{'library'}->{$library}->{'read_length'}) ? $max_rd_len : $global_opt->{'library'}->{$library}->{'read_length'};
	}

	# SGA run consists of multiple steps:
	# 0. merge all SE/PE/HQMP reads into one file; SGA uses original or Trimmomatic/NextClip trimmed reads; keep track of files for scaffolding
	mkdir("sga_tmp");
	my %scaf_lib;
	# SE libraries
	if (defined($lib{'se'}))	{
		foreach my $library (@{$lib{'se'}})	{
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original" || !(-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq"))	{
				system("cat $global_opt->{'out_dir'}/libraries/$library/$library.fq >> sga_tmp/$protocol.fq");
			}	else	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq >> sga_tmp/$protocol.fq");
			}
		}
	}
	# PE libraries
	if (defined($lib{'pe'}))	{
		foreach my $library (@{$lib{'pe'}})	{
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original" || !(-s "$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq" && -s "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq"))	{
				system("cat $global_opt->{'out_dir'}/libraries/$library/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library/$library\_2.fq >> sga_tmp/$protocol.fq");
				push @{$scaf_lib{$library}}, ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq");
			}	else	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq >> sga_tmp/$protocol.fq");
				push @{$scaf_lib{$library}}, ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq");
				if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq")	{
					system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq >> sga_tmp/$protocol.fq");
				}
			}
		}
	}
	# MP libraries
	if (defined($lib{'mp'}))	{
		foreach my $library (@{$lib{'mp'}})	{
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				push @{$scaf_lib{$library}}, ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq");
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				push @{$scaf_lib{$library}}, ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq");
			}
		}
	}
	# HQMP libraries
	if (defined($lib{'hqmp'}))	{
		foreach my $library (@{$lib{'hqmp'}})	{
			my $qc_status;
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$qc_status = "original";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$qc_status = "trimmomatic";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip")	{
				$qc_status = "nextclip";
			}	else	{
				if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq" && -s "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq")	{
					$qc_status = "trimmomatic";
				}	elsif (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq" && -s "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq")	{
					$qc_status = "nextclip";
				}	else	{
					$qc_status = "original";
				}
			}

			if ($qc_status eq "original")	{
				system("cat $global_opt->{'out_dir'}/libraries/$library/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library/$library\_2.fq >> sga_tmp/$protocol.fq");
				push @{$scaf_lib{$library}}, ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq");
			}	elsif ($qc_status eq "nextclip")	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq >> sga_tmp/$protocol.fq");
				push @{$scaf_lib{$library}}, ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq");
				if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq")	{
					system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq >> sga_tmp/$protocol.fq");
				}
			}	elsif ($qc_status eq "trimmomatic")	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq >> sga_tmp/$protocol.fq");
				push @{$scaf_lib{$library}}, ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq");
				if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq")	{
					system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq >> sga_tmp/$protocol.fq");
				}
			}	
		}
	}
	
	# 1. preprocess
	print "\tstep 1: preprocess\n";
	my $cmd = "$global_opt->{'bin'}->{'sga'} preprocess -o $protocol.pp.fq sga_tmp/$protocol.fq";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	system("rm -rf sga_tmp");

	# 2. 1st index
	print "\tstep 2: 1st index\n";
	my $alg = ($max_rd_len < 200) ? "ropebwt" : "sais";
	$cmd = "$global_opt->{'bin'}->{'sga'} index -a $alg -t $global_opt->{'threads'} --no-reverse $protocol.pp.fq";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# 3. correct
	print "\tstep 3: correct\n";
	$cmd = "$global_opt->{'bin'}->{'sga'} correct -k $global_opt->{'protocol'}->{$protocol}->{'kmer'} --learn -t $global_opt->{'threads'} -o $protocol.ec.fq $protocol.pp.fq";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# 4. 2nd index
	print "\tstep 4: 2nd index\n";
	$cmd = "$global_opt->{'bin'}->{'sga'} index -a $alg -t $global_opt->{'threads'} $protocol.ec.fq";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# 5. filter
	print "\tstep 5: filter\n";
	$cmd = "$global_opt->{'bin'}->{'sga'} filter -t $global_opt->{'threads'} $protocol.ec.fq";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# 6. overlap
	print "\tstep 6: overlap\n";
	$cmd = "$global_opt->{'bin'}->{'sga'} overlap -m $global_opt->{'protocol'}->{$protocol}->{'min-overlap'} -t $global_opt->{'threads'} $protocol.ec.filter.pass.fa";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# 7. assemble
	print "\tstep 7: assemble\n";
	$cmd = "$global_opt->{'bin'}->{'sga'} assemble -m $global_opt->{'protocol'}->{$protocol}->{'assemble-overlap'} -o $protocol $protocol.ec.filter.pass.asqg.gz";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	print "\tContig level assembly finished!\n";
	
	# Check if the programs required for scaffolding are available
	if (defined($global_opt->{'bin'}->{'bwa'}) && -e $global_opt->{'bin'}->{'bwa'} && defined($global_opt->{'bin'}->{'samtools'}) && -e $global_opt->{'bin'}->{'samtools'})	{
		# 8. bwa index
		print "\tstep 9: build BWA index\n";
		$cmd = "$global_opt->{'bin'}->{'bwa'} index $protocol\-contigs.fa";
		&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

		# 9. bwa mapping
		print "\tstep 10: BWA mapping of PE/MP/HQMP libraries\n";
		my @max_cov_lib = (0, 0);
		foreach my $library (sort keys %scaf_lib)	{
			if ($global_opt->{'library'}->{$library}->{'depth'} > $max_cov_lib[0])	{
				@max_cov_lib = ($global_opt->{'library'}->{$library}->{'depth'}, $library);
			}
			$cmd = "$global_opt->{'bin'}->{'bwa'} aln -t $global_opt->{'threads'} $protocol\-contigs.fa $scaf_lib{$library}->[0] > $library\_1.sai";
			&Utilities::execute_cmd2($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
			$cmd = "$global_opt->{'bin'}->{'bwa'} aln -t $global_opt->{'threads'} $protocol\-contigs.fa $scaf_lib{$library}->[1] > $library\_2.sai";
			&Utilities::execute_cmd2($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
			$cmd = "$global_opt->{'bin'}->{'bwa'} sampe $protocol\-contigs.fa $library\_1.sai $library\_2.sai $scaf_lib{$library}->[0] $scaf_lib{$library}->[1] > $library.sam";
			&Utilities::execute_cmd2($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
			$cmd = "$global_opt->{'bin'}->{'samtools'} view -@ $global_opt->{'threads'} -Sb $library.sam > $library.bam";
			&Utilities::execute_cmd2($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
			my $bam2de_bin = dirname($global_opt->{'bin'}->{'sga'})."/sga-bam2de.pl";
			$cmd = "$bam2de_bin --prefix $library -n 5 $library.bam";
			&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
		}
		
		# 10. generate A-statistics
		print "\tstep 11: generate A-statistics\n";
		$cmd = "$global_opt->{'bin'}->{'samtools'} sort -@ $global_opt->{'threads'} $max_cov_lib[1].bam $max_cov_lib[1].sort";
		&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
		my $astat_bin = dirname($global_opt->{'bin'}->{'sga'})."/sga-astat.py";
		$cmd = "$astat_bin -m 200 $max_cov_lib[1].sort.bam > contigs.astat";
		&Utilities::execute_cmd2($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
		
		# 11. scaffolding
		print "\tstep 12: scaffolding\n";
		$cmd = "$global_opt->{'bin'}->{'sga'} scaffold -m 200 -a contigs.astat -o $protocol\-scaf";
		foreach my $library (sort keys %scaf_lib)	{
			if ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
				$cmd .= " --pe $library.de";
			}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "hqmp")	{
				$cmd .= " --pe $library.de";
			}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
				$cmd .= " --mate $library.de";
			}
		}
		$cmd .= " $protocol\-contigs.fa";
		&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

		# 12. generate fasta file
		print "\tstep 13: generate scaffolds.fa\n";
		$cmd = "$global_opt->{'bin'}->{'sga'} scaffold2fasta --write-unplaced -m 200 -o $protocol\-scaffolds.fa -a $protocol\-graph.asqg.gz -o $protocol\-scaffolds.fa $protocol\-scaf";
		&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	}	else	{
		print "\tWARNING: the tools \"BWA\" and \"SAMtools\" are not available, will not perform scaffolding.\n";
	}

	# copy assembly files
	if (-e "$protocol\-contigs.fa")	{
		system("ln $protocol\-contigs.fa $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln $protocol\-scaffolds.fa $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub soapdenovo2	{
	(my $protocol, my $global_opt) = @_;
			
	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set libraries
	my %data = &data($protocol, $global_opt, 0, 1, 1, 1);
	my $max_rd_len = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		$max_rd_len = ($max_rd_len >= $global_opt->{'library'}->{$library}->{'read_length'}) ? $max_rd_len : $global_opt->{'library'}->{$library}->{'read_length'};
	}
	
	# set configuration file
	my @conf;
	push @conf, "max_rd_len=$max_rd_len\n";
	
	# SE libraries
	if (defined($data{'se'}))	{
		foreach my $library (sort keys %{$data{'se'}})	{
			push @conf, "[LIB]\n";
			push @conf, "reverse_seq=0\n";
			push @conf, "asm_flags=1\n";
			push @conf, "q=$data{'se'}->{$library}\n";
		}
	}

	# PE libraries
	if (defined($data{'pe'}))	{
		foreach my $library (sort keys %{$data{'pe'}})	{
			push @conf, "[LIB]\n";
			push @conf, "avg_ins=$global_opt->{'library'}->{$library}->{'frag_mean'}\n";
			push @conf, "reverse_seq=0\n";
			push @conf, "asm_flags=3\n";
			push @conf, "rank=1\n";
			push @conf, "pair_num_cutoff=3\n";
			push @conf, "map_len=32\n";
			push @conf, "q1=$data{'pe'}->{$library}->[0]\n";
			push @conf, "q2=$data{'pe'}->{$library}->[1]\n";
		}
	}
	
	# HQMP libraries
	if (defined($data{'hqmp'}))	{
		foreach my $library (sort keys %{$data{'hqmp'}})	{
			push @conf, "[LIB]\n";
			push @conf, "avg_ins=$global_opt->{'library'}->{$library}->{'frag_mean'}\n";
			push @conf, "reverse_seq=0\n";
			push @conf, "asm_flags=3\n";
			push @conf, "rank=2\n";
			push @conf, "pair_num_cutoff=5\n";
			push @conf, "map_len=35\n";
			push @conf, "q1=$data{'hqmp'}->{$library}->[0]\n";
			push @conf, "q2=$data{'hqmp'}->{$library}->[1]\n";
		}
	}

	# MP libraries
	if (defined($data{'mp'}))	{
		foreach my $library (sort keys %{$data{'mp'}})	{
			push @conf, "[LIB]\n";
			push @conf, "avg_ins=$global_opt->{'library'}->{$library}->{'frag_mean'}\n";
			push @conf, "reverse_seq=1\n";
			push @conf, "asm_flags=2\n";
			push @conf, "rank=3\n";
			push @conf, "pair_num_cutoff=5\n";
			push @conf, "map_len=35\n";
			push @conf, "q1=$data{'mp'}->{$library}->[0]\n";
			push @conf, "q2=$data{'mp'}->{$library}->[1]\n";
		}
	}
	
	open CONF, "> config" or die "Can't write to SOAPdenovo2 configuration file!\n";
	print CONF @conf;
	close (CONF);

	# set k-mer
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0, 1, 1, 0, 0);

	# set command
	my $cmd = "$global_opt->{'bin'}->{'soapdenovo2'} all -s config -k $kmer -p $global_opt->{'threads'} -o $protocol";
	if (defined($global_opt->{'protocol'}->{$protocol}->{'option'}))	{
		$cmd .= " $global_opt->{'protocol'}->{$protocol}->{'option'}";
	}

	# run SOAPdenovo2
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# create hard link of assembly files
	if (-e "$protocol.contig")	{
		system("ln $protocol.contig $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln $protocol.scafSeq $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub spades	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set libraries
	my %data = &data($protocol, $global_opt, 0, 1, 1, 1);
	my $max_rd_len = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		next unless (exists($global_opt->{'library'}->{$library}->{'read_length'}));
		$max_rd_len = ($max_rd_len >= $global_opt->{'library'}->{$library}->{'read_length'}) ? $max_rd_len : $global_opt->{'library'}->{$library}->{'read_length'};
	}
	
	my %lib_num = (
		'se' => 1,
		'pe' => 1,
		'mp' => 1,
		'hqmp' => 1,
	);
	
	my $libs;

	# PacBio CLR libraries
	if (defined($data{'clr'}))	{
		foreach my $library (sort keys %{$data{'clr'}})	{
			$libs .= " --pacbio $global_opt->{'out_dir'}/libraries/$library/$library.fq";
		}
	}

	# SE libraries
	if (defined($data{'se'}))	{
		foreach my $library (sort keys %{$data{'se'}})	{
			$libs .= " --s$lib_num{'se'} $data{'se'}->{$library}";
			$lib_num{'se'}++;
		}
	}

	# PE, MP, and HQMP libraries
	my @libs;
	if (defined($data{'pe'}))	{
		push @libs, sort keys %{$data{'pe'}};
	}
	if (defined($data{'mp'}))	{
		push @libs, sort keys %{$data{'mp'}};
	}
	if (defined($data{'hqmp'}))	{
		push @libs, sort keys %{$data{'hqmp'}};
	}
	if (@libs)	{
		foreach my $library (@libs)	{
			my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
			$libs .= " --$read_type".$lib_num{$read_type}."-1 $data{$read_type}->{$library}->[0] --$read_type".$lib_num{$read_type}."-2 $data{$read_type}->{$library}->[1]";
			$lib_num{$read_type}++;
		}
	}
	
	# set k-mer
	my %kmer;
	if ($global_opt->{'protocol'}->{$protocol}->{'multi-kmer'})	{
		%kmer = (
			'21' => 1,
			'33' => 1,
			'55' => 1,
		);
		if ($max_rd_len >= 150)	{
			$kmer{'77'} = 1;
		}
		if ($max_rd_len >= 250)	{
			$kmer{'99'} = 1;
			$kmer{'127'} = 1;
		}
	}
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0, 1, 1, 0, 0);
	$kmer{$kmer} = 1;
	$kmer = join ",", sort {$a<=>$b} keys %kmer;

	# set command
	my $cmd = $global_opt->{'bin'}->{'spades'};
	if ($global_opt->{'protocol'}->{$protocol}->{'option'} =~ /\w/)	{
		$cmd .= " $global_opt->{'protocol'}->{$protocol}->{'option'}";
	}
	$cmd .= " -k $kmer $libs -t $global_opt->{'threads'} -m $global_opt->{'memory'} -o .";
	
	# run SPAdes
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# create hard link of assembly files
	if (-e "contigs.fasta")	{
		system("ln contigs.fasta $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln scaffolds.fasta $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub dipspades	{
	(my $protocol, my $global_opt) = @_;
	
	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set libraries
	my %data = &data($protocol, $global_opt, 0, 1, 1, 1);
	my $max_rd_len = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		$max_rd_len = ($max_rd_len >= $global_opt->{'library'}->{$library}->{'read_length'}) ? $max_rd_len : $global_opt->{'library'}->{$library}->{'read_length'};
	}
	
	my %lib_num = (
		'se' => 1,
		'pe' => 1,
		'mp' => 1,
		'hqmp' => 1,
	);
	
	my $libs;

	# PacBio CLR libraries
	if (defined($data{'clr'}))	{
		foreach my $library (sort keys %{$data{'clr'}})	{
			$libs .= " --pacbio $global_opt->{'out_dir'}/libraries/$library/$library.fq";
		}
	}

	# SE libraries
	if (defined($data{'se'}))	{
		foreach my $library (sort keys %{$data{'se'}})	{
			$libs .= " --s$lib_num{'se'} $data{'se'}->{$library}";
			$lib_num{'se'}++;
		}
	}

	# PE, MP, and HQMP libraries
	my @libs;
	if (defined($data{'pe'}))	{
		push @libs, sort keys %{$data{'pe'}};
	}
	if (defined($data{'mp'}))	{
		push @libs, sort keys %{$data{'mp'}};
	}
	if (defined($data{'hqmp'}))	{
		push @libs, sort keys %{$data{'hqmp'}};
	}
	if (@libs)	{
		foreach my $library (@libs)	{
			my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
			$libs .= " --$read_type".$lib_num{$read_type}."-1 $data{$read_type}->{$library}->[0] --$read_type".$lib_num{$read_type}."-2 $data{$read_type}->{$library}->[1]";
			$lib_num{$read_type}++;
		}
	}
	
	# set k-mer
	my %kmer;
	if ($global_opt->{'protocol'}->{$protocol}->{'multi-kmer'})	{
		%kmer = (
			'21' => 1,
			'33' => 1,
			'55' => 1,
		);
		if ($max_rd_len >= 150)	{
			$kmer{'77'} = 1;
		}
		if ($max_rd_len >= 250)	{
			$kmer{'99'} = 1;
			$kmer{'127'} = 1;
		}
	}
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0, 1, 1, 1, 0);
	$kmer{$kmer} = 1;
	$kmer = join ",", sort {$a<=>$b} keys %kmer;

	# set command
	my $cmd = $global_opt->{'bin'}->{'dipspades'};
	if ($global_opt->{'protocol'}->{$protocol}->{'option'} =~ /\w/)	{
		$cmd .= " $global_opt->{'protocol'}->{$protocol}->{'option'}";
	}
	$cmd .= " -k $kmer $libs -t $global_opt->{'threads'} -m $global_opt->{'memory'} -o .";
	
	# run dipSPAdes
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# create hard link of assembly files
	if (-e "consensus_contigs.fasta")	{
		system("ln consensus_contigs.fasta $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln consensus_contigs.fasta $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub velvet	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set libraries
	my %data = &data($protocol, $global_opt, 0, 1, 1, 1);
	
	# set library numbering
	my %lib_num; my $lib_num = 1;
	foreach my $read_type (sort keys %data)	{
		foreach my $library (sort keys %{$data{$read_type}})	{
			if ($lib_num == 1)	{
				$lib_num{$library} = "";
			}	else	{
				$lib_num{$library} = $lib_num;
			}
			$lib_num++;
		}
	}
	
	my $libs;
	# SE libraries
	if (defined($data{'se'}))	{
		foreach my $library (sort keys %{$data{'se'}})	{
			$libs .= " -fastq -short$lib_num{$library} $data{'se'}->{$library}";
		}
	}

	# PE/MP/HQMP libraries
	my @libs;
	if (defined($data{'pe'}))	{
		push @libs, sort keys %{$data{'pe'}};
	}
	if (defined($data{'mp'}))	{
		push @libs, sort keys %{$data{'mp'}};
	}
	if (defined($data{'hqmp'}))	{
		push @libs, sort keys %{$data{'hqmp'}};
	}
	if (@libs)	{
		foreach my $library (@libs)	{
			my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
			if ($read_type =~ /^(pe|hqmp)$/)	{
				$libs .= " -fastq -shortPaired$lib_num{$library} -separate $data{$read_type}->{$library}->[0] $data{$read_type}->{$library}->[1]";
			}	else	{
				my $cmd = "$global_opt->{'bin'}->{'fastx'} -Q33 -i $data{$read_type}->{$library}->[0] -o $library\_1.fq"; 
				&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
				$cmd = "$global_opt->{'bin'}->{'fastx'} -Q33 -i $data{$read_type}->{$library}->[1] -o $library\_2.fq"; 
				&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
				$libs .= " -fastq -shortPaired$lib_num{$library} -separate $library\_1.fq $library\_2.fq";
			}
		}
	}
	
	# set k-mer
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 1, 1, 1, 0, 0);
	
	# set command for velveth
	my $cmd = "$global_opt->{'bin'}->{'velveth'} . $kmer".$libs;
	
	# run velveth
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# set command for velvetg
	$cmd = "$global_opt->{'bin'}->{'velvetg'} . ";
	if ($global_opt->{'protocol'}->{$protocol}->{'option'} =~ /\w/)	{
		$cmd .= " $global_opt->{'protocol'}->{$protocol}->{'option'}";
	}
	
	if (@libs)	{	
		foreach my $library (@libs)	{
			$cmd .= " -ins_length".$lib_num{$library}." $global_opt->{'library'}->{$library}->{'frag_mean'} -ins_length".$lib_num{$library}."_sd $global_opt->{'library'}->{$library}->{'frag_sd'}";
		}
	}

	# run velvetg with scaffolding
	&Utilities::execute_cmd("$cmd -clean yes", "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	system("mv contigs.fa scaffolds.fa");

	# run velvetg without scaffolding
	&Utilities::execute_cmd("$cmd -scaffolding no", "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# creat hard links of assembly files
	if (-e "contigs.fa")	{
		system("ln contigs.fa $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln scaffolds.fa $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub data	{
	(my $protocol, my $global_opt, my $mp_se, my $mp, my $hqmp_se, my $hqmp) = @_;

	# collect libraries for each read type
	my %lib;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
		push @{$lib{$read_type}}, $library;
	}

	# determine which data file to use for each library
	my %data;

	# SE data: SE libraries and SE reads generated from PE/MP/HQMP libraries during QC
	if (defined($lib{'se'}))	{
		foreach my $library (@{$lib{'se'}})	{
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$data{'se'}->{$library} = "$global_opt->{'out_dir'}/libraries/$library/$library.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "correction")	{
				$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq";
			}
		}
		foreach my $library (@{$lib{'pe'}})	{
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				next;
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq")	{
					$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "correction")	{
				if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq")	{
					$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq";
				}
			}
		}
		if ($mp_se && defined($lib{'mp'}))	{
			foreach my $library (@{$lib{'mp'}})	{
				if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
					next;
				}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
					if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq")	{
						$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
					}
				}
			}
		}
		if ($hqmp_se && defined($lib{'hqmp'}))	{
			foreach my $library (@{$lib{'hqmp'}})	{
				if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
					next;
				}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip")	{
					if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq")	{
						$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq";
					}
				}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
					if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq")	{
						$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
					}
				}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "correction")	{
					if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq")	{
						$data{'se'}->{$library} = "$global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq";
					}
				}
			}
		}
	}

	# PE libraries: original, trimmomatic, and quake
	if (defined($lib{'pe'}))	{
		foreach my $library (@{$lib{'pe'}})	{
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$data{'pe'}->{$library} = [ ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq") ];
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$data{'pe'}->{$library} = [ ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq") ];
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "correction")	{
				$data{'pe'}->{$library} = [ ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.cor.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.cor.fq") ];
			}
		}
	}

	# MP libraries: original, trimmomatic, and nextclip
	if ($mp && defined($lib{'mp'}))	{
		foreach my $library (@{$lib{'mp'}})	{
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$data{'mp'}->{$library} = [ ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq") ];
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$data{'mp'}->{$library} = [ ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq") ];
			}
		}
	}

	# HQMP libraries: original, trimmomatic, nextclip, and quake
	if ($hqmp && defined($lib{'hqmp'}))	{
		foreach my $library (@{$lib{'hqmp'}})	{
			if ($global_opt->{'library'}->{$library}->{'qc'} eq "0" || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$data{'hqmp'}->{$library} = [ ("$global_opt->{'out_dir'}/libraries/$library/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library/$library\_2.fq") ];
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip")	{
				$data{'hqmp'}->{$library} = [ ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq") ];
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$data{'hqmp'}->{$library} = [ ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq") ];
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "correction")	{
				$data{'hqmp'}->{$library} = [ ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.cor.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.cor.fq") ];
			}
		}
	}

	# PacBio CLR libraries: original
	if (defined($lib{'clr'}))	{
		foreach my $library (@{$lib{'clr'}})	{
			$data{'clr'}->{$library} = "$global_opt->{'out_dir'}/libraries/$library/$library.fq";
		}
	}

	return %data;
}

sub kmergenie	{
	(my $protocol, my $global_opt, my $mp_se, my $mp, my $hqmp_se, my $hqmp, my $diploid, my $min_abundance) = @_;
	
	print "\tKmerGenie estimation of best K-mer:\n";

	# create and enter the directory for KmerGenie
	mkdir("kmergenie");
	chdir("kmergenie");
	
	# set libraries
	my %data = &data($protocol, $global_opt, $mp_se, $mp, $hqmp_se, $hqmp);

	# SE libraries
	if (defined($data{'se'}))	{
		foreach my $library (sort keys %{$data{'se'}})	{
			system("cat $data{'se'}->{$library} >> $protocol.fq");
		}
	}

	# PE, MP, and HQMP libraries
	my @libs;
	if (defined($data{'pe'}))	{
		push @libs, sort keys %{$data{'pe'}};
	}
	if (defined($data{'mp'}))	{
		push @libs, sort keys %{$data{'mp'}};
	}
	if (defined($data{'hqmp'}))	{
		push @libs, sort keys %{$data{'hqmp'}};
	}
	if (@libs)	{
		foreach my $library (@libs)	{
			my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
			system("cat $data{$read_type}->{$library}->[0] $data{$read_type}->{$library}->[1] >> $protocol.fq");
		}
	}
	
	# set command for kmergenie
	my $cmd = "$global_opt->{'bin'}->{'kmergenie'} $protocol.fq -t $global_opt->{'threads'}";
	if ($diploid)	{
		$cmd .= " --diploid";
	}

	# run kmergenie
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.kmergenie.log");
	system("rm $protocol.fq");

	open KMERGENIE, "< $global_opt->{'out_dir'}/logs/$protocol.kmergenie.log" or die "Can't open $global_opt->{'out_dir'}/logs/$protocol.kmergenie.log!\n";
	my @kmergenie_out = <KMERGENIE>;
	close (KMERGENIE);
	
	chdir("../");
	
	my $kmer = 33;
	if ($kmergenie_out[-1] =~ /^best k\:\s*(\d+)/)	{
		$kmer = $1;
		print "\tKmerGenie analysis finished successfully! The K-mer size of $kmer will be used for the assembly protocol $protocol.\n";
	}	else	{
		print "\tWARNING: KmerGenie failed to find a suitable K-mer value! The K-mer size of 33 will be used for the assembly protocol $protocol.\n";
	}

	unless ($min_abundance)	{
		$min_abundance = 3;
		if ($kmergenie_out[-2] =~ /^recommended coverage cut-off for best k\:\s*(\d+)/)	{
			$min_abundance = $1;
			print "\tKmerGenie analysis finished successfully! The minimum abundance of $min_abundance will be used for the assembly protocol $protocol.\n";
		}	else	{
			print "\tWARNING: KmerGenie failed to find a suitable minimum abundance! The minimum abundance of $min_abundance will be used for the assembly protocol $protocol.\n";
		}
	}
	return ($min_abundance, $kmer);
}

sub quast	{
	(my $mode, my $global_opt) = @_;
	
	my $eval_dir = ($mode eq "assemblies") ? "evaluation" : "evaluation.cor";
	foreach my $type (('contigs', 'scaffolds'))	{
		print "Starts QUAST evalution of assembled $type:\t".localtime()."\n";
		my @assemblies = glob "$global_opt->{'out_dir'}/$mode/*.$type.fa";
		if (@assemblies)	{
			my $cmd = "$global_opt->{'bin'}->{'quast'} --fast -t $global_opt->{'threads'} -o $global_opt->{'out_dir'}/$eval_dir/$type\_QUAST";
			# determine if the "eukaryote" option should be turned on
			if ($global_opt->{'quast'}->{'eukaryote'})	{
				$cmd .= " --eukaryote";
			}
			# determine if gene annotation is available for evaluation
			if (defined($global_opt->{'quast'}->{'gene'}))	{
				$cmd .= " -G $global_opt->{'quast'}->{'gene'}";
			}
			# determine if the GAGE report should be generated
			if (defined($global_opt->{'genome'}))	{
				$cmd .= " -R $global_opt->{'genome'}";
				if ($global_opt->{'quast'}->{'gage'})	{
					$cmd .= " --gage";
				}
			}	else	{
				if ($global_opt->{'quast'}->{'gage'})	{
					print "\tWARNING: GAGE mode requires a reference genome. The -gage option is ingnored and a full evaluation will be performed.\n";
				}
			}
	
			my @names;
			foreach my $file (@assemblies)	{
				(my $protocol = basename($file)) =~ s/\.$type\.fa//;
				print "\tfound the $type assembly for protocol $protocol!\n";
				push @names, $protocol;
			}
			my $name = join ",", @names;
			my $assemblies = join " ", @assemblies;
			$cmd .= " -l $name $assemblies";
	
			unless (-d "$global_opt->{'out_dir'}/$eval_dir/$type\_QUAST")	{
				my $log = ($mode eq "assemblies") ? "$global_opt->{'out_dir'}/logs/$type.QUAST.log" : "$global_opt->{'out_dir'}/logs/$type.cor.QUAST.log";
				&Utilities::execute_cmd($cmd, $log);
			}
			if ($global_opt->{'quast'}->{'gage'} == 1 && -e "$global_opt->{'out_dir'}/$eval_dir/$type\_QUAST/gage_report.txt")	{
				system("ln $global_opt->{'out_dir'}/$eval_dir/$type\_QUAST/gage_report.txt $global_opt->{'out_dir'}/$eval_dir/$type.gage_report.txt");
				print "QUAST evalution of assembled $type finished!\n\n";
				&Utilities::rank_assembly($eval_dir, $type, $global_opt, 1, 1);
			}	elsif ($global_opt->{'quast'}->{'gage'} == 0 && -e "$global_opt->{'out_dir'}/$eval_dir/$type\_QUAST/report.txt")	{
				system("ln $global_opt->{'out_dir'}/$eval_dir/$type\_QUAST/report.txt $global_opt->{'out_dir'}/$eval_dir/$type.report.txt");
				print "QUAST evalution of assembled $type finished!\n\n";
				if (defined($global_opt->{'genome'}))	{
					&Utilities::rank_assembly($eval_dir, $type, $global_opt, 0, 1);
				}	else	{
					&Utilities::rank_assembly($eval_dir, $type, $global_opt, 0, 0);
				}
			}	else	{
				print "WARNING: No evalution report found, the QUAST evaluation of assembled $type failed!\n\n";
			}
		}	else	{
			print "WARNING: There is no $type assembly found in \"$global_opt->{'out_dir'}/$mode\"!\n\n";
		}
	}	

	return;
}

sub reapr	{
	my $global_opt = $_[0];

	print "Starts REAPR evalution:\t".localtime()."\n\n";

	print "Prepare reads for REAPR evaluation:\n";
	# preapre the read files/links for REAPR evaluation
	# set up links to the PE library
	my $short_lib = $global_opt->{'reapr'}->{'short'};
	my $short_type = $global_opt->{'library'}->{$short_lib}->{'read_type'};
	if ($short_type eq "pe")	{
		if (-e "$short_lib\_1.fq")	{ system("rm $short_lib\_1.fq"); }
		if (-e "$short_lib\_2.fq")	{ system("rm $short_lib\_2.fq"); }
		system("ln $global_opt->{'out_dir'}/libraries/$short_lib/$short_lib\_1.fq $short_lib\_1.fq");
		system("ln $global_opt->{'out_dir'}/libraries/$short_lib/$short_lib\_2.fq $short_lib\_2.fq");
	}	elsif ($short_type eq "hqmp")	{
		# to add
	}
	# reverse complement the MP library
	my $long_lib = $global_opt->{'reapr'}->{'long'};
	unless ($short_lib eq $long_lib)	{
		my $long_type = $global_opt->{'library'}->{$long_lib}->{'read_type'};
		print "\treverse complement $long_type library $long_lib:\n";
		if (-e "$long_lib\_1.fq")	{ system("rm $long_lib\_1.fq"); }
		if (-e "$long_lib\_2.fq")	{ system("rm $long_lib\_2.fq"); }
		if ($long_type eq "pe")	{
			# to add
		}	elsif ($long_type eq "hqmp")	{
			# to add
		}	elsif ($long_type eq "mp")	{
			my $cmd = "$global_opt->{'bin'}->{'fastx'} -Q33 -i $global_opt->{'out_dir'}/libraries/$long_lib/$long_lib\_1.fq -o $long_lib\_1.fq"; 
			&Utilities::execute_cmd($cmd, "/dev/null");
			$cmd = "$global_opt->{'bin'}->{'fastx'} -Q33 -i $global_opt->{'out_dir'}/libraries/$long_lib/$long_lib\_2.fq -o $long_lib\_2.fq"; 
			&Utilities::execute_cmd($cmd, "/dev/null");
		}
	}
	print "Reads preparation finished.\n\n";

	foreach my $type (('contigs', 'scaffolds'))	{
		my @assemblies = glob "$global_opt->{'out_dir'}/assemblies/*.$type.fa";
		if (@assemblies)	{
			foreach my $file (@assemblies)	{
				(my $protocol = basename($file)) =~ s/\.$type\.fa//;

				# skip if the reapr correction is already done:
				if (-e "$protocol.$type.fa")	{
					print "NOTE: REAPR correction of $type assembly for protocol $protocol already finished, skip to the next!\n\n";
					next;
				}	else	{
					if (-d "$protocol.$type")	{ system("rm -rf $protocol.$type"); }
					print "Found the $type assembly for protocol $protocol, performing REAPR correction:\n";
				}

				# REAPR evaluation consists of three steps:
				# 1. preapre the assembly file
				my $cmd = "$global_opt->{'bin'}->{'reapr'} facheck $file $protocol.$type";
				&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.reapr.log");
				# 2. map short insert library if available
				$cmd = "$global_opt->{'bin'}->{'reapr'} perfectmap $protocol.$type.fa $short_lib\_1.fq $short_lib\_2.fq $global_opt->{'library'}->{$short_lib}->{'frag_mean'} $protocol.short";
				&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.reapr.log");
				# 3. map long insert library
				$cmd = "$global_opt->{'bin'}->{'reapr'} smaltmap -n $global_opt->{'threads'} $protocol.$type.fa $long_lib\_1.fq $long_lib\_2.fq $protocol.long.bam";
				&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.reapr.log");
				# 4. run reapr pipeline
				$cmd = "$global_opt->{'bin'}->{'reapr'} pipeline $protocol.$type.fa $protocol.long.bam $protocol.$type $protocol.short";
				&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.reapr.log");
				system("rm $protocol.$type.fa $protocol.$type.info $protocol.$type.fa.fai $protocol.short.hist $protocol.short.perfect_cov.gz $protocol.short.perfect_cov.gz.tbi $protocol.long.bam $protocol.long.bam.bai $protocol.$type.run-pipeline.sh");

				if (-e "$protocol.$type/04.break.broken_assembly.fa")	{
					system("ln $protocol.$type/04.break.broken_assembly.fa $protocol.$type.fa");
					print "The REAPR evaluation of $protocol $type finished successfully!\n\n";
				}	else	{
					system("rm -rf $protocol.$type");
					print "WARNING: the REAPR evaluation of $protocol $type failed!\n\n";
				}
			}
		}	else	{
			print "WARNING: There is no $type assembly found in \"$global_opt->{'out_dir'}/assemblies\"!\n\n";
		}
	}

	# clean up the temporary read files/links for REAPR evaluation
	system("rm $short_lib\_1.fq $short_lib\_2.fq");
	unless ($short_lib eq $long_lib) { system("rm $long_lib\_1.fq $long_lib\_2.fq"); }

	return;
}

1;
