package Preprocess;

use strict;
use warnings;

use Utilities;

sub prepare_real	{
	(my $library, my $global_opt, my $overwrite) = @_;

	# set command to convert all fastq to phred33
	my $cmd = "java -jar $global_opt->{'bin'}->{'trimmomatic'} ".(($global_opt->{'library'}->{$library}->{'read_type'} eq "se") ? "SE": "PE")." -threads $global_opt->{'threads'}";
	if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se")	{
		if (-e "$global_opt->{'out_dir'}/real_data/$library.fq" && !($overwrite == 0 && -e "$library.fq"))	{
			$cmd .= " $global_opt->{'out_dir'}/real_data/$library.fq $library.fq TOPHRED33";
		}	else	{
			return 0;
		}
	}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} =~ /^(pe|mp|hqmp)$/)	{
		if (-e "$global_opt->{'out_dir'}/real_data/$library\_1.fq" || -e "$global_opt->{'out_dir'}/real_data/$library\_2.fq")	{
			if (-e "$global_opt->{'out_dir'}/real_data/$library\_1.fq" && -e "$global_opt->{'out_dir'}/real_data/$library\_2.fq")	{
				unless ($overwrite == 0 && -e "$library\_1.fq" && -e "$library\_2.fq")	{
					$cmd .= " $global_opt->{'out_dir'}/real_data/$library\_1.fq $global_opt->{'out_dir'}/real_data/$library\_2.fq $library\_1.fq temp_1.fq $library\_2.fq temp_2.fq TOPHRED33";
				}
			}	else	{
				die "ERROR: the real dataset $library is a PE/MP library but both ends do not exist.\n";
			}
		}	else	{
			return 0;
		}
	}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "clr")	{
		if (-e "$global_opt->{'out_dir'}/real_data/$library.fq")	{
			unless (-e "$library.fq")	{
				system("ln -s \"$global_opt->{'out_dir'}/real_data/$library.fq\" $library.fq");
			}
			return 1;
		}	else	{
			return 0;
		}
	}

	# run phred conversion command
	print "Convert real dataset $library to Phred33:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.prep_real.log");
	
	# cleanup empty temp files
	unless ($global_opt->{'library'}->{$library}->{'read_type'} eq "se")	{
		system("rm temp_1.fq temp_2.fq");
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "hqmp")	{
			print "Reverse complement $library.\n";
			$cmd = "$global_opt->{'bin'}->{'fastx'} -Q33 -i $library\_1.fq -o $library\_1.fq.rc";
			&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.prep_real.log");
			system("mv $library\_1.fq.rc $library\_1.fq");
			$cmd = "$global_opt->{'bin'}->{'fastx'} -Q33 -i $library\_2.fq -o $library\_2.fq.rc";
			&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.prep_real.log");
			system("mv $library\_2.fq.rc $library\_2.fq");
		}
		
	}

	print "Conversion to Phred33 finished.\n";

	return 1;
}

sub QC	{
	(my $library, my $global_opt, my $overwrite) = @_;

	my $lib_opt = $global_opt->{'library'}->{$library};
	
	print "Starts QC of the library $library:\t".localtime()."\n";

	$lib_opt->{'qc'} = "original";

	if ($lib_opt->{'nc-on'} && $lib_opt->{'read_type'} eq 'mp')	{
		if ($overwrite == 0)	{
			if (-s "$library\_1.nc.fq" && -s "$library\_2.nc.fq")	{
				$lib_opt->{'read_type'} = "hqmp";
				$lib_opt->{'qc'} = "nextclip";
			}
			if (-e "$library.nc.fq" && -s "$library.nc.fq" == 0)	{
				system("rm $library.nc.fq");
			}
		}
		if ($lib_opt->{'qc'} eq "original")	{
			if (-e "$library\_1.nc.fq") { system("rm $library\_1.nc.fq"); }
			if (-e "$library\_2.nc.fq") { system("rm $library\_2.nc.fq"); }
			if (-e "$library.nc.fq") { system("rm $library.nc.fq"); }
			&nextclip($library, $global_opt);
		}
	}

	if ($lib_opt->{'tm-on'})	{
		if ($lib_opt->{'read_type'} eq "se")	{
			if ($overwrite == 0 && -s "$library.tm.fq")	{
				$lib_opt->{'qc'} = "trimmomatic";
			}
			unless ($lib_opt->{'qc'} eq "trimmomatic")	{
				if (-e "$library.tm.fq") { system("rm $library.tm.fq"); }
				&trimmomatic($library, $global_opt);
			}
		}	elsif ($lib_opt->{'read_type'} =~ /^(pe|mp|hqmp)$/)	{
			if ($overwrite == 0)	{
				if (-s "$library\_1.tm.fq" && -s "$library\_2.tm.fq")	{
					$lib_opt->{'qc'} = "trimmomatic";
				}
				if (-e "$library.tm.fq" && -s "$library.tm.fq" == 0)	{
					system("rm $library.tm.fq");
				}
			}
			unless ($lib_opt->{'qc'} eq "trimmomatic")	{
				if (-e "$library\_1.tm.fq") { system("rm $library\_1.tm.fq"); }
				if (-e "$library\_2.tm.fq") { system("rm $library\_2.tm.fq"); }
				if (-e "$library.tm.fq") { system("rm $library.tm.fq"); }
				&trimmomatic($library, $global_opt);
			}
		}
	}

	if (defined($lib_opt->{'ec-on'}))	{
		if ($lib_opt->{'read_type'} eq "se")	{
			if ($overwrite == 0 && -e "$library.cor.fq")	{
				$lib_opt->{'qc'} = "correction";
			}
			unless ($lib_opt->{'qc'} eq "correction")	{
				if (-e "$library.cor.fq") { system("rm $library.cor.fq"); }
				if ($lib_opt->{'ec-tool'} eq "lighter")	{
					&lighter($library, $global_opt);
				}	elsif ($lib_opt->{'ec-tool'} eq "quake")	{
					&quake($library, $global_opt);
				}
			}
		}	elsif ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$/)	{
			if ($overwrite == 0)	{
				if (-e "$library\_1.cor.fq" && -e "$library\_2.cor.fq")	{
					$lib_opt->{'qc'} = "correction";
				}
				if (-e "$library.cor.fq" && -s "$library.cor.fq" == 0)	{
					system("rm $library.cor.fq");
				}
			}
			unless ($lib_opt->{'qc'} eq "correction")	{
				if (-e "$library\_1.cor.fq") { system("rm $library\_1.cor.fq"); }
				if (-e "$library\_2.cor.fq") { system("rm $library\_2.cor.fq"); }
				if (-e "$library.cor.fq") { system("rm $library.cor.fq"); }
				if ($lib_opt->{'ec-tool'} eq "lighter")	{
					&lighter($library, $global_opt);
				}	elsif ($lib_opt->{'ec-tool'} eq "quake")	{
					&quake($library, $global_opt);
				}
			}
		}
	}

	print "Quality control of the library $library finished.\n\n";

	return;
}

sub nextclip	{
	(my $library, my $global_opt) = @_;
	
	my $lib_opt = $global_opt->{'library'}->{$library};

	# set command
	my $cmd = "$global_opt->{'bin'}->{'nextclip'} -m $lib_opt->{'nc-minlen'} -o $library.nc";
	
	# set input file names for original and Trimmomatic processed data separately
	$cmd .= " -i $global_opt->{'out_dir'}/libraries/$library/$library\_1.fq -j $global_opt->{'out_dir'}/libraries/$library/$library\_2.fq";

	# run NextClip trimming
	print "\tNextClip adapter trimming starts:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");

	# combine output files
	system("cat $library.nc_A_R1.fastq $library.nc_B_R1.fastq $library.nc_C_R1.fastq > $library\_1.nc.fq");
	system("cat $library.nc_A_R2.fastq $library.nc_B_R2.fastq $library.nc_C_R2.fastq > $library\_2.nc.fq");
	if (-s "$library.nc_D_R1.fastq" || -s "$library.nc_D_R2.fastq")	{
		system("cat $library.nc_D_R1.fastq $library.nc_D_R2.fastq > $library.nc.fq");
	}
	system("rm *.txt *.fastq");

	# check if NextClip runs into error
	if (-s "$library\_1.nc.fq" && -s "$library\_2.nc.fq")	{
		# reverse complement trimmed FASTQ file
		# first end
		$cmd = "$global_opt->{'bin'}->{'fastx'} -Q33 -i $library\_1.nc.fq -o temp.fq";
		&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");
		system "mv temp.fq $library\_1.nc.fq";
		# second end
		$cmd = "$global_opt->{'bin'}->{'fastx'} -Q33 -i $library\_2.nc.fq -o temp.fq";
		&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");
		system "mv temp.fq $library\_2.nc.fq";
		# change library type
		$lib_opt->{'read_type'} = "hqmp";
		print "\t$library becomes a HQMP library.\n";
		# update the last QC task performed
		$lib_opt->{'qc'} = "nextclip";
		print "\tNextClip adapter trimming finished.\n";
	}	else	{
		if (-e "$library\_1.nc.fq") { system("rm $library\_1.nc.fq"); }
		if (-e "$library\_2.nc.fq") { system("rm $library\_2.nc.fq"); }
		if (-e "$library.nc.fq") { system("rm $library.nc.fq"); }
		print "\tWARNING: No read pair has survived NextClip trimming.\n";
	}
	
	return;
}

sub trimmomatic	{
	(my $library, my $global_opt) = @_;
	
	my $lib_opt = $global_opt->{'library'}->{$library};

	# set Trimmomatic actions
	my $action;
	# set quality trimming
	if (defined($lib_opt->{'tm-trailing'}))	{
		$action .= " TRAILING:$lib_opt->{'tm-trailing'}";
	}
	# set adapter trimming
	if (defined($lib_opt->{'tm-adapter'}))	{
		$action .= " ILLUMINACLIP:$lib_opt->{'tm-adapter'}:2:30:10:1:true";
	}
	# set minimum length
	$action .= " MINLEN:$lib_opt->{'tm-minlen'}";

	# set command for Trimmomatic trimming
	my $cmd = "java -jar $global_opt->{'bin'}->{'trimmomatic'} ".(($lib_opt->{'read_type'} eq "se") ? "SE": "PE")." -threads $global_opt->{'threads'}";
	# set input and output file names for SE and PE/HQMP data separately
	if ($lib_opt->{'read_type'} eq "se")	{
		$cmd .= " $global_opt->{'out_dir'}/libraries/$library/$library.fq $library.tm.fq";
	}	elsif ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$/)	{
		if ($lib_opt->{'qc'} eq "original")	{
			$cmd .= " $global_opt->{'out_dir'}/libraries/$library/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library/$library\_2.fq $library\_1.tm.fq $library\_1.tm-se.fq $library\_2.tm.fq $library\_2.tm-se.fq";
		}	elsif ($lib_opt->{'qc'} eq "nextclip")	{
			$cmd .= "$library\_1.nc.fq $library\_2.nc.fq $library\_1.tm.fq $library\_1.tm-se.fq $library\_2.tm.fq $library\_2.tm-se.fq";
			# process single-end reads resulted from NextClip trimming
			if (-e "$library.nc.fq")	{
				my $cmd2 = "java -jar $global_opt->{'bin'}->{'trimmomatic'} SE -threads $global_opt->{'threads'} $library.nc.fq $library.tm.fq".$action;
				&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");
				unless (-s "$library.tm.fq") { system "rm $library.tm.fq"; }
			}
		}
	}	elsif ($lib_opt->{'read_type'} eq "mp")	{
		if ($lib_opt->{'qc'} eq "original")	{
			$cmd .= " $global_opt->{'out_dir'}/libraries/$library/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library/$library\_2.fq $library\_1.tm.fq $library\_1.tm-se.fq $library\_2.tm.fq $library\_2.tm-se.fq";
		}
	}
	$cmd .= $action;

	# run Trimmomatic trimming
	print "\tTrimmomatic trimming starts:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");

	# combine unpaired reads
	if ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$/)	{
		if (-s "$library\_1.tm-se.fq" || -s "$library\_2.tm-se.fq")	{
			system("cat $library\_1.tm-se.fq $library\_2.tm-se.fq >> $library.tm.fq");
		}
		system("rm $library\_1.tm-se.fq $library\_2.tm-se.fq");
	}

	# check if Trimmomatic runs into error
	if ($lib_opt->{'read_type'} eq "se")	{
		unless (-s "$library.tm.fq")	{
			system("rm $library.tm.fq");
			print "\tWARNING: No data have survived Trimmomatic trimming.\n";
		}
	}	elsif (-s "$library\_1.tm.fq" && -s "$library\_2.tm.fq")	{
		# update the last QC task performed
		$lib_opt->{'qc'} = "trimmomatic";
		print "\tTrimmomatic trimming finished.\n";
	}	else	{
		if (-e "$library\_1.tm.fq") { system("rm $library\_1.tm.fq"); }
		if (-e "$library\_2.tm.fq") { system("rm $library\_2.tm.fq"); }
		if (-e "$library.tm.fq") { system("rm $library.tm.fq"); }
		print "\tWARNING: No read pair has survived Trimmomatic trimming.\n";
	}

	return;
}

sub quake	{
	(my $library, my $global_opt) = @_;

	my $lib_opt = $global_opt->{'library'}->{$library};
	
	mkdir("quake");
	chdir("quake");
	
	# estimate k-mer size if not provided
	if ($lib_opt->{'ec-kmer'} == 0)	{
		my $genomeSize = ($global_opt->{'genome_size'} == 0) ? &Utilities::genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};
		$lib_opt->{'ec-kmer'} = int(log(200*$genomeSize)/log(4) + 0.5);
	}

	# generate file list
	open QUAKE, "> $library.filelist" or die "Can't write to $library.filelist!\n";
	if ($lib_opt->{'qc'} eq "original")	{
		if ($lib_opt->{'read_type'} eq "se")	{
			system("ln -s $global_opt->{'out_dir'}/libraries/$library/$library.fq $library.fq");
			print QUAKE "$library.fq\n";
		}	elsif ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$'/)	{
			system("ln -s $global_opt->{'out_dir'}/libraries/$library/$library\_1.fq $library\_1.fq");
			system("ln -s $global_opt->{'out_dir'}/libraries/$library/$library\_2.fq $library\_2.fq");
			print QUAKE "$library\_1.fq $library\_2.fq\n";
		}
	}	elsif ($lib_opt->{'qc'} eq "nextclip")	{
		system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq $library\_1.fq");
		system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq $library\_2.fq");
		print QUAKE "$library\_1.fq $library\_2.fq\n";
		if (-s "../$library.nc.fq")	{
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq $library.fq");
			print QUAKE "$library.fq\n";
		}
	}	elsif ($lib_opt->{'qc'} eq "trimmomatic")	{
		if ($lib_opt->{'read_type'} eq "se")	{
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq $library.fq");
			print QUAKE "$library.fq\n";
		}	elsif ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$/)	{
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $library\_1.fq");
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq $library\_2.fq");
			print QUAKE "$library\_1.fq $library\_2.fq\n";
			if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq")	{
				system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq $library.fq");
				print QUAKE "$library.fq\n";
			}
		}
	}
	close(QUAKE);
	
	# set command
	my $cmd = "$global_opt->{'bin'}->{'quake'} -t $global_opt->{'threads'} -k $lib_opt->{'ec-kmer'} -f $library.filelist";
	
	# run Quake error correction
	print "\tQuake error correction starts:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");

	# combine single-end reads resulted from correction
	if (-s "$library\_1.cor_single.fq" || -s "$library\_2.cor_single.fq")	{
		system("cat $library\_1.cor_single.fq $library\_2.cor_single.fq $library.cor.fq >> $library.cor.fq");
	}
	if (-e "$library\_1.cor_single.fq") { system("rm $library\_1.cor_single.fq"); }
	if (-e "$library\_2.cor_single.fq") { system("rm $library\_2.cor_single.fq"); }
	
	# check if Quake runs into error
	if ($lib_opt->{'read_type'} eq "se")	{
		if (-s "$library.cor.fq")	{
			system("mv $library.cor.fq $global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq");
			$lib_opt->{'qc'} = "correction";
			print "\tQuake error correction finished.\n";
		}
	}	elsif ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$/)	{
		if (-s "$library\_1.cor.fq" && -s "$library\_2.cor.fq")	{
			system("mv $library\_1.cor.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.cor.fq");
			system("mv $library\_2.cor.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.cor.fq");
			if (-s "$library.cor.fq")	{
				system("mv $library.cor.fq $global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq");
			}
			$lib_opt->{'qc'} = "correction";
			print "\tQuake error correction finished.\n";
		}	else	{
			print "\tWARNING: No read pair has survied the error correction, Quake error correction failed.\n";
		}
	}
	
	chdir("..");
	system("rm -rf quake");

	return;
}

sub lighter	{
	(my $library, my $global_opt) = @_;

	my $lib_opt = $global_opt->{'library'}->{$library};
	
	mkdir("lighter");
	chdir("lighter");
	
	my $file_list;
	# generate file list
	open QUAKE, "> $library.filelist" or die "Can't write to $library.filelist!\n";
	if ($lib_opt->{'qc'} eq "original")	{
		if ($lib_opt->{'read_type'} eq "se")	{
			system("ln -s $global_opt->{'out_dir'}/libraries/$library/$library.fq $library.fq");
			$file_list .= "-r $library.fq ";
		}	elsif ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$/)	{
			system("ln -s $global_opt->{'out_dir'}/libraries/$library/$library\_1.fq $library\_1.fq");
			system("ln -s $global_opt->{'out_dir'}/libraries/$library/$library\_2.fq $library\_2.fq");
			$file_list .= "-r $library\_1.fq -r $library\_2.fq ";
		}
	}	elsif ($lib_opt->{'qc'} eq "nextclip")	{
		system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq $library\_1.fq");
		system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq $library\_2.fq");
		$file_list .= "-r $library\_1.fq -r $library\_2.fq ";
		if (-s "../$library.nc.fq")	{
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq $library.fq");
			$file_list .= "-r $library.fq ";
		}
	}	elsif ($lib_opt->{'qc'} eq "trimmomatic")	{
		if ($lib_opt->{'read_type'} eq "se")	{
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq $library.fq");
			$file_list .= "-r $library.fq ";
		}	elsif ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$/)	{
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $library\_1.fq");
			system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq $library\_2.fq");
			$file_list .= "-r $library\_1.fq -r $library\_2.fq ";
			if (-s "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq")	{
				system("ln -s $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq $library.fq");
				$file_list .= "-r $library.fq ";
			}
		}
	}
	
	# set kmer
	my $kmer = ($lib_opt->{'ec-kmer'} == 0) ? 19 : $lib_opt->{'ec-kmer'};
	
	# set genome size
	my $genomeSize = ($global_opt->{'genome_size'} == 0) ? &Utilities::genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};
	
	# set command
	my $cmd = "$global_opt->{'bin'}->{'lighter'} -t $global_opt->{'threads'} -K $kmer $genomeSize $file_list";

	# run Lighter error correction
	print "\tLighter error correction starts:\n";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$library.QC.log");

	# check if Lighter runs into error
	if ($lib_opt->{'read_type'} eq "se")	{
		if (-s "$library.cor.fq")	{
			system("mv $library.cor.fq $global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq");
			$lib_opt->{'qc'} = "correction";
			print "\tLighter error correction finished.\n";
		}
	}	elsif ($lib_opt->{'read_type'} =~ /^(pe|hqmp)$/)	{
		if (-s "$library\_1.cor.fq" && -s "$library\_2.cor.fq")	{
			system("mv $library\_1.cor.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.cor.fq");
			system("mv $library\_2.cor.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.cor.fq");
			if (-s "$library.cor.fq")	{
				system("$library.cor.fq $global_opt->{'out_dir'}/preprocessed/$library/$library.cor.fq");
			}
			$lib_opt->{'qc'} = "correction";
			print "\tLighter error correction finished.\n";
		}	else	{
			print "\tWARNING: No read pair has survived the error correction, Lighter error correction failed.\n";
		}
	}
	
	chdir("..");
	system("rm -rf lighter");

	return;
}

1;
