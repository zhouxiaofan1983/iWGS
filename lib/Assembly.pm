package Assembly;

use strict;
use warnings;

use File::Basename;
use Utilities;

sub abyss	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set k-mer
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0);

	# set command
	my $cmd = "$global_opt->{'bin'}->{'abyss'} np=$global_opt->{'threads'} k=$kmer name=$protocol";
	if ($global_opt->{'protocol'}->{$protocol}->{'option'} =~ /\w/)	{
		$cmd .= " $global_opt->{'protocol'}->{$protocol}->{'option'}";
	}
		
	# set libraries
	my %lib;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
		push @{$lib{$read_type}}, $library;
	}

	if (defined($lib{'pe'}))	{
		my $lib = join " ", @{$lib{'pe'}};
		$cmd .= " lib=\'$lib\'";
		foreach my $library (@{$lib{'pe'}})	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$cmd .= " $library=\'$global_opt->{'out_dir'}/libraries/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library\_2.fq\'";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$cmd .= " $library=\'$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq\'";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				$cmd .= " $library=\'$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.qk.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.qk.fq\'";
			}
		}
	}
	if (defined($lib{'mp'}))	{
		my $mp = join " ", @{$lib{'mp'}};
		$cmd .= " mp=\'$mp\'";
		foreach my $library (@{$lib{'mp'}})	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$cmd .= " $library=\'$global_opt->{'out_dir'}/libraries/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library\_2.fq\'";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$cmd .= " $library=\'$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq\'";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip")	{
				$cmd .= " $library=\'$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq\'";
			}
		}
	}
	if (defined($lib{'se'}))	{
		$cmd .= " se=\'";
		foreach my $library (@{$lib{'se'}})	{
			$cmd .= "$global_opt->{'out_dir'}/libraries/$library.fq ";
		}
		foreach my $library (@{$lib{'pe'}})	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				next;
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				if (-s $fastq)	{
					$cmd .= "$fastq ";
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
				if (-s $fastq)	{
					$cmd .= "$fastq ";
				}
			}
		}
		$cmd .= "\'";
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
			print GROUPS "$library,$library,$global_opt->{'out_dir'}/libraries/$library.fq\n";
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe" || $global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
			print GROUPS "$library,$library,$global_opt->{'out_dir'}/libraries/$library\_*.fq\n";
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
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
			print LIBS "$library,iWGS,unnamed,jumping,1,,,$global_opt->{'library'}->{$library}->{'frag_mean'},$global_opt->{'library'}->{$library}->{'frag_sd'},outward,,\n";
		}
	}
	close (LIBS);
	
	# prepare the data
	mkdir("mydata");
	my $prepare_bin = dirname($global_opt->{'bin'}->{'allpaths'})."/PrepareAllPathsInputs.pl";
	my $cmd = "$prepare_bin DATA_DIR=$global_opt->{'out_dir'}/protocols/$protocol/mydata PLOIDY=$global_opt->{'protocol'}->{$protocol}->{'ploidy'}";
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

	my %read_type;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		$read_type{$global_opt->{'library'}->{$library}->{'read_type'}}->{$library} = 1;
	}

	# merge multiple PacBio CLR libraries to one
	my @clr = keys %{$read_type{'clr'}};
	if (scalar @clr > 1)	{
		foreach my $library (@clr)	{
			system("cat $global_opt->{'out_dir'}/libraries/$library.fq >> pacbio_clr.fq");
		}
	}	else	{
		 system("ln $global_opt->{'out_dir'}/libraries/$clr[0].fq pacbio_clr.fq");
	}

	# create the "pacbio.spec" filfe
	if ($global_opt->{'protocol'}->{$protocol}->{'sensitive'})	{
		open SPEC, "> pacbio.spec" or die "Can't write to pacbio.spec!\n";
		print SPEC "mhap=-k 16 --num-hashes 1256 --num-min-matches 3 --threshold 0.04\nmerSize=16\n";
		close (SPEC);
	}	else	{
		system("touch pacbio.spec");
	}

	# set command
	my $cmd;
	my $genomeSize = ($global_opt->{'genome_size'} == 0) ? &Utilities::genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};
	if (exists $read_type{'se'} || exists $read_type{'pe'})	{
		# hybrid assembly
		my $fastqToCA_bin = dirname($global_opt->{'bin'}->{'ca'})."/fastqToCA";
		my $frg;
		foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
			next unless ($global_opt->{'library'}->{$library}->{'read_type'} eq "se" || $global_opt->{'library'}->{$library}->{'read_type'} eq "pe");
			my $technology = ($global_opt->{'library'}->{$library}->{'read_length'} > 160) ? "illumina-long" : "illumina";
			$cmd = "$fastqToCA_bin -libraryname $library -technology $technology";
			if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se")	{
				if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
					$cmd .= " -reads $global_opt->{'out_dir'}/libraries/$library.fq";
				}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
					$cmd .= " -reads $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
					$cmd .= " -reads $global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
				$cmd = "$fastqToCA_bin -libraryname $library -technology $technology";
				if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
					$cmd .= " -insertsize $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} -mates $global_opt->{'out_dir'}/libraries/$library\_1.fq,$global_opt->{'out_dir'}/libraries/$library\_2.fq";
				}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
					$cmd .= " -insertsize $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} -mates $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq,$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq";
					my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
					if (-s $fastq)	{
						my $cmd2 = "$fastqToCA_bin -libraryname $library\-se -technology $technology -reads $fastq";
						&Utilities::execute_cmd($cmd2, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
						$frg .= " $global_opt->{'out_dir'}/protocols/$protocol/$library\-se.frg";
					}
				}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
					$cmd .= " -insertsize $global_opt->{'library'}->{$library}->{'frag_mean'} $global_opt->{'library'}->{$library}->{'frag_sd'} -mates $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.qk.fq,$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.qk.fq";
					my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
					if (-s $fastq)	{
						my $cmd2 = "$fastqToCA_bin -libraryname $library\-se -technology $technology -reads $fastq";
						&Utilities::execute_cmd($cmd2, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
						$frg .= " $global_opt->{'out_dir'}/protocols/$protocol/$library\-se.frg";
					}
				}
			}
			&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
			$frg .= " $global_opt->{'out_dir'}/protocols/$protocol/$library.frg";
		}
		$cmd = "$global_opt->{'bin'}->{'ca'} -length 500 -partitions 200 -l $protocol -genomeSize $genomeSize -s pacbio.spec -fastq $global_opt->{'out_dir'}/protocols/$protocol/pacbio_clr.fq $frg";
	}	else	{
		# PacBio only assembly
		$cmd = "$global_opt->{'bin'}->{'ca'} -length 500 -partitions 200 -l $protocol -genomeSize $genomeSize -s pacbio.spec -fastq $global_opt->{'out_dir'}/protocols/$protocol/pacbio_clr.fq";
	}

	# run CA
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# create hard link of assembly files
	if (-e "$protocol/9-terminator/asm.ctg.fasta")	{
		system("ln $protocol/9-terminator/asm.ctg.fasta $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln $protocol/9-terminator/asm.scf.fasta $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub discovar	{
	(my $protocol, my $global_opt) = @_;

	print "Starts the assembly protocol $protocol:\t".localtime()."\n";

	# convert FastQ to BAM
	my $library = ${$global_opt->{'protocol'}->{$protocol}->{'library'}}[0];
	my $cmd = "java -jar $global_opt->{'bin'}->{'picard'} FastqToSam F1=$global_opt->{'out_dir'}/libraries/$library\_1.fq F2=$global_opt->{'out_dir'}/libraries/$library\_2.fq SM=$library O=$library.bam";
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# run DISCOVAR
	$cmd = "$global_opt->{'bin'}->{'discovar'} READS=$library.bam NUM_THREADS=$global_opt->{'threads'} OUT_DIR=.";
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

sub soapdenovo2	{
	(my $protocol, my $global_opt) = @_;
			
	print "Starts the assembly protocol $protocol:\t".localtime()."\n";
	
	# set configuration file
	my @conf;
	my $max_rd_len = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		$max_rd_len = ($global_opt->{'library'}->{$library}->{'read_length'} > $max_rd_len) ? $global_opt->{'library'}->{$library}->{'read_length'} : $max_rd_len;
		push @conf, "[LIB]\n";
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se")	{
			push @conf, "reverse_seq=0\n";
			push @conf, "asm_flags=1\n";
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				push @conf, "q=$global_opt->{'out_dir'}/libraries/$library.fq\n";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				push @conf, "q=$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq\n";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				push @conf, "q=$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq\n";
			}
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
			push @conf, "avg_ins=$global_opt->{'library'}->{$library}->{'frag_mean'}\n";
			push @conf, "reverse_seq=0\n";
			push @conf, "asm_flags=3\n";
			push @conf, "rank=1\n";
			push @conf, "pair_num_cutoff=3\n";
			push @conf, "map_len=32\n";
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				push @conf, "q1=$global_opt->{'out_dir'}/libraries/$library\_1.fq\n";
				push @conf, "q2=$global_opt->{'out_dir'}/libraries/$library\_2.fq\n";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				push @conf, "q1=$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq\n";
				push @conf, "q2=$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq\n";
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				if (-s $fastq)	{
					push @conf, "reverse_seq=0\n";
					push @conf, "asm_flags=1\n";
					push @conf, "q=$fastq\n";
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				push @conf, "q1=$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.qk.fq\n";
				push @conf, "q2=$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.qk.fq\n";
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
				if (-s $fastq)	{
					push @conf, "reverse_seq=0\n";
					push @conf, "asm_flags=1\n";
					push @conf, "q=$fastq\n";
				}
			}
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
			push @conf, "avg_ins=$global_opt->{'library'}->{$library}->{'frag_mean'}\n";
			push @conf, "reverse_seq=1\n";
			push @conf, "asm_flags=2\n";
			push @conf, "rank=2\n";
			push @conf, "pair_num_cutoff=5\n";
			push @conf, "map_len=35\n";
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				push @conf, "q1=$global_opt->{'out_dir'}/libraries/$library\_1.fq\n";
				push @conf, "q2=$global_opt->{'out_dir'}/libraries/$library\_2.fq\n";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")   {
				push @conf, "q1=$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq\n";
				push @conf, "q2=$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq\n";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip")	{
				push @conf, "q1=$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq\n";
				push @conf, "q2=$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq\n";
			}
		}
	}
	unshift @conf, "max_rd_len=$max_rd_len\n";

	open CONF, "> config" or die "Can't write to SOAPdenovo2 configuration file!\n";
	print CONF @conf;
	close (CONF);

	# set k-mer
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0);

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
	my $libs;
	my %number = (
		'se' => 1,
		'pe' => 1,
		'mp' => 1,
	);

	my $max_rd_len = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
		$max_rd_len = ($read_type eq "pe" && $global_opt->{'library'}->{$library}->{'read_length'} > $max_rd_len) ? $global_opt->{'library'}->{$library}->{'read_length'} : $max_rd_len;
		if ($read_type eq "clr")	{
			$libs .= " --pacbio $global_opt->{'out_dir'}/libraries/$library.fq";
		}	elsif ($read_type eq "se")	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$libs .= " --s$number{$read_type} $global_opt->{'out_dir'}/libraries/$library.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$libs .= " --s$number{$read_type} $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				$libs .= " --s$number{$read_type} $global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
			}
			$number{$read_type}++;
		}	elsif ($read_type eq "pe")	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/libraries/$library\_1.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/libraries/$library\_2.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq";
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				if (-s $fastq)	{
					$libs .= " --s$number{'se'} $fastq";
					$number{'se'}++;
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.qk.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.qk.fq";
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
				if (-s $fastq)	{
					$libs .= " --s$number{'se'} $fastq";
					$number{'se'}++;
				}
			}
			$number{$read_type}++;
		}	elsif ($read_type eq "mp")	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/libraries/$library\_1.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/libraries/$library\_2.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip")	{
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq";
			}
			$number{$read_type}++;
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
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 0);
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
	my $libs;
	my %number = (
		'se' => 1,
		'pe' => 1,
		'mp' => 1,
	);

	my $max_rd_len = 0;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		my $read_type = $global_opt->{'library'}->{$library}->{'read_type'};
		$max_rd_len = ($read_type eq "pe" && $global_opt->{'library'}->{$library}->{'read_length'} > $max_rd_len) ? $global_opt->{'library'}->{$library}->{'read_length'} : $max_rd_len;
		if ($read_type eq "clr")	{
			$libs .= " --pacbio $global_opt->{'out_dir'}/libraries/$library.fq";
		}	elsif ($read_type eq "se")	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				$libs .= " --s$number{$read_type} $global_opt->{'out_dir'}/libraries/$library.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$libs .= " --s$number{$read_type} $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				$libs .= " --s$number{$read_type} $global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
			}
			$number{$read_type}++;
		}	elsif ($read_type eq "pe")	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/libraries/$library\_1.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/libraries/$library\_2.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq";
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				if (-s $fastq)	{
					$libs .= "--s$number{'se'} $fastq";
					$number{'se'}++;
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.qk.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.qk.fq";
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
				if (-s $fastq)	{
					$libs .= "--s$number{'se'} $fastq";
					$number{'se'}++;
				}
			}
			$number{$read_type}++;
		}	elsif ($read_type eq "mp")	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/libraries/$library\_1.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/libraries/$library\_2.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip")	{
				$libs .= " --$read_type"."$number{$read_type}\-1 $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq --$read_type"."$number{$read_type}\-2 $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq";
			}
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
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 1, 0);
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
	
	# set k-mer
	my $kmer = ($global_opt->{'protocol'}->{$protocol}->{'kmer'}) ? $global_opt->{'protocol'}->{$protocol}->{'kmer'} : &kmergenie($protocol, $global_opt, 0, 1);
	
	# set command for velveth
	my $cmd = "$global_opt->{'bin'}->{'velveth'} . $kmer";
	
	# set libraries
	my %lib; my $lib_num = 1;
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		$lib{$library} = $lib_num;
		$lib_num++;
	}
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se")	{
			my $fastq;
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				$fastq = "$global_opt->{'out_dir'}/libraries/$library.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				$fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				$fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
			}
			if ($lib{$library} == 1)	{
				$cmd .= " -fastq -short $fastq";
			}	else	{
				$cmd .= " -fastq -short$lib{$library} $fastq";
			}
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
			my @fastq;
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				@fastq = ("$global_opt->{'out_dir'}/libraries/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library\_2.fq");
			}       elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")   {
				@fastq = ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq");
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				if (-s $fastq)	{
					$cmd .= " -fastq -short$lib_num $fastq";
					$lib_num++;
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake") {
				@fastq = ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.qk.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.qk.fq");
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
				if (-s $fastq)	{
					$cmd .= " -fastq -short$lib_num $fastq";
					$lib_num++;
				}
			}
			if ($lib{$library} == 1)        {
				$cmd .= " -fastq -shortPaired -separate $fastq[0] $fastq[1]";
			}	else	{
				$cmd .= " -fastq -shortPaired$lib{$library} -separate $fastq[0] $fastq[1]";
			}
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
			my @fastq;
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")       {
				@fastq = ("$global_opt->{'out_dir'}/libraries/$library\_1.fq", "$global_opt->{'out_dir'}/libraries/$library\_2.fq");
			}       elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")   {
				@fastq = ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq");
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				if (-s $fastq)	{
					$cmd .= " -fastq -short$lib_num $fastq";
					$lib_num++;
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip") {
				@fastq = ("$global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq", "$global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq");
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq";
				if (-s $fastq)	{
					$cmd .= " -fastq -short$lib_num $fastq";
					$lib_num++;
				}
			}
			if ($lib{$library} == 1)        {
				$cmd .= " -fastq -shortPaired -separate $fastq[0] $fastq[1]";
			}	else	{
				$cmd .= " -fastq -shortPaired$lib{$library} -separate $fastq[0] $fastq[1]";
			}
		}
	}

	# run velveth
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");
	
	# set command for velvetg
	$cmd = "$global_opt->{'bin'}->{'velvetg'} . ";
	if ($global_opt->{'protocol'}->{$protocol}->{'option'} =~ /\w/)	{
		$cmd .= " $global_opt->{'protocol'}->{$protocol}->{'option'}";
	}
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		if ($global_opt->{'library'}->{$library}->{'read_type'} ne "se")	{
			if ($lib{$library} == 1)        {
				$cmd .= " -ins_length $global_opt->{'library'}->{$library}->{'frag_mean'} -ins_length_sd $global_opt->{'library'}->{$library}->{'frag_sd'}";
			}	else	{
				$cmd .= " -ins_length".$lib{$library}." $global_opt->{'library'}->{$library}->{'frag_mean'} -ins_length".$lib{$library}."_sd $global_opt->{'library'}->{$library}->{'frag_sd'}";
			}
		}
	}

	# run velvetg
	&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$protocol.assembly.log");

	# creat hard links of assembly files
	if (-e "contigs.fa")	{
		system("ln contigs.fa $global_opt->{'out_dir'}/assemblies/$protocol.contigs.fa");
		system("ln contigs.fa $global_opt->{'out_dir'}/assemblies/$protocol.scaffolds.fa");
		print "The assembly protocol $protocol finished successfully!\n\n";
	}	else	{
		print "WARNING: No assembly found, $protocol failed!\n\n";
	}

	return;
}

sub kmergenie	{
	(my $protocol, my $global_opt, my $diploid, my $hmp) = @_;
	
	print "\tKmerGenie estimation of best K-mer:\n";

	# create and enter the directory for KmerGenie
	mkdir("kmergenie");
	chdir("kmergenie");
	
	# prepare SE and PE reads for KmerGenie
	foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se")	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				system("cat $global_opt->{'out_dir'}/libraries/$library.fq >> $protocol.fq");
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq >> $protocol.fq");
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")   {
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq >> $protocol.fq");
			}
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				system("cat $global_opt->{'out_dir'}/libraries/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library\_2.fq >> $protocol.fq");
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq >> $protocol.fq");
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				if (-s $fastq)	{
					system("cat $fastq >> $protocol.fq");
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "quake")	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.qk.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.qk.fq >> $protocol.fq");
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.qk.fq";
				if (-s $fastq)	{
					system("cat $fastq >> $protocol.fq");
				}
			}
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
			next unless ($hmp);
			if (!defined($global_opt->{'library'}->{$library}->{'qc'}) || $global_opt->{'library'}->{$library}->{'qc'} eq "original")	{
				system("cat $global_opt->{'out_dir'}/libraries/$library\_1.fq $global_opt->{'out_dir'}/libraries/$library\_2.fq >> $protocol.fq");
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "trimmomatic")	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.tm.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.tm.fq >> $protocol.fq");
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.tm.fq";
				if (-s $fastq)	{
					system("cat $fastq >> $protocol.fq");
				}
			}	elsif ($global_opt->{'library'}->{$library}->{'qc'} eq "nextclip")	{
				system("cat $global_opt->{'out_dir'}/preprocessed/$library/$library\_1.nc.fq $global_opt->{'out_dir'}/preprocessed/$library/$library\_2.nc.fq >> $protocol.fq");
				my $fastq = "$global_opt->{'out_dir'}/preprocessed/$library/$library.nc.fq";
				if (-s $fastq)	{
					system("cat $fastq >> $protocol.fq");
				}
			}
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
	my $kmer = 33;
	if ($kmergenie_out[-1] =~ /best k\:\s*(\d+)/)	{
		$kmer = $1;
		print "\tKmerGenie analysis finished successfully! The K-mer size of $kmer will be used for the assembly protocol $protocol.\n";
	}	else	{
		print "\tWARNING: KmerGenie failed to find a suitable K-mer value! The K-mer size of 33 will be used for the assembly protocol $protocol.\n";
	}
	
	chdir("../");

	return $kmer;
}

sub quast	{
	(my $type, my $global_opt) = @_;
	
	print "Starts QUAST evalution of assembled $type:\t".localtime()."\n";
	
	my @assemblies = glob "$global_opt->{'out_dir'}/assemblies/*.$type.fa";
	if (@assemblies)	{
		my $cmd = "$global_opt->{'bin'}->{'quast'} -T $global_opt->{'threads'} -o $global_opt->{'out_dir'}/evaluation/$type";
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
			$cmd .= " -R  $global_opt->{'genome'}";
			if ($global_opt->{'quast'}->{'gage'})	{
				$cmd .= " --gage";
			}
		}	else	{
			if ($$global_opt->{'quast'}->{'gage'})	{
				print "\tWARNING: GAGE mode requires a reference genome. The -gage option is ingnored and a full evaluation will be performed!\n";
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

		&Utilities::execute_cmd($cmd, "$global_opt->{'out_dir'}/logs/$type.QUAST.log");
		if ($global_opt->{'quast'}->{'gage'} == 1 && -e "$global_opt->{'out_dir'}/evaluation/$type/gage_report.txt")	{
			system("ln $global_opt->{'out_dir'}/evaluation/$type/gage_report.txt $global_opt->{'out_dir'}/evaluation/$type.gage_report.txt");
			print "QUAST evalution of assembled $type finished!\n\n";
		}	elsif ($global_opt->{'quast'}->{'gage'} == 0 && -e "$global_opt->{'out_dir'}/evaluation/$type/report.txt")	{
			system("ln $global_opt->{'out_dir'}/evaluation/$type/report.txt $global_opt->{'out_dir'}/evaluation/$type.report.txt");
			print "QUAST evalution of assembled $type finished!\n\n";
		}	else	{
			print "WARNING: No evalution report found, the QUAST evaluation of assembled $type failed!\n\n";
		}
	}	else	{
		print "WARNING: There is no successfully assembled $type!\n\n";
	}	

	return;
}

1;
