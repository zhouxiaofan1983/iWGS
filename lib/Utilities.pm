package Utilities;

use strict;
use warnings;

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
# set prices of sequencing
#############################
sub set_price	{
	my $pricing_info = $_[0];

	&validate_price($pricing_info);

	my %price;
	open PRICE, "< $pricing_info" or die "ERROR! Fail to initialize the pricing information.\nThe file $pricing_info does not exist!\n";
	while (<PRICE>)	{
		next if (/^#/);
		chomp;
		my @price = split /\t/;
		@price[0..3] = map { lc($_) } @price[0..3];
		if ($price[0] eq "illumina")	{
			$price{'seq'}->{$price[2]}->{$price[3]} = $price[5];				# set per lane sequencing price
			$price{'prep'}->{$price[2]} = $price[4];					# set library preparation price
			$price{'throughput'}->{$price[2]}->{$price[3]} = $price[6];			# set sequencing throughput (total number of reads) for Illumiona (per lane) and PacBio (per flowcell)
		}	else	{
			$price{'seq'}->{$price[2]} = $price[5];						# set per lane sequencing price
			$price{'prep'}->{$price[2]} = $price[4];					# set library preparation price
			$price{'throughput'}->{$price[2]} = $price[6];					# set sequencing throughput (total number of reads) for Illumiona (per lane) and PacBio (per flowcell)
		}
	}
	close (PRICE);

	return %price;
}

#############################
# validate the file containing price information of sequencing
#############################
sub validate_price	{
	my $pricing_info = $_[0];

	my %err_msg; my $err_msg;
	open PRICE, "< $pricing_info" or die "ERROR! Fail to initialize the pricing information.\nThe file $pricing_info does not exist!\n";
	while (<PRICE>)	{
		next if (/^#/);
		chomp;
		my @price = split /\t/;
		@price[0..3] = map { lc($_) } @price[0..3];

		if ($price[0] eq "illumina")	{
			unless ($price[1] eq "hiseq" || $price[1] eq "miseq")	{
				$err_msg = "Invalid Illumina sequencing platform! Should be one of \"HiSeq\" and \"MiSeq\".\n";
				$err_msg{$err_msg} = 1;
			}
			unless ($price[2] eq "se" || $price[2] eq "pe" || $price[2] eq "mp")	{
				$err_msg = "Invalid Illumina library type! Should be one of \"SE\", \"PE\", and \"MP\".\n";
				$err_msg{$err_msg} = 1;
			}
			unless ($price[3] =~ /^\d+$/)	{
				$err_msg = "Invalid Illumina read length! Should be numerical.\n";
				$err_msg{$err_msg} = 1;
			}
		}	elsif ($price[0] eq "pacbio")	{
			unless (($price[2] eq "ccs" && $price[3] eq "short") || ($price [2] eq "clr" && $price[3] eq "long"))	{
				$err_msg = "Invalid PacBio library type and read length! Should be one of \"CCS short\" and \"CLR long\".\n";
				$err_msg{$err_msg} = 1;
			}
		}	else	{
			$err_msg = "Invalid sequencing technology! Currently only \"Illumina\" and \"PacBio\" are supported.\n\n";
			$err_msg{$err_msg} = 1;
		}
		unless ($price[4] =~ /^\d+$/ && $price[5] =~ /^\d+$/ && $price[6] =~ /^\d+$/)	{
			$err_msg = "Invalid sequencing technology! Prices of library preparation and sequencing as well as sequencing througput should all be numerical.\n";
			$err_msg{$err_msg} = 1;
		}
	}
	close (PRICE);
	
	if (%err_msg)	{
		$err_msg = join "", sort keys %err_msg;
		die "ERROR! Fail to initialize the pricing information.\n$err_msg";
	}

	return;
}

#############################
## calculate sequencing price
#############################
sub calculate_price	{
	(my $global_opt, my $pricing_info) = @_;

	my $genome_size = &genomeSize($global_opt->{'genome'});

	# set the pricing information
	my %price = &set_price($pricing_info);
	
	my %library_price;
	foreach my $library (keys %{$global_opt->{'library'}})	{
		# add the price of library preparation
		my $lib_opt = $global_opt->{'library'}->{$library};
		$library_price{$library} = $price{'prep'}->{$lib_opt->{'read_type'}};
		if ($lib_opt->{'read_type'} eq "clr")	{
			# add the sequencing price of a PacBio library
			$library_price{$library} += $lib_opt->{'parameters'}->[0]*$genome_size/$price{'throughput'}->{$lib_opt->{'read_type'}}*$price{'seq'}->{$lib_opt->{'read_type'}};
		}	elsif ($lib_opt->{'read_type'} eq "se")	{
			# add the sequencing price of a Illumina SE library
			$library_price{$library} += $lib_opt->{'parameters'}->[0]*$genome_size/($price{'throughput'}->{$lib_opt->{'read_type'}}->{$lib_opt->{'parameters'}->[1]}*$lib_opt->{'parameters'}->[1])*$price{'seq'}->{$lib_opt->{'read_type'}}->{$lib_opt->{'parameters'}->[1]};
		}	else	{
			# add the sequencing price of a Illumina PE/MP library
			$library_price{$library} += $lib_opt->{'parameters'}->[0]*$genome_size/($price{'throughput'}->{$lib_opt->{'read_type'}}->{$lib_opt->{'parameters'}->[1]}*$lib_opt->{'parameters'}->[1]*2)*$price{'seq'}->{$lib_opt->{'read_type'}}->{$lib_opt->{'parameters'}->[1]};
		}
	}

	my %protocol_price;
	foreach my $protocol (keys %{$global_opt->{'protocol'}})	{
		foreach my $library (@{$global_opt->{'protocol'}->{$protocol}->{'library'}})	{
			$protocol_price{$protocol} += $library_price{$library};
		}
	}

	open COST, "> $global_opt->{'out_dir'}/total_cost.out" or die "Can't write to total_cost.out!";
	print COST "Cost for each library:\n";
	foreach my $library (sort keys %library_price)	{
		print COST "$library\t".(int(100*$library_price{$library}+0.5)/100)."\n";
	}
	print COST "\nCost for each assembly protocol:\n";
	foreach my $protocol (sort keys %protocol_price)	{
		print COST "$protocol\t".(int(100*$protocol_price{$protocol}+0.5)/100)."\n";
	}
	close (COST);

	return;
}

#############################
# Calculate the size of the reference genome
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

1;
