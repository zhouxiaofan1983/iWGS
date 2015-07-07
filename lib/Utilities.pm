package Utilities;

use strict;
use warnings;
use Math::Round;

#############################
# execute system command
#############################
sub execute_cmd {
	(my $cmd, my $log) = @_;

	print "\tCommand starts: \"$cmd\"\n";
	my $start_time = time();
	system("/usr/bin/time -p -o time.info $cmd >> $log 2>&1");
	my $end_time = time();

	my $timeinfo;
	open TIME, "< time.info" or die "Can't open time.info!\n";
	while (<TIME>)	{
		if (/sys\s*([\d\.]+)/ || /user\s*([\d\.]+)/)	{
			$timeinfo += $1;
		}
	}
	close (TIME);
	system("rm time.info");	

	print "\tCommand finished! All information saved to $log\n\tTime used: ".($end_time - $start_time)." seconds in real time, $timeinfo seconds in CPU time\n";

	return;
}

#############################
# execute system command2 - modified for bwa
#############################
sub execute_cmd2 {
	(my $cmd, my $log) = @_;

	print "\tCommand starts: \"$cmd\"\n";
	my $start_time = time();
	system("/usr/bin/time -p -o time.info $cmd 2>>$log");
	my $end_time = time();

	my $timeinfo;
	open TIME, "< time.info" or die "Can't open time.info!\n";
	while (<TIME>)	{
		if (/sys\s*([\d\.]+)/ || /user\s*([\d\.]+)/)	{
			$timeinfo += $1;
		}
	}
	close (TIME);
	system("rm time.info");	

	print "\tCommand finished! All information saved to $log\n\tTime used: ".($end_time - $start_time)." seconds in real time, $timeinfo seconds in CPU time\n";

	return;
}

#############################
# calculate sequencing price
#############################
sub calculate_price	{
	(my $global_opt, my $print_out) = @_;

	my $genome_size = ($global_opt->{'genome_size'} == 0) ? &genomeSize($global_opt->{'genome'}) : $global_opt->{'genome_size'};

	# set the pricing information
	my %price = &set_price($global_opt->{'pricing_info'});
	
	my %library_price;
	foreach my $library (keys %{$global_opt->{'library'}})	{
		# add the price of library preparation
		my $lib_opt = $global_opt->{'library'}->{$library};
		$library_price{$library} = $price{'prep'}->{$lib_opt->{'read_type'}};
		if ($lib_opt->{'read_type'} eq "clr")	{
			# add the sequencing price of a PacBio library
			$library_price{$library} += $lib_opt->{'depth'}*$genome_size/$price{'throughput'}->{$lib_opt->{'read_type'}}*$price{'seq'}->{$lib_opt->{'read_type'}};
		}	elsif ($lib_opt->{'read_type'} eq "se")	{
			# add the sequencing price of a Illumina SE library
			$library_price{$library} += $lib_opt->{'depth'}*$genome_size/($price{'throughput'}->{$lib_opt->{'read_type'}}->{$lib_opt->{'read_length'}}*$lib_opt->{'read_length'})*$price{'seq'}->{$lib_opt->{'read_type'}}->{$lib_opt->{'read_length'}};
		}	else	{
			# add the sequencing price of a Illumina PE/MP/HQMP library
			$library_price{$library} += $lib_opt->{'depth'}*$genome_size/($price{'throughput'}->{$lib_opt->{'read_type'}}->{$lib_opt->{'read_length'}}*$lib_opt->{'read_length'}*2)*$price{'seq'}->{$lib_opt->{'read_type'}}->{$lib_opt->{'read_length'}};
		}
	}

	my %protocol_price;
	foreach my $protocol (keys %{$global_opt->{'protocol'}})	{
		foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
			$protocol_price{$protocol} += $library_price{$library};
		}
	}

	if ($print_out)	{
		open COST, "> $global_opt->{'out_dir'}/total_cost.txt" or die "Can't write to total_cost.txt!";
		print COST "#Cost for each library:\n";
		foreach my $library (sort keys %library_price)	{
			print COST "$library\t".(nearest(0.01, $library_price{$library}))."\n";
		}
		print COST "\n#Cost for each assembly protocol:\n";
		foreach my $protocol (sort keys %protocol_price)	{
			print COST "$protocol\t".(nearest(0.01, $protocol_price{$protocol}))."\n";
		}
		close (COST);
	
		return;
	}	else	{
		return %protocol_price;
	}
}

#############################
# set prices of sequencing
#############################
sub set_price	{
	my $pricing_info = $_[0];

	my %price;

	if (&validate_price($pricing_info))	{
		open PRICE, "< $pricing_info" or die "ERROR! Fail to initialize the pricing information.\nThe file $pricing_info does not exist!\n";
		while (<PRICE>)	{
			next if (/^#/);
			chomp;
			my @price = split /\t/;
			@price[0..2] = map { lc($_) } @price[0..2];
			if ($price[0] eq "illumina")	{
				$price{'seq'}->{$price[2]}->{$price[3]} = $price[5];			# set per lane sequencing price
				$price{'prep'}->{$price[2]} = $price[4];				# set library preparation price
				$price{'throughput'}->{$price[2]}->{$price[3]} = $price[6];		# set sequencing throughput (total number of reads) for Illumiona (per lane) and PacBio (per flowcell)
			}	else	{
				$price{'seq'}->{$price[2]} = $price[5];					# set per lane sequencing price
				$price{'prep'}->{$price[2]} = $price[4];				# set library preparation price
				$price{'throughput'}->{$price[2]} = $price[6];				# set sequencing throughput (total number of reads) for Illumiona (per lane) and PacBio (per flowcell)
			}
		}
		close (PRICE);
	}	else	{
		%price = &init_price();
	}

	return %price;
}

#############################
# initialize default price information
#############################
sub init_price	{
	my %price = (
		"seq" => {
			"se" => {
				50 => 1126,
				100 => 1351,
			},
			"pe" => {
				50 => 1606,
				100 => 1825,
				125 => 2281,
				150 => 2402,
				250 => 1498,
				300 => 1926,
			},
			"mp" => {
				50 => 1606,
				100 => 1825,
				125 => 2281,
				150 => 2402,
				250 => 1498,
				300 => 1926,
			},
			"hqmp" => {
				50 => 1606,
				100 => 1825,
				125 => 2281,
				150 => 2402,
				250 => 1498,
				300 => 1926,
			},
			"clr" => 325,
		},
		"prep" => {
			"se" => 215,
			"pe" => 215,
			"mp" => 638,
			"hqmp" => 638,
			"clr" => 509,
		},
		"throughput" => {
			"se" => {
				50 => 200000000,
				100 => 200000000,
			},
			"pe" => {
				50 => 200000000,
				100 => 200000000,
				125 => 200000000,
				150 => 150000000,
				250 => 15000000,
				300 => 25000000,
			},
			"mp" => {
				50 => 200000000,
				100 => 200000000,
				125 => 200000000,
				150 => 150000000,
				250 => 15000000,
				300 => 25000000,
			},
			"hqmp" => {
				50 => 200000000,
				100 => 200000000,
				125 => 200000000,
				150 => 150000000,
				250 => 15000000,
				300 => 25000000,
			},
			"clr" => 500000000,
		},
	);
	
	return %price;
}

#############################
# validate the file containing price information of sequencing
#############################
sub validate_price	{
	my $pricing_info = $_[0];

	if (defined($pricing_info))	{
		unless (-e "$pricing_info")	{
			print "WARNING! The custome pricing information file $pricing_info does not exist, default settings will be used for cost estimation instead.\n";
			return 0;
		}
	}	else	{
		print "NOTE: Defaut settings will be used for cost estimation.\n";
		return 0;	
	}

	my %warn_msg; my $warn_msg;
	open PRICE, "< $pricing_info";
	while (<PRICE>)	{
		next if (/^#/);
		chomp;
		my @price = split /\t/;
		@price[0..3] = map { lc($_) } @price[0..3];

		if ($price[0] eq "illumina")	{
			unless ($price[1] eq "hiseq" || $price[1] eq "miseq")	{
				$warn_msg = "\tInvalid Illumina sequencing platform! Should be one of \"HiSeq\" and \"MiSeq\".\n";
				$warn_msg{$warn_msg} = 1;
			}
			unless ($price[2] eq "se" || $price[2] eq "pe" || $price[2] eq "mp" || $price[2] eq "hqmp")	{
				$warn_msg = "\tInvalid Illumina library type! Should be one of \"SE\", \"PE\", and \"(HQ)MP\".\n";
				$warn_msg{$warn_msg} = 1;
			}
			unless ($price[3] =~ /^\d+$/)	{
				$warn_msg = "\tInvalid Illumina read length! Should be numerical.\n";
				$warn_msg{$warn_msg} = 1;
			}
		}	elsif ($price[0] eq "pacbio")	{
			unless (($price[2] eq "ccs" && $price[3] eq "short") || ($price [2] eq "clr" && $price[3] eq "long"))	{
				$warn_msg = "\tInvalid PacBio library type and read length! Should be one of \"CCS short\" and \"CLR long\".\n";
				$warn_msg{$warn_msg} = 1;
			}
		}	else	{
			$warn_msg = "\tInvalid sequencing technology! Currently only \"Illumina\" and \"PacBio\" are supported.\n\n";
			$warn_msg{$warn_msg} = 1;
		}
		unless ($price[4] =~ /^\d+$/ && $price[5] =~ /^\d+$/ && $price[6] =~ /^\d+$/)	{
			$warn_msg = "\tInvalid sequencing technology! Prices of library preparation and sequencing as well as sequencing througput should all be numerical.\n";
			$warn_msg{$warn_msg} = 1;
		}
	}
	close (PRICE);
	
	if (%warn_msg)	{
		$warn_msg = join "", sort keys %warn_msg;
		print "WARNING! Fail to validate the custome pricing information, default values will be used instead:\n$warn_msg";
		return 0;
	}	else	{
		return 1;
	}
}

#############################
# rank the genome assembly
#############################
sub rank_assembly {
	(my $type, my $global_opt, my $gage, my $ref) = @_;
	
	my @warn_msg;

	# initialize weight settings
	(my $weight, my $criteria) = &init_weight($global_opt->{'custom_weight'}, $gage, $ref, \@warn_msg);

	# set metrics that need to be processed
	my %special_metric = &special_metric($gage);

	# read and process QUAST reports
	my $report = ($gage) ? "$global_opt->{'out_dir'}/evaluation/$type\_QUAST/gage_report.tsv" : "$global_opt->{'out_dir'}/evaluation/$type\_QUAST/report.tsv";
	my %report;
	open REPORT, "< $report" or die "Can't open $report!\n";
	while (<REPORT>)	{
		chomp;
		my @metric = split /\t/;
		my $metric = shift @metric;
		if (defined($special_metric{$metric}))	{
			foreach my $n (0..$#metric)	{
				if ($special_metric{$metric} eq "count")	{
					$metric[$n] =~ s/\s+COUNT:\s+\d+//;
				}	elsif ($special_metric{$metric} eq "frac")	{
					if ($metric[$n] =~ /\(([\d\.]+)\%\)/)	{
						$metric[$n] = $1;
					}
				}	elsif ($special_metric{$metric} eq "part")	{
					if ($metric[$n] =~ /(\d+)\s+\+\s+(\d+)/)	{
						$metric[$n] = $1 + $2;
					}
				}
				$metric[$n] = ($metric[$n] < 0) ? 0 : $metric[$n];
			}
		}
		$report{$metric} = \@metric;
	}
	close (REPORT);

	# combine misassembly metrics for GAGE report
	if ($gage)	{
		my @misassmbly_metric = ("Inversions", "Relocation", "Translocation");
		foreach my $misassembly_metric (@misassmbly_metric)	{
			foreach my $n (0..$#{$report{$misassembly_metric}})	{
				$report{'# misassemblies'}->[$n] += $report{$misassembly_metric}->[$n];
			}
		}
	}

	# process GC content metric if necessary
	if (defined($report{'GC (%)'}))	{
		foreach my $n (0..$#{$report{'GC (%)'}})	{
			$report{'GC (%)'}->[$n] = abs($report{'GC (%)'}->[$n] - $report{'Reference GC (%)'});
		}
	}
	
	# calculate the cost for each protocol if necessary
	my @protocol = @{$report{'Assembly'}};
	if (exists $weight->{'Cost'})	{
		my %protocol_price = &calculate_price($global_opt, 0);
		foreach my $n (0..$#protocol)	{
			$report{'Cost'}->[$n] = $protocol_price{$protocol[$n]};
		}
	}

	# calculate metric score
	my %metric_score; my %group_score; my $group_weight;
	foreach my $group (keys %{$weight})	{
		$group_weight += $weight->{$group}->{'weight'};
		my $metric_weight = 0;
		foreach my $metric (keys %{$weight->{$group}->{'member'}})	{
			$metric_weight += $weight->{$group}->{'member'}->{$metric};
			my @metric = sort {$a<=>$b} @{$report{$metric}};
			foreach my $n (0..$#{$report{$metric}})	{
				# calculate metric score
				if ($criteria->{$metric} eq "min")	{
					if ($metric[0] == 0)	{
						my $pseudo_count = ($metric[-1] =~ /\./) ? 0.01 : 1;
						$metric_score{$metric}->[$n] = $pseudo_count/($report{$metric}->[$n]+$pseudo_count);
					}	else	{
						$metric_score{$metric}->[$n] = $metric[0]/$report{$metric}->[$n];
					}
				}	elsif ($criteria->{$metric} eq "max")	{
					if ($metric[-1] == 0)	{
						$metric_score{$metric}->[$n] = 1;
					}	else	{
						$metric_score{$metric}->[$n] = $report{$metric}->[$n]/$metric[-1];
					}
				}
			}
		}
		# caculate group score
		foreach my $metric (keys %{$weight->{$group}->{'member'}})	{
			$weight->{$group}->{'member'}->{$metric} /= $metric_weight;
			foreach my $n (0..$#{$report{$metric}})	{
				# re-scale metric weight
				$group_score{$group}->[$n] += $metric_score{$metric}->[$n]*$weight->{$group}->{'member'}->{$metric};
			}
		}
	}

	# calculate total score
	my %total_score;
	foreach my $group (keys %group_score)	{
		# re-scale group weight
		$weight->{$group}->{'weight'} /= $group_weight;
		foreach my $n (0..$#{$group_score{$group}})	{
			$total_score{$n} += $group_score{$group}->[$n]*$weight->{$group}->{'weight'};
		}
	}

	# rank based on total score
	my @total_score = sort {$b<=>$a} values %total_score;
	my %rank;
	foreach my $n (0..$#total_score)	{
		$rank{$total_score[$n]} = $n + 1;
	}

	# generate output
	open RANK, "> $global_opt->{'out_dir'}/evaluation/$type.rank.txt" or die "Can't write to $type.rank.txt!\n";
	print RANK "Assembly\t".(join "\t", @protocol)."\n";
	# print metric score
	print RANK "\n#####Metric Score#####\n";
	foreach my $group (sort keys %{$weight})	{
		foreach my $metric (sort keys %{$weight->{$group}->{'member'}})	{
			print RANK "$metric";
			foreach my $metric_score (@{$metric_score{$metric}})	{
				print RANK "\t".(nearest(0.01, $metric_score));
			}
			print RANK "\n";
		}
	}
	print RANK "\n#####Group Score#####\n";
	foreach my $group (sort keys %{$weight})	{
		print RANK "$group";
		foreach my $group_score (@{$group_score{$group}})	{
			print RANK "\t".(nearest(0.01, $group_score));
		}
		print RANK "\n";
	}
	# print final rank
	print RANK "\n#####Final Rank#####\nRank";
	foreach my $n (0..$#protocol)	{
		print RANK "\t$rank{$total_score{$n}}";
	}
	print RANK "\n";
	close (RANK);

	return;
}

#############################
# verify weight matrix
#############################
sub init_weight {
	(my $custom_weight, my $gage, my $ref, my $warn_msg) = @_;

	# set compatible metrics
	my %metric;
	if ($gage)	{
		%metric = (
			"Contigs #" => "min",
			"Min contig" => "max",
			"Max contig" => "max",
			"N50" => "max",
			"Assembly size" => "max",
			"Chaff bases" => "min",
			"Missing reference bases" => "min",
			"Missing assembly bases" => "min",
			"Missing assembly contigs" => "min",
			"Duplicated reference bases" => "min",
			"Compressed reference bases" => "min",
			"Bad trim" => "min",
			"Avg idy" => "min",
			"SNPs" => "min",
			"Indels < 5bp" => "min",
			"Indels >= 5" => "min",
			"Inversions" => "min",
			"Relocation" => "min",
			"Translocation" => "min",
			"# misassemblies" => "min",
			"Corrected contig #" => "max",
			"Corrected assembly size" => "max",
			"Min correct contig" => "max",
			"Max correct contig" => "max",
			"Corrected N50" => "max",
			"Cost" => "min",
		);
	}	elsif ($ref)	{
		%metric = (
			"# contigs (>= 0 bp)" => "min",
			"# contigs (>= 1000 bp)" => "min",
			"Total length (>= 0 bp)" => "max",
			"Total length (>= 1000 bp)" => "max",
			"# contigs" => "min",
			"Largest contig" => "max",
			"Total length" => "max",
			"GC (%)" => "min",
			"N50" => "max",
			"NG50" => "max",
			"N75" => "max",
			"NG75" => "max",
			"L50" => "min",
			"LG50" => "min",
			"L75" => "min",
			"LG75" => "min",
			"# misassemblies" => "min",
			"# misassembled contigs" => "min",
			"Misassembled contigs length" => "min",
			"# local misassemblies" => "min",
			"# unaligned contigs" => "min",
			"Unaligned length" => "min",
			"Genome fraction (%)" => "max",
			"Duplication ratio" => "min",
			"# N's per 100 kbp" => "min",
			"# mismatches per 100 kbp" => "min",
			"# indels per 100 kbp" => "min",
			"Largest alignment" => "max",
			"NA50" => "max",
			"NGA50" => "max",
			"NA75" => "max",
			"NGA75" => "max",
			"LA50" => "min",
			"LGA50" => "min",
			"LA75" => "min",
			"LGA75" => "min",
			"Cost" => "min",
		);
	}	else	{
		%metric = (
			"# contigs (>= 0 bp)" => "min",
			"# contigs (>= 1000 bp)" => "min",
			"Total length (>= 0 bp)" => "max",
			"Total length (>= 1000 bp)" => "max",
			"# contigs" => "min",
			"Largest contig" => "max",
			"Total length" => "max",
			"GC (%)" => "min",
			"N50" => "max",
			"N75" => "max",
			"L50" => "min",
			"L75" => "min",
			"# N's per 100 kbp" => "min",
			"Cost" => "min",
		);
	}
	
	# set weight settings
	my %weight;

	# read custom weight settings
	if (defined($custom_weight) && -e "$custom_weight")	{
		open IN, "< $custom_weight" or die "Can't open $custom_weight!\n";
		while (<IN>)	{
			next if (/^[\#\-]/);
			next unless (/\w/);
			(my $weight = $_) =~ s/(^\s+|\s+$)//g;
			my @weight = split /\s+\|\s+/, $weight;
			if ($weight[-1] =~ /^[\d\.]+$/)	{
				if ($#weight == 1)	{
					# read group settings
					$weight{$weight[0]}->{'weight'} = $weight[1];
				}	elsif ($#weight == 2)	{
					# read metric settings
					unless (exists ($metric{$weight[1]}))	{
						push @{$warn_msg}, "\t\tThe metric $weight[1] is not compatible and will be ignored!\n";
						next;
					}
					$weight{$weight[0]}->{'member'}->{$weight[1]} = $weight[2];
				}	else	{
					push @{$warn_msg}, "\t\tThe following line in the custome weight file cannot be recognized and will be ignored:\n\t\t\t$_";
				}
			}	else	{
				push @{$warn_msg}, "\t\tThe following line in the custome weight file cannot be recognized and will be ignored:\n\t\t\t$_";
			}
		}
		close (IN);
	
		# verify custom weight settings
		foreach my $group (keys %weight)	{
			unless (exists $weight{$group}->{'member'})	{
				delete $weight{$group};
				push @{$warn_msg}, "\t\tThe group $group contains no metric and will be ignored!\n";
				next;
			}
			unless (exists $weight{$group}->{'weight'})	{
				delete $weight{$group};
				push @{$warn_msg}, "\t\tThe group $group does not have a weight and will be ignored!\n";
				next;
			}
		}	
	}

	# use defaults if custome weight settingss are not set properly
	unless (%weight)	{
		if ($gage)	{
			%weight = (
				"Contiguity" => {
					"weight" => 0.3,
					"member" => {
						"Corrected contig #" => 0.3,
						"Corrected N50" => 0.4,
						"Max correct contig" => 0.3,
					},
				},
				"Completeness" => {
					"weight" => 0.3,
					"member" => {
						"Corrected assembly size" => 0.5,
						"Missing reference bases" => 0.5,
					},
				},
				"Correctness" => {
					"weight" => 0.3,
					"member" => {
						"Missing assembly bases" => 0.3,
						"Avg idy" => 0.3,
						"# misassemblies" => 0.4,
					},
				},
				"Cost" => {
					"weight" => 0.1,
					"member" => {
						"Cost" => 1,
					},
				},
			);
		}	elsif ($ref)	{
			%weight = (
				"Contiguity" => {
					"weight" => 0.4,
					"member" => {
						"LA50" => 0.2,
						"NA50" => 0.4,
						"Largest alignment" => 0.4,
					},
				},
				"Completeness" => {
					"weight" => 0.4,
					"member" => {
						"Genome fraction" => 0.6,
						"Duplication ratio" => 0.2,
					},
				},
				"Correctness" => {
					"weight" => 0.1,
					"member" => {
						"Unaligned length" => 0.3,
						"# mismatches per 100 kbp" => 0.3,
						"# misassemblies" => 0.4,
					},
				},
				"Cost" => {
					"weight" => 0.1,
					"member" => {
						"Cost" => 1,
					},
				},
			);
		}	else	{
			%weight = (
				"Contiguity" => {
					"weight" => 0.4,
					"member" => {
						"# contigs (>= 1000 bp)" => 0.2,
						"N50" => 0.4,
						"Largest contig" => 0.4,
					},
				},
				"Completeness" => {
					"weight" => 0.4,
					"member" => {
						"Total length (>= 0 bp)" => 0.6,
						"Total length (>= 1000 bp)" => 0.2,
						"# N's per 100 kbp" => 0.2,
					},
				},
				"Correctness" => {
					"weight" => 0.1,
					"member" => {
						"GC (%)" => 1,
					},
				},
				"Cost" => {
					"weight" => 0.1,
					"member" => {
						"Cost" => 1,
					},
				},
			);
		}
	}
	
	return (\%weight, \%metric);
}

#############################
# set metrics that need to be processed
#############################
sub special_metric	{
	my $gage = $_[0];
	
	my %special_metric;
	if ($gage)	{
		%special_metric = (
			"N50" => "count",
			"Corrected N50" => "count",
			"Missing reference bases" => "frac",
			"Missing assembly bases" => "frac",
			"Missing assembly contigs" => "frac",
		);
	}	else	{
		%special_metric = (
			"# unaligned contigs" => "part",
		);
	}

	return %special_metric;
}

#############################
# calculate the size of the reference genome
#############################
sub genomeSize	{
	my $genome = $_[0];

	my $size = 0;
	open IN, "< $genome" or die "Can't open $genome!\n";
	while (<IN>)	{
		next if (/>/);
		chomp;
		$size += length($_);
	}
	close (IN);

	return $size;
}

#############################
# rename reads in FASTQ file
#############################
sub rename_fastq	{
	(my $file, my $library) = @_;
	
	open OLD, "< $file" or die "Can't open $file!\n";
	open NEW, "> $file.renamed" or die "Can't open $file!\n";
	my $count = 1;
	while (my $read = <OLD>)	{
		$read =~ s/^\@/\@$library\_/;
		print NEW $read;
		$read = <OLD>;
		print NEW $read;
		$read = <OLD>;
		print NEW "+\n";
		$read = <OLD>;
		print NEW $read;
		$count++;
	}
	close (OLD);
	close (NEW);

	system("mv $file.renamed $file");
	
	return;
}

1;
