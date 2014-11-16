package Ctrl;

use strict;
use warnings;

use Cwd;
use lib ("$FindBin::Bin/lib");
use File::Basename;
use File::Which;

#############################
# set default values for global options
#############################
sub init_global_opt	{
	my $root_dir = "$FindBin::Bin";

	my %global_opt = (
		"genome" => undef,
		"genome_size" => 0,
		"threads" => 1,
		"memory" => 8,
		"out_dir" => getcwd(),
		"qc" => undef,
		"pirs" => {
			"error_rate" => 1,						# set to "1" to use default setting of pIRS
			"error_profile" => undef,					# leave it blank to use the default profile of pIRS
			"gc" => 1,
			"gc_profile" => undef,						# leave it blank to use the default profile of pIRS
			"indel" => 1,
			"indel_profile" => undef,
		},									# leave it blank to use the default profile of pIRS
		"art" => {
			"qual_shift1" => 0,
			"qual_shift2" => 0,
			"qual_profile1" => undef,					# leave it blank to use the default profile of ART
			"qual_profile2" => undef,					# leave it blank to use the default profile of ART
			"ins_rate1" => "0.00009",
			"ins_rate2" => "0.00015",
			"del_rate1" => "0.00011",
			"del_rate2" => "0.00023",
		},
		"pbsim" => {
			"ratio" => "10:60:30",
			"length_mean" => "3000",
			"length_sd" => "2300",
			"length_max" => "25000",
			"length_min" => "100",
			"accuracy_max" => "0.90",
			"accuracy_min" => "0.75",
		},
		"trimmomatic" => {
			"trailing" => "3",
			"adapters" => undef,
			"minlen" => "25",
		},
		"nextclip" => {
			"adapter" => "CTGTCTCTTATACACATCT",
			"minlen" => "25",
		}, 
		"quake" => {
			"kmer" => 0,
			"minlen" => "25",
		},
		"abyss" => {
			"kmer" => 0,
			"option" => "l=1 n=5 s=100",
		},
		"allpaths" => {
			"ploidy" => 1,
		},
		"ca" => {
			"sensitive" => 0,
		},
		"discovar" => undef,
		"soapdenovo2" => {
			"kmer" => 0,
			"option" => "–F –R –E –w –u",
		},
		"spades" => {
			"kmer" => 0,
			"multi-kmer" => 1,
			"option" => "--only-assembler",					# or "--careful"
		},
		"dipspades" => {
			"kmer" => 0,
			"multi-kmer" => 1,
			"option" => "--only-assembler",					# or "--careful"
		},
		"velvet" => {
			"kmer" => 0,
			"option" => "-exp_cov auto -scaffolding yes",
		},
		"quast" => {
			"eukaryote" => 1,
			"gage" => 1,
			"gene" => undef,
		},
		"library" => undef,
		"protocol" => undef,
	);
		
	$global_opt{'bin'}->{'pirs'} = (-e "$root_dir/tools/pIRS/pirs") ? "$root_dir/tools/pIRS/pirs" : File::Which::which("pirs");
	$global_opt{'bin'}->{'art'} = (-e "$root_dir/tools/ART/art_illumina") ? "$root_dir/tools/ART/art_illumina" : File::Which::which("art_illumina");
	$global_opt{'bin'}->{'pbsim'} = (-e "$root_dir/tools/PBSIM/bin/pbsim") ? "$root_dir/tools/PBSIM/bin/pbsim" : File::Which::which("pbsim");
	$global_opt{'bin'}->{'trimmomatic'} = (-e "$root_dir/tools/Trimmomatic/trimmomatic.jar") ? "$root_dir/tools/Trimmomatic/trimmomatic.jar" : File::Which::which("trimmomatic.jar");
	$global_opt{'bin'}->{'nextclip'} = (-e "$root_dir/tools/NextClip/bin/nextclip") ? "$root_dir/tools/NextClip/bin/nextclip" : File::Which::which("nextclip");
	$global_opt{'bin'}->{'quake'} = (-e "$root_dir/tools/Quake/bin/quake.py") ? "$root_dir/tools/Quake/bin/quake.py" : File::Which::which("quake.py");
	$global_opt{'bin'}->{'kmergenie'} = (-e "$root_dir/tools/kmergenie/kmergenie") ? "$root_dir/tools/kmergenie/kmergenie" : File::Which::which("kmergenie");
	$global_opt{'bin'}->{'abyss'} = (-e "$root_dir/tools/ABYSS/bin/abyss-pe") ? "$root_dir/tools/ABYSS/bin/abyss-pe" : File::Which::which("abyss-pe");
	$global_opt{'bin'}->{'allpaths'} = (-e "$root_dir/tools/ALLPATHS-LG/bin/RunAllPathsLG") ? "$root_dir/tools/ALLPATHS-LG/bin/RunAllPathsLG" : File::Which::which("RunAllPathsLG");
	$global_opt{'bin'}->{'ca'} = (-e "$root_dir/tools/CA/bin/PBcR") ? "$root_dir/tools/CA/bin/PBcR" : File::Which::which("PBcR");
	$global_opt{'bin'}->{'discovar'} = (-e "$root_dir/tools/DISCOVAR/bin/DiscovarExp") ? "$root_dir/tools/DISCOVAR/bin/Discovarexp" : File::Which::which("Discovarexp");
	$global_opt{'bin'}->{'soapdenovo2'} = (-e "$root_dir/tools/SOAPdenovo2/SOAPdenovo2") ? "$root_dir/tools/SOAPdenovo2/SOAPdenovo2" : File::Which::which("SOAPdenovo2");
	$global_opt{'bin'}->{'spades'} = (-e "$root_dir/tools/SPAdes/bin/spades.py") ? "$root_dir/tools/SPAdes/bin/spades.py" : File::Which::which("spades.py");
	$global_opt{'bin'}->{'dipspades'} = (-e "$root_dir/tools/SPAdes/bin/dipspades.py") ? "$root_dir/tools/dipSPAdes/bin/dipspades.py" : File::Which::which("dipspades.py");
	$global_opt{'bin'}->{'velvetg'} = (-e "$root_dir/tools/Velvet/velvetg") ? "$root_dir/tools/Velvet/velvetg" : File::Which::which("velvetg");
	$global_opt{'bin'}->{'velveth'} = (-e "$root_dir/tools/Velvet/velveth") ? "$root_dir/tools/Velvet/velveth" : File::Which::which("velveth");
	$global_opt{'bin'}->{'picard'} = (-e "$root_dir/tools/Picard/picard.jar") ? "$root_dir/tools/Picard/picard.jar" : File::Which::which("picard.jar");
	$global_opt{'bin'}->{'quast'} = (-e "$root_dir/tools/QUAST/quast.py") ? "$root_dir/tools/QUAST/quast.py" : File::Which::which("quast.py");
		
	$global_opt{'pbsim'}->{'model_qc'} = (defined($global_opt{'bin'}->{'pbsim'})) ? dirname($global_opt{'bin'}->{'pbsim'})."/../data/model_qc_clr" : undef;

	return %global_opt;
}


#############################
# override default setings with command line arguments
##############################
sub override_opt	{
	(my $opt, my $global_opt, my $err_msg) = @_;
	
	foreach my $key (keys %{$opt})	{
		if ($key =~ /\./)	{
			my @key = split /\./, $key;
			unless (exists $global_opt->{$key[0]}->{$key[1]}) { push @{$err_msg}, "\tThe option \"$key\" is unknown, please verify.\n"; }
			if ($key[1] eq "option")	{
				$opt->{$key} =~ s/^\"+|\"+$//g;
			}
			$global_opt->{$key[0]}->{$key[1]} = $opt->{$key};
		}	else	{
			unless (exists $global_opt->{$key}) { push @{$err_msg}, "\tThe option \"$key\" is unknown, please verify.\n"; }
			$global_opt->{$key} = $opt->{$key};
		}
	}

	return;
}

#############################
# read the global control file
##############################
sub read_global_ctrl_file	{
	(my $global_ctrl_file, my $global_opt) = @_;

	my @err_msg;
	
	# read the global control file
	my %opt;
	open IN, "< $global_ctrl_file" or die "Can't open the global control file: $global_ctrl_file!\n";
	while (my $line = <IN>)	{
		chomp($line);
		if ($line !~ /^\s*[\n\#]/ && $line =~ /^\s*([\w\.]+)\s*\=\s*([^\n\#]+)/)	{
			my $opt = lc($1);
			my $value = $2;
			next unless ($value =~ /\S/);
			$value =~ s/^\s+|\s+$//g;
			if ($opt eq "library")	{
				my @library = split /\,/, $value;
				$opt{$opt}->{$library[0]}->{'read_type'} = lc($library[1]);
				if ($opt{$opt}->{$library[0]}->{'read_type'} eq "clr")	{
					unless ($#library == 4)	{ push @err_msg, "\tConfiguration for the CLR library $library[0] should have 5 elements.\n"; }
					$opt{$opt}->{$library[0]}->{'depth'} = $library[2];
					$opt{$opt}->{$library[0]}->{'accuracy_mean'} = $library[3];
					$opt{$opt}->{$library[0]}->{'accuracy_sd'} = $library[4];
				}	elsif ($opt{$opt}->{$library[0]}->{'read_type'} eq "se")	{
					unless ($#library == 3) { push @err_msg, "\tConfiguration for the SE library $library[0] should have 4 elements.\n"; }
					$opt{$opt}->{$library[0]}->{'depth'} = $library[2];
					$opt{$opt}->{$library[0]}->{'read_length'} = $library[3];
				}	elsif ($opt{$opt}->{$library[0]}->{'read_type'} eq "pe" || $opt{$opt}->{$library[0]}->{'read_type'} eq "mp")	{
					unless ($#library == 5) { push @err_msg, "\tConfiguration for the PE/MP library $library[0] should have 6 elements.\n"; }
					$opt{$opt}->{$library[0]}->{'depth'} = $library[2];
					$opt{$opt}->{$library[0]}->{'read_length'} = $library[3];
					$opt{$opt}->{$library[0]}->{'frag_mean'} = $library[4];
					$opt{$opt}->{$library[0]}->{'frag_sd'} = $library[5];
				}	else	{
					push @err_msg, "\tLibrary $library[0] has invalid read type.\n";
				}
			}	elsif ($opt eq "protocol")	{
				my @protocol = split /\,/, $value;
				$opt{$opt}->{$protocol[0]}->{'assembler'} = lc($protocol[1]);
				# remove potential redundancy in input libraries for each assembly protocol
				my %library = map { $_ => 1 } @protocol[2..$#protocol];
				@{$opt{$opt}->{$protocol[0]}->{'library'}} = sort keys %library;
			}	else	{
				$opt{$opt} = $value;
			}
		}
	}
	close (IN);
	
	# override default settings with values obtained from the global control file
	&override_opt(\%opt, $global_opt, \@err_msg);
	
	if (@err_msg)	{
		my $err_msgs = join "", @err_msg;
		die "ERROR(s) detected in configurations:\n$err_msgs";
	}

	return;
}
	
#############################
# validate final settings of global options
##############################
sub check_global_opt	{
	(my $global_opt, my $real) = @_;

	# convert relative paths to absolute paths
	my $cwd = getcwd();
	if (defined($global_opt->{'genome'}) && $global_opt->{'genome'} !~ /^\//) { $global_opt->{'genome'} = $cwd."/".$global_opt->{'genome'}; }
	if (defined($global_opt->{'out_dir'}) && $global_opt->{'out_dir'} !~ /^\//) { $global_opt->{'out_dir'} = $cwd."/".$global_opt->{'out_dir'}; }
	if (defined($global_opt->{'trimmomatic'}->{'adapters'}) && $global_opt->{'trimmomatic'}->{'adapters'} !~ /^\//) { $global_opt->{'trimmomatic'}->{'adapters'} = $cwd."/".$global_opt->{'trimmomatic'}->{'adapters'}; }
	if (defined($global_opt->{'pirs'}->{'error_profile'}) && $global_opt->{'pirs'}->{'error_profile'} !~ /^\//) { $global_opt->{'pirs'}->{'error_profile'} = $cwd."/".$global_opt->{'pirs'}->{'error_profile'}; }
	if (defined($global_opt->{'pirs'}->{'gc_profile'}) && $global_opt->{'pirs'}->{'gc_profile'} !~ /^\//) { $global_opt->{'pirs'}->{'gcc_profile'} = $cwd."/".$global_opt->{'pirs'}->{'gc_profile'}; }
	if (defined($global_opt->{'pirs'}->{'indel_profile'}) && $global_opt->{'pirs'}->{'indel_profile'} !~ /^\//) { $global_opt->{'pirs'}->{'indel_profile'} = $cwd."/".$global_opt->{'pirs'}->{'indel_profile'}; }
	if (defined($global_opt->{'art'}->{'qual_profile1'}) && $global_opt->{'art'}->{'qual_profile1'} !~ /^\//) { $global_opt->{'art'}->{'qual_profile1'} = $cwd."/".$global_opt->{'art'}->{'qual_profile1'}; }
	if (defined($global_opt->{'art'}->{'qual_profile2'}) && $global_opt->{'art'}->{'qual_profile2'} !~ /^\//) { $global_opt->{'art'}->{'qual_profile2'} = $cwd."/".$global_opt->{'art'}->{'qual_profile2'}; }
	if (defined($global_opt->{'pbsim'}->{'model_qc'}) && $global_opt->{'pbsim'}->{'model_qc'} !~ /^\//) { $global_opt->{'pbsim'}->{'model_qc'} = $cwd."/".$global_opt->{'pbsim'}->{'model_qc'}; }
	if (defined($global_opt->{'quast'}->{'gene'}) && $global_opt->{'quast'}->{'gene'} !~ /^\//) { $global_opt->{'quast'}->{'gene'} = $cwd."/".$global_opt->{'quast'}->{'gene'}; }	

	my @err_msg; my @warn_msg;
	# check general settings
	unless (($real == 1 && !defined($global_opt->{'genome'})) || (defined($global_opt->{'genome'}) && -e $global_opt->{'genome'})) { push @err_msg, "\tThe reference genome sequence does not exist.\n"; }
	unless ($global_opt->{'genome_size'} =~ /^\d+$/ && ($real == 0 || $global_opt->{'genome_size'} > 0)) { push @err_msg, "\tThe genome size should be an integer no less than zero (must be positive if a reference genome is not provided).\n"; }
	unless ($global_opt->{'threads'} =~ /^\d+$/ && $global_opt->{'threads'} > 0) { push @err_msg, "\tThe number of threads to use should be a positive integer.\n"; }
	unless ($global_opt->{'memory'} =~ /^\d+$/ && $global_opt->{'memory'} > 0) { push @err_msg, "\tThe amount of memory to use should be a positive integer.\n"; }
	# check the settings of libraries and assembly protocols (e.g. if executables are available, if libraries and protocols are compatible)
	if (defined($global_opt->{'library'}) && defined($global_opt->{'protocol'}))	{
		# if QC is turn on, prepare QC settings for relevant libraries
		if (defined($global_opt->{'qc'}))	{
			&qc_setup($global_opt, \@err_msg, \@warn_msg);
		}
		&check_libraries($global_opt, \@err_msg, \@warn_msg);
		&check_protocols($global_opt, \@err_msg);
		&check_compatibility($global_opt->{'library'}, $global_opt->{'protocol'}, \@err_msg);
	}	elsif (defined($global_opt->{'library'}) || defined($global_opt->{'protocol'}))	{
		push @err_msg, "\tPlease specify at least one library and one assembly protocol together, or leave both blank to run with default settings.\n";
	}	else	{
		&default_protocol($global_opt);
		push @warn_msg, "\tNo library or assembly protocol specified, continue with the default settings.\n";
	}
	# check the settings for QUAST
	unless (defined($global_opt->{'bin'}->{'quast'}) && -e $global_opt->{'bin'}->{'quast'}) { push @err_msg, "\tThe required genome assembly evaluation tool QUAST is not available.\n";}
	unless ($global_opt->{'quast'}->{'eukaryote'} =~ /^[01]$/) { push @err_msg, "\tThe option \"QUAST.eukaryote\" should be either \"0\" or \"1\".\n"; }
	unless ($global_opt->{'quast'}->{'gage'} =~ /^[01]$/) { push @err_msg, "\tThe option \"QUAST.gage\" should be either \"0\" or \"1\".\n"; }
	unless (!defined($global_opt->{'quast'}->{'gene'}) || -e $global_opt->{'quast'}->{'gene'}) { push @err_msg, "\tThe gene annotation file for QUAST does not exist.\n"; }

	# if one or more warnings were detected, print out the message
	if (@warn_msg)	{
		my $warn_msg = join "", @warn_msg;
		print "WARNING(s) detected in configurations:\n$warn_msg\n";
	}

	# if one or more errors were detected, print out the message and quit
	if (@err_msg)	{
		my $err_msg = join "", @err_msg;
		die "ERROR(s) detected in configurations:\n$err_msg\n";
	}

	return;
}

#############################
# prepare QC settings for relevant libraries
#############################
sub qc_setup	{
	(my $global_opt, my $err_msg, my $warn_msg) = @_;

	# read in adapter seuqneces for Trimmomatic adapter trimming
	my %adapter; my %invalid;
	if (defined($global_opt->{'trimmomatic'}->{'adapters'}))	{
		if  (-e $global_opt->{'trimmomatic'}->{'adapters'})	{
			open ADAPTER, "< $global_opt->{'trimmomatic'}->{'adapters'}" or die "Can't open $global_opt->{'trimmomatic'}->{'adapters'}!\n";
			while (<ADAPTER>)	{
				next unless /\w/;
				chomp;
				my @adapter = split /\s+/;
				if ($#adapter == 1)	{
					if (defined($global_opt->{'library'}->{$adapter[0]}))	{
						$adapter{$adapter[0]} = $adapter[1];
					}	else	{
						$invalid{$adapter[0]} = 1;
					}
				}	else	{
					push @{$err_msg}, "\tThe following line in the adapter list for Trimmomatic is not in a correct format:\n\t\t\"$_\"\n";
				}
			}
			close (ADAPTER);
		}	else	{
			push @{$err_msg}, "\tThe adapter list for Trimmomatic does not exist.\n";
		}
	}

	# report libraries mentioned only in the adapter sequence file
	if (%invalid)	{
		push @{$warn_msg}, "\t".(join ", ", sort keys %invalid)." mentioned only in the adapter list, will be ignored.\n";
	}

	# loop through all libraries with QC enabled
	my @qc_libs = ($global_opt->{'qc'} eq "all") ? keys %{$global_opt->{'library'}} : split /,/, $global_opt->{'qc'};
	foreach my $library (@qc_libs)	{
		my @err_msg; my @warn_msg;
		if (defined($global_opt->{'library'}->{$library}))	{
			if ($global_opt->{'library'}->{$library}->{'read_type'} eq "clr")	{
				push @warn_msg, "\t\tQC for this library will be skipped, since PacBio CLR data is not supported.\n";
			}	else	{
				# set the QC flag for qualified library
				$global_opt->{'library'}->{$library}->{'qc'} = 1;
				# set Trimmomatic quality trimming parameters
				$global_opt->{'library'}->{$library}->{'tm-trailing'} = $global_opt->{'trimmomatic'}->{'trailing'};
				$global_opt->{'library'}->{$library}->{'tm-minlen'} = $global_opt->{'trimmomatic'}->{'minlen'};
				if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se" || $global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
					# set adapter sequences for qualified SE/PE library
					$global_opt->{'library'}->{$library}->{'qk-kmer'} = $global_opt->{'quake'}->{'kmer'};
					$global_opt->{'library'}->{$library}->{'qk-minlen'} = $global_opt->{'quake'}->{'minlen'};
				}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
					# set adapter sequence for MP library
					$global_opt->{'library'}->{$library}->{'nc-adapter'} = $global_opt->{'nextclip'}->{'adapter'};
					$global_opt->{'library'}->{$library}->{'nc-minlen'} = $global_opt->{'nextclip'}->{'minlen'};
				}
			}
			if (defined($adapter{$library}))        {
				if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se" || $global_opt->{'library'}->{$library}->{'read_type'} eq "pe") {
					$global_opt->{'library'}->{$library}->{'tm-adapter'} = $adapter{$library};
				}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
					push @warn_msg, "\t\tTrimmomatic adapter trimming is not compatible with ".uc($global_opt->{'library'}->{$library}->{'read_type'})." library (use NextClip instead), will be ignored.\n";
				}
				delete $adapter{$library};
			}
		}	else	{
			push @err_msg, "\t\tthe library $library does not exist.\n";	
		}
		if (@warn_msg)	{
			push @{$warn_msg}, "\tWarning(s) detected in QC settings for library $library:\n";
			push @{$warn_msg}, @warn_msg;
		}
		if (@err_msg)	{
			push @{$err_msg}, "\tProblem(s) detected in QC settings for library $library:\n";
			push @{$err_msg}, @err_msg;
		}
	}
	
	# check if QC has been enabled for all libraries mentioned in the adapter sequence file
	if (%adapter)	{
		push @{$warn_msg}, "\tQC is not enabled for ".(join ", ", sort keys %adapter).", the adapter sequences will be ignored.\n\n";
	}
	
	return;
}


#############################
# validate libraries
#############################
sub check_libraries	{
	(my $global_opt, my $err_msg, my $warn_msg) = @_;

	my $libraries = $global_opt->{'library'};
	foreach my $library (sort keys %{$libraries})	{
		# to collect library specific error messages
		my @err_msg; my @warn_msg;
		# check coverage, must be greater than 0
		unless (defined($libraries->{$library}->{'depth'}) && $libraries->{$library}->{'depth'} =~ /^[\d\.]+$/ && $libraries->{$library}->{'depth'} > 0) { push @err_msg, "\t\tcoverage should be a positive number.\n"; }
		# check settings for each library type
		if (defined($libraries->{$library}->{'read_type'}))	{
			if ($libraries->{$library}->{'read_type'} eq "clr")	{
				# check the avg of PacBio reads quality, must be between 0 and 1
				unless (defined($libraries->{$library}->{'accuracy_mean'}) && $libraries->{$library}->{'accuracy_mean'} =~ /^[\d\.]+$/ && $libraries->{$library}->{'accuracy_mean'} > 0 && $libraries->{$library}->{'accuracy_mean'} <= 1) { push @err_msg, "\t\tthe average reads quality should be a number in (0, 1].\n"; }
				# check the sd of PacBio reads quality, must be greater than 0
				unless (defined($libraries->{$library}->{'accuracy_sd'}) && $libraries->{$library}->{'accuracy_sd'} =~ /^[\d\.]+$/) { push @err_msg, "\t\tthe standard deviation of reads quality should be a number no less than zero.\n"; }
				&check_library("pbsim", $libraries->{$library}, $global_opt, \@err_msg, \@warn_msg);
			}	elsif ($libraries->{$library}->{'read_type'} eq "se")	{
				# check the read length, must be greater than 0
				unless (defined($libraries->{$library}->{'read_length'}) && $libraries->{$library}->{'read_length'} =~ /^\d+$/ && $libraries->{$library}->{'read_length'} > 0) { push @err_msg, "\t\tthe read length must be a positive integer.\n"; }
				&check_library("art", $libraries->{$library}, $global_opt, \@err_msg, \@warn_msg);
			}	elsif ($libraries->{$library}->{'read_type'} eq "pe" || $libraries->{$library}->{'read_type'} eq "mp")	{
				# check the average and standard deviation of insert size, must be greater than 0
				unless (defined($libraries->{$library}->{'frag_mean'}) && $libraries->{$library}->{'frag_mean'} =~ /^\d+$/ && $libraries->{$library}->{'frag_mean'} > 0) { push @err_msg, "\t\tthe average insert size should be a positive number.\n"; }
				if ($libraries->{$library}->{'read_type'} eq "pe" && $libraries->{$library}->{'frag_mean'} >= 2000)	{
					push @err_msg, "\t\tthe mean fragment size of a PE library should be smaller than 2kbp.\n";
				}	elsif ($libraries->{$library}->{'read_type'} eq "mp" && $libraries->{$library}->{'frag_mean'} < 2000)	{
					push @err_msg, "\t\tthe mean fragment size of a MP library should not be smaller than 2kbp.\n";
				}
				# check the standard deviation of insert size, must be greater than 0
				unless (defined($libraries->{$library}->{'frag_sd'}) && $libraries->{$library}->{'frag_sd'} =~ /^\d+$/) { push @err_msg, "\t\tthe standard deviation of insert size should be a number no less than zero.\n"; }
				# check the read length, must be greater than 0
				if (defined($libraries->{$library}->{'read_length'}) && $libraries->{$library}->{'read_length'} =~ /^\d+$/ && $libraries->{$library}->{'read_length'} > 0)	{
					if ($libraries->{$library}->{'read_length'} <= 100)	{
						&check_library("pirs", $libraries->{$library}, $global_opt, \@err_msg, \@warn_msg);
					}	else	{
						&check_library("art", $libraries->{$library}, $global_opt, \@err_msg, \@warn_msg);
					}	
				}	else	{
					push @err_msg, "\t\tthe read length must be a positive integer.\n";
				}
			}	else	{
				push @err_msg, "\t\tinvalid read type \"".$libraries->{$library}->{'read_type'}."\"\n";
			}
		}	else	{
			push @err_msg, "\t\tmust define a read type.\n";
		}
		if (@warn_msg)	{
			push @{$warn_msg}, "\tWarning(s) detected in the library $library:\n";
			push @{$warn_msg}, @warn_msg;
		}
		if (@err_msg)	{
			push @{$err_msg}, "\tProblem(s) detected in the library $library:\n";
			push @{$err_msg}, @err_msg;
		}
	}

	return;
}

#############################
# validate the settings of individual library 
#############################
sub check_library	{
	(my $simulator, my $library, my $global_opt, my $err_msg, my $warn_msg) = @_;
	
	# set simulator names
	my %simulator = (
		"pirs" => "pIRS",
		"art" => "ART",
		"pbsim" => "PBSIM",
	);
	
	# set simulator for the library
	if (exists $library->{'simulator'})	{
		unless (defined($simulator{$library->{'simulator'}}))	{ push @{$err_msg}, "\t\tthe specified simulator $library->{'simulator'} is invalid.\n"; }
		unless ($library->{'simulator'} eq $simulator)	{
			push @{$err_msg}, "\t\tthe specified simulator $library->{'simulator'} does not match the data type.\n";
			return;
		}
	}	else	{
		$library->{'simulator'} = $simulator;
	}

	# check the availability of the simulator
	unless (defined($global_opt->{'bin'}->{$simulator}) && -e $global_opt->{'bin'}->{$simulator}) { push @{$err_msg}, "\t\tthe required simulator $simulator{$simulator} is not available.\n"; }

	# check if all settings of the simulator exist
	foreach my $key (keys %{$global_opt->{$simulator}})	{
		unless (exists $library->{$key}) { $library->{$key} = $global_opt->{$simulator}->{$key}; }
	}

	# list general settings for each simulator
	my %general_settings = (
		"pirs" => {
			"depth" => 1,
			"read_type" => 1,
			"read_length" => 1,
			"frag_mean" => 1,
			"frag_sd" => 1,
		},
		"art" => {
			"depth" => 1,
			"read_type" => 1,
			"read_length" => 1,
			"frag_mean" => 1,
			"frag_sd" => 1,
		},
		"pbsim" => {
			"depth" => 1,
			"read_type" => 1,
			"accuracy_mean" => 1,
			"accuracy_sd" => 1,
		},
	);
	# list QC settings
	my %qc_settings = (
		"tm-trailing" => "trimmomatic",
		"tm-adapter" => "trimmomatic",
		"tm-minlen" => "trimmomatic",
		"nc-adapter" => "nextclip",
		"nc-minlen" => "nextclip",
		"qk-kmer" => "quake",
		"qk-minlen" => "quake",
	);
	# record all QC tasks
	my %qc_task;
	# check if settings for the library is compatible with the simulator
	foreach my $key (keys %{$library})	{
		unless ($key eq "simulator" || exists $general_settings{$simulator}->{$key} || exists $global_opt->{$simulator}->{$key} || $key eq "qc" || exists $qc_settings{$key}) { push @{$err_msg}, "\t\tthe option \"$key\" is not compatible with the simulator $simulator{$simulator} or the QC tools.\n"; }
		if (defined($qc_settings{$key}))	{
			$qc_task{$qc_settings{$key}} = 1;
		}
	}
	
	# check settings for each simulator
	if ($simulator eq "pirs")	{
		# check settings for pIRS
		unless ($library->{'error_rate'} =~ /^[\d\.]+$/ && ($library->{'error_rate'} == 0 || $library->{'error_rate'} == 1 || ($library->{'error_rate'} >= 0.0001 && $library->{'error_rate'} <= 0.63))) { push @{$err_msg}, "\t\tthe substitution rate for pIRS should be one of 0, 1, or a number between 0.0001 and 0.63.\n"; }
		unless (!defined($library->{'error_profile'}) || -e $library->{'error_profile'}) { push @{$err_msg}, "\t\tthe base-calling profile for pIRS does not exist.\n"; }
		unless ($library->{'gc'} =~ /^[01]$/) { push @{$err_msg}, "\t\tthe option \"Illumina.gc\" should be either \"0\" or \"1\".\n"; }
		unless (!defined($library->{'gc_profile'}) || -e $library->{'gc_profile'}) { push @{$err_msg}, "\t\tthe GC content coverage file for pIRS does not exist.\n"; }
		unless ($library->{'indel'} =~ /^[01]$/) { push @{$err_msg}, "\t\tthe option \"Illumina.indel\" should be either \"0\" or \"1\".\n"; }
		unless (!defined($library->{'indel_profile'}) || -e $library->{'indel_profile'}) { push @{$err_msg}, "\t\tthe Indel-error profile for pIRS does not exist.\n"; }
	}	elsif ($simulator eq "art")	{
		# check settings for ART
		unless ($library->{'qual_shift1'} =~ /^\-?\d+$/) { push @{$err_msg}, "\t\tthe amount to shfit first-read quality score for ART should be an integer.\n"; }
		unless ($library->{'read_type'} eq "se" || $library->{'qual_shift2'} =~ /^\-?\d+$/) { push @{$err_msg}, "\t\tthe amount to shfit second-read quality score for ART should be an integer.\n"; }
		unless (!defined($library->{'qual_profile1'}) || -e $library->{'qual_profile1'}) { push @{$err_msg}, "\t\tthe first-read quality profile for ART does not exist.\n"; }
		unless (!defined($library->{'qual_profile2'}) || -e $library->{'qual_profile2'}) { push @{$err_msg}, "\t\tthe second-read quality profile for ART does not exist.\n"; }
		unless ($library->{'ins_rate1'} =~ /^[\d\.]+$/) { push @{$err_msg}, "\t\tthe first-read insertion rate for ART should be a number no less than zero.\n"; }
		unless ($library->{'read_type'} eq "se" || $library->{'ins_rate2'} =~ /^[\d\.]+$/) { push @{$err_msg}, "\t\tthe second-read insertion rate for ART should be a number no less than zero.\n"; }
		unless ($library->{'del_rate1'} =~ /^[\d\.]+$/) { push @{$err_msg}, "\t\tthe first-read deletion rate for ART should be a number no less than zero.\n"; }
		unless ($library->{'read_type'} eq "se" || $library->{'del_rate2'} =~ /^[\d\.]+$/) { push @{$err_msg}, "\t\tthe second-read deletion rate for ART should be a number no less than zero.\n"; }
	}	elsif ($simulator eq "pbsim")	{
		# check setting for PBSIM
		unless (defined($library->{'model_qc'}) && -e $library->{'model_qc'}) { push @{$err_msg}, "\t\tthe quality code for PBSIM does not exist.\n"; }
		unless ($library->{'ratio'} =~ /^[\d\.]+\:[\d\.]+\:[\d\.]+$/) { push @{$err_msg}, "\t\tthe ratio of substitution:insertion:deletion errors in simulated PacBio reads should be the ratio between three numbers no less than zero, in a format similar to \"10:60:30\".\n"; }
		unless ($library->{'length_mean'} =~ /^[\d\.]+$/ && $library->{'length_mean'} > 0) { push @{$err_msg}, "\t\tthe mean of PacBio read length should be a positive number.\n"; }
		unless ($library->{'length_sd'} =~ /^[\d\.]+$/) { push @{$err_msg}, "\t\tthe standard deviation of PacBio read length should be a number no less than zero.\n"; }
		unless ($library->{'length_max'} =~ /^\d+$/ && $library->{'length_max'} >= $library->{'length_mean'}) { push @{$err_msg}, "\t\tthe maximum PacBio read length should be a positive integer no smaller than the mean read length.\n"; }
		unless ($library->{'length_min'} =~ /^\d+$/ && $library->{'length_min'} <= $library->{'length_mean'} && $library->{'length_min'} > 0) { push @{$err_msg}, "\t\tthe minimum PacBio read length should be a positive integer no larger than the mean read length.\n"; }
		unless ($library->{'accuracy_max'} =~ /^[\d\.]+$/ && $library->{'accuracy_max'} >= $library->{'accuracy_mean'} && $library->{'accuracy_max'} <= 1) { push @{$err_msg}, "\t\tthe maximum PacBio read accuracy should be a number between 0 and 1, and no smaller than the mean read accuracy.\n"; }
		unless ($library->{'accuracy_min'} =~ /^[\d\.]+$/ && $library->{'accuracy_min'} <= $library->{'accuracy_mean'} && $library->{'accuracy_max'} >= 0) { push @{$err_msg}, "\t\tthe minimum PacBio read accuracy should be a number between 0 and 1, and no larger than the mean read accuracy.\n"; }
	}

	# check QC settings
	if (defined($library->{'qc'}) && $library->{'qc'} == 1)	{
		unless (%qc_task)	{
			delete $library->{'qc'};
			push @{$warn_msg}, "\t\tQC is enabled for this library with NO QC task specified, will be ignored.\n";
		}
		if (defined($qc_task{'trimmomatic'}))	{
			unless (defined($global_opt->{'bin'}->{'trimmomatic'}) && -e $global_opt->{'bin'}->{'trimmomatic'}) { push @{$err_msg}, "\t\tthe required quality control tool Trimmomatic is not available.\n";}
			unless (!defined($library->{'tm-trailing'}) || $library->{'tm-trailing'} =~ /^\d+$/) { push @{$err_msg}, "\t\tthe threshold of Trimmomatic quality-based trimming should be an integer no less than zero.\n"; }
			unless (!defined($library->{'tm-minlen'}) || $library->{'tm-minlen'} =~ /^\d+$/) { push @{$err_msg}, "\t\tthe minimum read length after Trimmomatic trimming should be an integer no less than zero.\n"; }
			if (defined($library->{'tm-adapter'}))	{
				if ($library->{'read_type'} eq "se" || $library->{'read_type'} eq "pe")	{
					# convert relatvie path to absolute path
					if ($library->{'tm-adapter'} !~ /^\//) {
						$library->{'tm-adapter'} = getcwd()."/".$library->{'tm-adapter'};
					}
					unless (-e $library->{'tm-adapter'}) { push @{$err_msg}, "\t\tthe adapter sequence file for Trimmomatic does not exist.\n"; }
				}	else	{
					push @{$err_msg}, "\t\tTrimmomatic adapter trimming is not compatible with ".uc($library->{'read_type'})." library.\n";
				}
			}
		}
		if (defined($qc_task{'nextclip'}))	{
			if ($library->{'read_type'} eq "mp")	{
				unless (defined($global_opt->{'bin'}->{'nextclip'}) && -e $global_opt->{'bin'}->{'nextclip'}) { push @{$err_msg}, "\t\tthe required quality control tool NextClip is not available.\n";}
				unless (defined($library->{'nc-adapter'}) && $library->{'nc-adapter'} =~ /^[ATCG]+$/) { push @{$err_msg}, "\t\tadapter must be a valid DNA sequence"; }
				unless (defined($library->{'nc-minlen'}) && $library->{'nc-minlen'} =~ /^\d+$/) { push @{$err_msg}, "\t\tthe minimum read length after NextClip adapter trimming should be an integer no less than zero.\n"; }
			}	else	{
				push @{$err_msg}, "\t\tNextClip adapter trimming is not compatible with ".uc($library->{'read_type'})." library.\n";
			}
		}
		if (defined($qc_task{'quake'}))	{
			if ($library->{'read_type'} eq "se" || $library->{'read_type'} eq "pe")	{
				unless (defined($global_opt->{'bin'}->{'quake'}) && -e $global_opt->{'bin'}->{'quake'}) { push @{$err_msg}, "\t\tthe required quality control tool Quake is not available.\n";}
				unless (defined($library->{'qk-kmer'}) && $library->{'qk-kmer'} =~ /^\d+$/) { push @{$err_msg}, "\t\tthe k-mer size for Quake error correction should be an integer no less than zero.\n"; }
				unless (defined($library->{'qk-minlen'}) && $library->{'qk-minlen'} =~ /^\d+$/) { push @{$err_msg}, "\t\tthe minimum read length after Quake error correction should be an integer no less than zero.\n"; }
			}	else	{
				push @{$err_msg}, "\t\tQuake error correction is not compatible with ".uc($library->{'read_type'})." library.\n";
			}
		}
	}	else	{
		if (%qc_task)	{
			foreach my $key (%qc_settings)	{
				if (exists $library->{$key})	{ delete $library->{$key}; }
			}
			push @{$warn_msg}, "\t\tQC is turned off for this library, all QC settings will be ignored.\n";
		}
	}

	return;
}

#############################
# validate assembly protocols
#############################
sub check_protocols	{
	(my $global_opt, my $err_msg) = @_;
	
	# set the assembler names
	my %assembler = (
		"abyss" => "ABYSS",
		"allpaths" => "ALLPATHS-LG",
		"ca" => "Celera Assembler",
		"discovar" => "DISCOVAR de novo",
		"soapdenovo2" => "SOAPdenovo2",
		"spades" => "SPAdes",
		"dipspades" => "dipSPAdes",
		"velvet" => "Velvet",
	);
	# set assemblers that would invoke kmergenie
	my %kmergenie = (
		"abyss" => 1,
		"soapdenovo2" => 1,
		"spades" => 1,
		"dipspades" => 1,
		"velvet" => 1,
	);

	my $protocols = $global_opt->{'protocol'};
	foreach my $protocol (keys %{$protocols})	{
		# to collect protocol specific error messages
		my @err_msg;
		
		# check if the assembler is valid
		my $assembler = $protocols->{$protocol}->{'assembler'};
		unless (exists $assembler{$assembler})	{
			push @{$err_msg}, "\tProblem(s) detected in the assembly protocol $protocol:\n";
			push @{$err_msg}, "\t\tinvalid assembler $assembler.\n";
			next;
		}

		# check if all settings of the assembler exist
		foreach my $key (keys %{$global_opt->{$assembler}})	{
			unless (exists $protocols->{$protocol}->{$key}) { $protocols->{$protocol}->{$key} = $global_opt->{$assembler}->{$key}; }
		}
		# check if settings for the protocol is compatible with the assembler
		foreach my $key (keys %{$protocols->{$protocol}})	{
			unless ($key eq "assembler" || $key eq "library" || exists $global_opt->{$assembler}->{$key})	{ push @err_msg, "\t\tthe option \"$key\" is not compatible with the assembler $assembler{$assembler}."; }
		}

		# check the availability of the assembler
		if ($assembler eq "velvet")	{
			unless (defined($global_opt->{'bin'}->{'velvetg'}) && -e $global_opt->{'bin'}->{'velvetg'}) { push @err_msg, "\t\tthe assembler velvetg is not available.\n"; }
			unless (defined($global_opt->{'bin'}->{'velveth'}) && -e $global_opt->{'bin'}->{'velveth'}) { push @err_msg, "\t\tthe assembler velveth is not available.\n"; }
		}	else	{
			unless (defined($global_opt->{'bin'}->{$assembler}) && -e $global_opt->{'bin'}->{$assembler}) { push @err_msg, "\t\tthe assembler $assembler{$assembler} is not available.\n"; }
		}
		if (defined($kmergenie{$assembler}) && $protocols->{$protocol}->{'kmer'} eq "0")	{
			unless (defined($global_opt->{'bin'}->{'kmergenie'}) && -e $global_opt->{'bin'}->{'kmergenie'}) { push @err_msg, "\t\tthe k-mer optimizer KmerGenie is not available.\n"; }
		}	elsif ($assembler eq "discovar")	{
			unless (defined($global_opt->{'bin'}->{'picard'}) && -e $global_opt->{'bin'}->{'picard'}) { push @err_msg, "\t\tthe required tool Picard is not available.\n"; }
		}

		# check assembler specific options
		if ($assembler eq "abyss")	{
			unless ($protocols->{$protocol}->{'kmer'} =~ /^\d+$/ && ($protocols->{$protocol}->{'kmer'} == 0 || $protocols->{$protocol}->{'kmer'}%2 == 1)) { push @err_msg, "\t\tthe option \"kmer\" should be \"0\" or an odd number.\n"; }
		}	elsif ($assembler eq "allpaths")	{
			unless ($protocols->{$protocol}->{'ploidy'} =~ /^\d+$/ && $protocols->{$protocol}->{'ploidy'} > 0) { push @err_msg, "\t\tthe option \"ploidy\" should be a positive integer.\n"; }
		}	elsif ($assembler eq "ca")	{
			unless ($protocols->{$protocol}->{'sensitive'} =~ /^[01]$/) { push @err_msg, "\t\tthe option \"sensitive\" should be either \"0\" or \"1\".\n"; }
		}	elsif ($assembler eq "soapdenovo2")	{
			unless ($protocols->{$protocol}->{'kmer'} =~ /^\d+$/ && ($protocols->{$protocol}->{'kmer'} == 0 || $protocols->{$protocol}->{'kmer'}%2 == 1)) { push @err_msg, "\t\tthe option \"kmer\" should be \"0\" or an odd number.\n"; }
		}	elsif ($assembler eq "spades" || $assembler eq "dipspades")	{
			unless ($protocols->{$protocol}->{'kmer'} =~ /^\d+$/ && ($protocols->{$protocol}->{'kmer'} == 0 || $protocols->{$protocol}->{'kmer'}%2 == 1)) { push @err_msg, "\t\tthe option \"kmer\" should be \"0\" or an odd number.\n"; }
			unless ($protocols->{$protocol}->{'multi-kmer'} =~ /^[01]$/) { push @err_msg, "\t\tthe option \"multi-kmer\" should be either \"0\" or \"1\".\n"; }
		}	elsif ($assembler eq "velvet")	{
			unless ($protocols->{$protocol}->{'kmer'} =~ /^\d+$/ && ($protocols->{$protocol}->{'kmer'} == 0 || $protocols->{$protocol}->{'kmer'}%2 == 1)) { push @err_msg, "\t\tthe option \"kmer\" should be \"0\" or an odd number.\n"; }
		}

		if (@err_msg)	{
			push @{$err_msg}, "\tProblem(s) detected in the assembly protocol $protocol:\n";
			push @{$err_msg}, @err_msg;
		}
	}

	return;
}

#############################
# check the compatibility of libraries and assembly protocols
#############################
sub check_compatibility	{
	(my $libraries, my $protocols, my $err_msg) = @_;

	foreach my $protocol (sort keys %{$protocols})	{
		my @err_msg;

		my %read_type;
		foreach my $library (@{$protocols->{$protocol}->{'library'}})	{
			if (defined($libraries->{$library}))	{
				$read_type{$libraries->{$library}->{'read_type'}}->{$library} = 1;
			}	else	{
				push @err_msg, "\t\tthe required library $library does not exist.\n";
			}
		}
		if ($protocols->{$protocol}->{'assembler'} eq "abyss")	{			# a ABYSS protocol should have at least one PE library, and no PacBio library
			unless (exists $read_type{'pe'})	{
				push @err_msg, "\t\tABYSS requires at least one PE library.\n";
			}
			if (exists $read_type{'clr'})	{
				push @err_msg, "\t\tABYSS is not compatible with PacBio reads.\n";
			}
		}	elsif ($protocols->{$protocol}->{'assembler'} eq "allpaths")	{	# a ALLPATHS-LG protocol should have at least one overlapping PE library and one MP library
			my $overlap = 0;
			foreach my $library (@{$protocols->{$protocol}->{'library'}})	{
				if ($libraries->{$library}->{'read_type'} eq "pe" && $libraries->{$library}->{'read_length'}*2 > $libraries->{$library}->{'frag_mean'})	{
					$overlap = 1;
				}
			}
			unless ($overlap)	{
				push @err_msg, "\t\tALLPATHS-LG requires at least one overlapping PE library.\n";
			}
			unless (exists $read_type{'mp'})	{
				push @err_msg, "\t\tALLPATHS-LG requires at least one MP library.\n";
			}
		}	elsif ($protocols->{$protocol}->{'assembler'} eq "ca")	{		# a Celera Assembler protocol should have at least 20x PacBio reads for hybrid assembly, or at least 50x PacBio reads for self-correction assembly
			my $clr_depth = 0;
			foreach my $library (@{$protocols->{$protocol}->{'library'}})	{
				if ($libraries->{$library}->{'read_type'} eq "clr")	{
					$clr_depth += $libraries->{$library}->{'depth'};
				}
			}
			if (exists $read_type{'clr'})	{
				if (exists $read_type{'se'} || exists $read_type{'pe'})	{
					unless ($clr_depth >= 10)	{
						push @err_msg, "\t\tCelera Assembler requires at least 10x coverage PacBio reads for hybrid assembly.\n";
					}
				}	else	{
					unless ($clr_depth >= 50)	{
						push @err_msg, "\t\tCelera Assembler requires at least 50x coverage PacBio reads for self-correction assembly.\n";
					}
				}
			}	else	{
				push @err_msg, "\t\tCelera Assembler requires at least one PacBio library.\n";
			}
		}	elsif ($protocols->{$protocol}->{'assembler'} eq "discovar")  {		# a DISCOVAR de novo protocol should have a single PE library, and the insert size should be no greater than three times the read length (which should be at least 100bp)
			if (exists $read_type{'se'} || exists $read_type{'mp'} || exists $read_type{'clr'} || scalar keys %{$read_type{'pe'}} > 1)	{
				push @err_msg, "\t\tDiscovar de novo requires a SINGLE PE library.\n";
			}	else	{
				my @pe_lib = keys %{$read_type{'pe'}};
				unless ($libraries->{$pe_lib[0]}->{'read_length'} >= 100 && $libraries->{$pe_lib[0]}->{'read_length'}*3 >= $libraries->{$pe_lib[0]}->{'frag_mean'})	{
					push @err_msg, "\t\tDiscovar de novo requires a PE library whose insert size is substantially smaller than the read length (which should be at least 100bp).\n";
				}
			}
		}	elsif ($protocols->{$protocol}->{'assembler'} eq "soapdenovo2")	{	# a SOAPdenovo2 protocol should have at least one SE/PE library, and no PacBio library
			unless (exists $read_type{'se'} || exists $read_type{'pe'})	{
				push @err_msg, "\t\tSOAPdenovo2 requires at least one SE/PE library.\n";
			}
			if (exists $read_type{'clr'})	{
				push @err_msg, "\t\tSOAPdenovo2 is not compatible with PacBio reads.\n";
			}
		}	elsif ($protocols->{$protocol}->{'assembler'} eq "spades")	{	# a SPAdes protocol should have at least SE/PE library
			unless (exists $read_type{'se'} || exists $read_type{'pe'})	{
				push @err_msg, "\t\tSPAdes requires at least one SE/PE library.\n";
			}
		}	elsif ($protocols->{$protocol}->{'assembler'} eq "dipspades")	{	# a dipSPAdes protocol should have at least SE/PE library
			unless (exists $read_type{'se'} || exists $read_type{'pe'})	{
				push @err_msg, "\t\tdipSPAdes requires at least one SE/PE library.\n";
			}
		}	elsif ($protocols->{$protocol}->{'assembler'} eq "velvet")	{	# a Velvet protocol should have at least one SE/PE/MP library, and no PacBio library
			unless (exists $read_type{'se'} || exists $read_type{'pe'} || exists $read_type{'mp'})	{
				push @err_msg, "\t\tVelvet requires at least one SE/PE/MP library.\n";
			}
			if (exists $read_type{'clr'})	{
				push @err_msg, "\t\tVelvet is not compatible with PacBio reads.\n";
			}
		}
		
		if (@err_msg)	{
			push @{$err_msg}, "\tCompatibility issue(s) detected in the assembly protocol $protocol:\n";
			push @{$err_msg}, @err_msg;
		}
	}	

	return;
}

#############################
# set default libraries and assembly protocols
#############################
sub default_protocol	{
	my $global_opt = $_[0];

	$global_opt->{'library'} = {
		"L001" => {
			"simulator" => "pirs",
			"read_type" => "pe",
			"depth" => 50,
			"read_length" => 100,
			"frag_mean" => 180,
			"frag_sd" => 9,
			"error_rate" => 1,
			"error_profile" => undef,
			"gc" => 1,
			"gc_profile" => undef,
			"indel" => 1,
			"indel_profile" => undef,
		},
		"L002" => {
			"simulator" => "pirs",
			"read_type" => "mp",
			"depth" => 50,
			"read_length" => 100,
			"frag_mean" => 3000,
			"frag_sd" => 150,
			"error_rate" => 1,
			"error_profile" => undef,
			"gc" => 1,
			"gc_profile" => undef,
			"indel" => 1,
			"indel_profile" => undef,
		},
	};

	$global_opt->{'protocol'} = {
		"P001" => {
			"assembler" => "soapdenovo2",
			"library" => [ ("L001") ],
			"kmer" => 0,
			"option" => "–F –R –E –w –u",
		},
		"P002" => {
			"assembler" => "allpaths",
			"library" => [ ("L001", "L002") ],
			"ploidy" => 1,
		},
	};

	return;	
}

#############################
# read global options from  individual configuration files
#############################
sub read_conf_file	{
	my @conf_file = @_;

	# initialize global options
	my %global_opt = &init_global_opt();

	# list all library and assembly protocol related settings
	my %class = (
		"qc" => "library",
		"tm-trailing" => "library",
		"tm-adapter" => "library",
		"tm-minlen" => "library",
		"nc-adapter" => "library",
		"nc-minlen" => "library",
		"qk-kmer" => "library",
		"qk-minlen" => "library",
		"simulator" => "library",
		"depth" => "library",
		"read_type" => "library",
		"read_length" => "library",
		"frag_mean" => "library",
		"frag_sd" => "library",
		"error_rate" => "library",
		"error_profile" => "library",
		"gc" => "library",
		"gc_profile" => "library",
		"indel" => "library",
		"indel_profile" => "library",
		"qual_shift1" => "library",
		"qual_shift2" => "library",
		"qual_profile1" => "library",
		"qual_profile2" => "library",
		"ins_rate1" => "library",
		"ins_rate2" => "library",
		"del_rate1" => "library",
		"del_rate2" => "library",
		"ratio" => "library",
		"length_mean" => "library",
		"length_sd" => "library",
		"length_max" => "library",
		"length_min" => "library",
		"model_qc" => "library",
		"accuracy_mean" => "library",
		"accuracy_sd" => "library",
		"accuracy_max" => "library",
		"accuracy_min" => "library",
		"assembler" => "protocol",
		"library" => "protocol",
		"kmer" => "protocol",
		"multi-kmer" => "protocol",
		"option" => "protocol",
		"sensitive" => "protocol",
		"ploidy" => "protocol",
		"eukaryote" => "quast",
		"gage" => "quast",
		"gene" => "quast",
		"pirs" => "bin",
		"art" => "bin",
		"pbsim" => "bin",
		"trimmomatic" => "bin",
		"nextclip" => "bin",
		"quake" => "bin",
		"kmergenie" => "bin",
		"abyss-pe" => "bin",
		"allpaths" => "bin",
		"ca" => "bin",
		"discovar" => "bin",
		"soapdenovo2" => "bin",
		"spades" => "bin",
		"dipspades" => "bin",
		"velvetg" => "bin",
		"velveth" => "bin",
		"picard" => "bin",
		"quast" => "bin",
		"genome" => 1,
		"genome_size" => 1,
		"threads" => 1,
		"memory" => 1,
		"out_dir" => 1,
	);
	
	my @err_msg;
	# read options from individual configuration files
	foreach my $conf_file (@conf_file)	{
		open CONF, "< $conf_file" or die "Can't open the configuration file $conf_file!\n";
		while (my $line = <CONF>)	{
			chomp($line);
			if ($line !~ /^\s*[\n\#]/ && $line =~ /^\s*([\w\.]+)\s*\=\s*([^\n\#]+)/)	{
				my $opt = $1;
				my $value = $2;
				next unless ($value =~ /\S/);
				$value =~ s/^\s+|\s+$//g;
				if ($opt =~ /\./)	{
					my @opt = split /\./, $opt;
					my @opt_lc = split /\./, lc($opt);
					if (exists $class{$opt_lc[1]})	{
						if ($class{$opt_lc[1]} eq "library" || $class{$opt_lc[1]} eq "protocol")	{
							if ($opt_lc[1] eq "library")	{
								# remove potential redundancy in input libraries for each assembly protocol
								my %library = map { $_ => 1 } (split /\,/, $value);
								@{$global_opt{$class{$opt_lc[1]}}->{$opt[0]}->{$opt_lc[1]}} = sort keys %library;
							}	else	{
								# convert the name of simulator/assembler to lower case
								if ($opt_lc[1] eq "simulator" || $opt_lc[1] eq "assembler" || $opt_lc[1] eq "read_type")	{
									$value = lc($value);
								}	elsif ($opt_lc[1] eq "option")	{
									$value =~ s/^\"+|\"+$//g;
								}
								$global_opt{$class{$opt_lc[1]}}->{$opt[0]}->{$opt_lc[1]} = $value;
							}
						}	elsif ($opt_lc[0] eq $class{$opt_lc[1]})	{
							$global_opt{$opt_lc[0]}->{$opt_lc[1]} = $value;
						}	else	{
							push @err_msg, "\tThe option \"$opt\" is unknown, please verify.\n";
						}
					}	else	{
						push @err_msg, "\tThe option \"$opt\" is unknown, please verify.\n";
					}
				}	else	{
					my $opt_lc = lc($opt);
					if (exists $class{$opt_lc})	{
						$global_opt{$opt_lc} = $value;
					}	else	{
						push @err_msg, "\tThe option \"$opt\" is unknown, please verify.\n";
					}
				}
			}
		}
		close (CONF);
	}

	if (@err_msg)	{
		my $err_msgs = join "", @err_msg;
		die "ERROR(s) detected in configurations:\n$err_msgs";
	}

	return %global_opt;
}

#############################
# generate individual configuration files
#############################
sub write_conf_file	{
	my $global_opt = $_[0];

	my $cwd = getcwd();

	# generate the configuration file for libraries
	my @conf;	
	push @conf, "#############################\n# Library options\n#############################\n";			
	foreach my $library (sort keys %{$global_opt->{'library'}})	{
		push @conf, "\n# parameters for the library $library\n";
		# write simulation settings
		push @conf, $library.".read_type = ".uc($global_opt->{'library'}->{$library}->{'read_type'})."\n";
		push @conf, $library.".depth = $global_opt->{'library'}->{$library}->{'depth'}\n";
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "clr")	{
			push @conf, $library.".simulator = PBSIM\n";
			push @conf, $library.".accuracy_mean = $global_opt->{'library'}->{$library}->{'accuracy_mean'}\n";
			push @conf, $library.".accuracy_sd = $global_opt->{'library'}->{$library}->{'accuracy_sd'}\n";
			push @conf, $library.".accuracy_max = $global_opt->{'pbsim'}->{'accuracy_max'}\n";
			push @conf, $library.".accuracy_min = $global_opt->{'pbsim'}->{'accuracy_min'}\n";
			push @conf, $library.".model_qc = ".&Cwd::abs_path($global_opt->{'pbsim'}->{'model_qc'})."\n";
			push @conf, $library.".ratio = $global_opt->{'pbsim'}->{'ratio'}\n";
			push @conf, $library.".length_mean = $global_opt->{'pbsim'}->{'length_mean'}\n";
			push @conf, $library.".length_sd = $global_opt->{'pbsim'}->{'length_sd'}\n";
			push @conf, $library.".length_max = $global_opt->{'pbsim'}->{'length_max'}\n";
			push @conf, $library.".length_min = $global_opt->{'pbsim'}->{'length_min'}\n";
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "se")	{
			push @conf, $library.".simulator = ART\n";
			push @conf, $library.".read_length = $global_opt->{'library'}->{$library}->{'read_length'}\n";
			push @conf, $library.".qual_shift1 = $global_opt->{'art'}->{'qual_shift1'}\n";
			push @conf, $library.".qual_profile1 = ".(defined($global_opt->{'art'}->{'qual_profile1'}) ? $global_opt->{'art'}->{'qual_profile1'} : " ")."\n";
			push @conf, $library.".ins_rate1 = $global_opt->{'art'}->{'ins_rate1'}\n";
			push @conf, $library.".del_rate1 = $global_opt->{'art'}->{'del_rate1'}\n";
		}	elsif ($global_opt->{'library'}->{$library}->{'read_length'} > 100)	{
			push @conf, $library.".simulator = ART\n";
			push @conf, $library.".read_length = $global_opt->{'library'}->{$library}->{'read_length'}\n";
			push @conf, $library.".frag_mean = $global_opt->{'library'}->{$library}->{'frag_mean'}\n";
			push @conf, $library.".frag_sd = $global_opt->{'library'}->{$library}->{'frag_sd'}\n";
			push @conf, $library.".qual_shift1 = $global_opt->{'art'}->{'qual_shift1'}\n";
			push @conf, $library.".qual_shift2 = $global_opt->{'art'}->{'qual_shift2'}\n";
			push @conf, $library.".qual_profile1 = ".(defined($global_opt->{'art'}->{'qual_profile1'}) ? $global_opt->{'art'}->{'qual_profile1'} : " ")."\n";
			push @conf, $library.".qual_profile2 = ".(defined($global_opt->{'art'}->{'qual_profile2'}) ? $global_opt->{'art'}->{'qual_profile2'} : " ")."\n";
			push @conf, $library.".ins_rate1 = $global_opt->{'art'}->{'ins_rate1'}\n";
			push @conf, $library.".ins_rate2 = $global_opt->{'art'}->{'ins_rate2'}\n";
			push @conf, $library.".del_rate1 = $global_opt->{'art'}->{'del_rate1'}\n";
			push @conf, $library.".del_rate2 = $global_opt->{'art'}->{'del_rate2'}\n";
		}	else	{
			push @conf, $library.".simulator = pIRS\n";
			push @conf, $library.".read_length = $global_opt->{'library'}->{$library}->{'read_length'}\n";
			push @conf, $library.".frag_mean = $global_opt->{'library'}->{$library}->{'frag_mean'}\n";
			push @conf, $library.".frag_sd = $global_opt->{'library'}->{$library}->{'frag_sd'}\n";
			push @conf, $library.".error_rate = $global_opt->{'pirs'}->{'error_rate'}\n";
			push @conf, $library.".error_profile = ".(defined($global_opt->{'pirs'}->{'error_profile'}) ? $global_opt->{'pirs'}->{'error_profile'} : " ")."\n";
			push @conf, $library.".gc = $global_opt->{'pirs'}->{'gc'}\n";
			push @conf, $library.".gc_profile = ".(defined($global_opt->{'pirs'}->{'gc_profile'}) ? $global_opt->{'pirs'}->{'gc_profile'} : " ")."\n";
			push @conf, $library.".indel = $global_opt->{'pirs'}->{'indel'}\n";
			push @conf, $library.".indel_profile = ".(defined($global_opt->{'pirs'}->{'indel_profile'}) ? $global_opt->{'pirs'}->{'indel_profile'} : " ")."\n";
		}
		# write QC settings
		if (defined($global_opt->{'library'}->{$library}->{'qc'}) && $global_opt->{'library'}->{$library}->{'qc'} == 1) { push @conf, $library.".QC = $global_opt->{'library'}->{$library}->{'qc'}\n"; }
		if ($global_opt->{'library'}->{$library}->{'read_type'} eq "se" || $global_opt->{'library'}->{$library}->{'read_type'} eq "pe")	{
			if (defined($global_opt->{'library'}->{$library}->{'tm-trailing'})) { push @conf, $library.".tm-trailing = $global_opt->{'library'}->{$library}->{'tm-trailing'}\n"; }
			if (defined($global_opt->{'library'}->{$library}->{'tm-adapter'})) { push @conf, $library.".tm-adapter = $global_opt->{'library'}->{$library}->{'tm-adapter'}\n"; }
			if (defined($global_opt->{'library'}->{$library}->{'tm-minlen'})) { push @conf, $library.".tm-minlen = $global_opt->{'library'}->{$library}->{'tm-minlen'}\n"; }
			if (defined($global_opt->{'library'}->{$library}->{'qk-kmer'})) { push @conf, $library.".qk-kmer = $global_opt->{'library'}->{$library}->{'qk-kmer'}\n"; }
			if (defined($global_opt->{'library'}->{$library}->{'qk-minlen'})) { push @conf, $library.".qk-minlen = $global_opt->{'library'}->{$library}->{'qk-minlen'}\n"; }
		}	elsif ($global_opt->{'library'}->{$library}->{'read_type'} eq "mp")	{
			if (defined($global_opt->{'library'}->{$library}->{'tm-trailing'})) { push @conf, $library.".tm-trailing = $global_opt->{'library'}->{$library}->{'tm-trailing'}\n"; }
			if (defined($global_opt->{'library'}->{$library}->{'tm-minlen'})) { push @conf, $library.".tm-minlen = $global_opt->{'library'}->{$library}->{'tm-minlen'}\n"; }
			if (defined($global_opt->{'library'}->{$library}->{'nc-adapter'})) { push @conf, $library.".nc-adapter = $global_opt->{'library'}->{$library}->{'nc-adapter'}\n"; }
			if (defined($global_opt->{'library'}->{$library}->{'nc-minlen'})) { push @conf, $library.".nc-minlen = $global_opt->{'library'}->{$library}->{'nc-minlen'}\n"; }
		}
	}
	
	open LIB_CONF, "> $cwd/libraries.conf" or die "Can't write to libraries.conf!\n";
	print LIB_CONF @conf;
	close (LIB_CONF);
	
	# generate the configuration file for assembly protocols
	@conf = ();
	push @conf, "#############################\n# Assembly protocol options\n#############################\n";
	foreach my $protocol (sort keys %{$global_opt->{'protocol'}})	{
		push @conf, "\n# parameters for the assembly protocol $protocol\n";
		push @conf, $protocol.".library = ";
		$conf[-1] .= join ",", sort @{$global_opt->{'protocol'}->{$protocol}->{'library'}};
		$conf[-1] .= "\n";
		if ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "abyss")	{
			push @conf, $protocol.".assembler = ABYSS\n";
			push @conf, $protocol.".kmer = $global_opt->{'protocol'}->{$protocol}->{'kmer'}\n";
			push @conf, $protocol.".option = \"$global_opt->{'protocol'}->{$protocol}->{'option'}\"\n";
		}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "allpaths")	{
			push @conf, $protocol.".assembler = ALLPATHS\n";
			push @conf, $protocol.".ploidy = $global_opt->{'protocol'}->{$protocol}->{'ploidy'}\n";
		}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "ca")	{
			push @conf, $protocol.".assembler = CA\n";
			push @conf, $protocol.".sensitive = $global_opt->{'protocol'}->{$protocol}->{'sensitive'}\n";
		}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "discovar")	{
			push @conf, $protocol.".assembler = DISCOVAR\n";
		}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "soapdenovo2")	{
			push @conf, $protocol.".assembler = SOAPdenovo2\n";
			push @conf, $protocol.".kmer = $global_opt->{'protocol'}->{$protocol}->{'kmer'}\n";
			push @conf, $protocol.".option = \"$global_opt->{'protocol'}->{$protocol}->{'option'}\"\n";
		}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "spades")	{
			push @conf, $protocol.".assembler = SPAdes\n";
			push @conf, $protocol.".kmer = $global_opt->{'protocol'}->{$protocol}->{'kmer'}\n";
			push @conf, $protocol.".multi-kmer = $global_opt->{'protocol'}->{$protocol}->{'multi-kmer'}\n";
			push @conf, $protocol.".option = \"$global_opt->{'protocol'}->{$protocol}->{'option'}\"\n";
		}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "dipspades")	{
			push @conf, $protocol.".assembler = dipSPAdes\n";
			push @conf, $protocol.".kmer = $global_opt->{'protocol'}->{$protocol}->{'kmer'}\n";
			push @conf, $protocol.".multi-kmer = \"$global_opt->{'protocol'}->{$protocol}->{'multi-kmer'}\"\n";
			push @conf, $protocol.".option = \"$global_opt->{'protocol'}->{$protocol}->{'option'}\"\n";
		}	elsif ($global_opt->{'protocol'}->{$protocol}->{'assembler'} eq "velvet")	{
			push @conf, $protocol.".assembler = Velvet\n";
			push @conf, $protocol.".kmer = $global_opt->{'protocol'}->{$protocol}->{'kmer'}\n";
			push @conf, $protocol.".option = \"$global_opt->{'protocol'}->{$protocol}->{'option'}\"\n";
		}
	}
	
	open PROT_CONF, "> $cwd/protocols.conf" or die "Can't write to protocols.ctrl!";
	print PROT_CONF @conf;
	close (PROT_CONF);

	# generate the configuration file for miscellaneous options
	@conf = ();
	# General options
	push @conf, "#############################\n# General options\n#############################\n";
	push @conf, "genome = ".(defined($global_opt->{'genome'}) ? $global_opt->{'genome'} : " ")."\n";
	push @conf, "genome_size = ".(defined($global_opt->{'genome_size'}) ? $global_opt->{'genome_size'} : " ")."\n"; 
	push @conf, "threads = $global_opt->{'threads'}\n";
	push @conf, "memory = $global_opt->{'memory'}\n";
	push @conf, "out_dir = $global_opt->{'out_dir'}\n";
	# Evaluation options
	push @conf, "\n#############################\n# Evaluation options\n#############################\n";
	push @conf, "QUAST.eukaryote = $global_opt->{'quast'}->{'eukaryote'}\n";
	push @conf, "QUAST.gage = $global_opt->{'quast'}->{'gage'}\n";
	push @conf, "QUAST.gene = ".(defined($global_opt->{'quast'}->{'gene'}) ? $global_opt->{'quast'}->{'gene'} : " ")."\n";
	# Paths to executables
	push @conf, "\n#############################\n# Executable options\n#############################\n";
	push @conf, "bin.pIRS = ".(defined($global_opt->{'bin'}->{'pirs'}) ? $global_opt->{'bin'}->{'pirs'} : " ")."\n";
	push @conf, "bin.ART = ".(defined($global_opt->{'bin'}->{'art'}) ? $global_opt->{'bin'}->{'art'} : " ")."\n";
	push @conf, "bin.PBSIM = ".(defined($global_opt->{'bin'}->{'pbsim'}) ? $global_opt->{'bin'}->{'pbsim'} : " ")."\n";
	push @conf, "bin.Trimmomatic = ".(defined($global_opt->{'bin'}->{'trimmomatic'}) ? $global_opt->{'bin'}->{'trimmomatic'} : " ")."\n";
	push @conf, "bin.NextClip = ".(defined($global_opt->{'bin'}->{'nextclip'}) ? $global_opt->{'bin'}->{'nextclip'} : " ")."\n";
	push @conf, "bin.Quake = ".(defined($global_opt->{'bin'}->{'quake'}) ? $global_opt->{'bin'}->{'quake'} : " ")."\n";
	push @conf, "bin.KmerGenie = ".(defined($global_opt->{'bin'}->{'kmergenie'}) ? $global_opt->{'bin'}->{'kmergenie'} : " ")."\n";
	push @conf, "bin.ABYSS = ".(defined($global_opt->{'bin'}->{'abyss-pe'}) ? $global_opt->{'bin'}->{'abyss-pe'} : " ")."\n";
	push @conf, "bin.ALLPATHS = ".(defined($global_opt->{'bin'}->{'allpaths'}) ? $global_opt->{'bin'}->{'allpaths'} : " ")."\n";
	push @conf, "bin.CA = ".(defined($global_opt->{'bin'}->{'ca'}) ? $global_opt->{'bin'}->{'ca'} : " ")."\n";
	push @conf, "bin.DISCOVAR = ".(defined($global_opt->{'bin'}->{'discovar'}) ? $global_opt->{'bin'}->{'discovar'} : " ")."\n";
	push @conf, "bin.SOAPdenovo2 = ".(defined($global_opt->{'bin'}->{'soapdenovo2'}) ? $global_opt->{'bin'}->{'soapdenovo2'} : " ")."\n";
	push @conf, "bin.SPAdes = ".(defined($global_opt->{'bin'}->{'spades'}) ? $global_opt->{'bin'}->{'spades'} : " ")."\n";
	push @conf, "bin.dipSPAdes = ".(defined($global_opt->{'bin'}->{'dipspades'}) ? $global_opt->{'bin'}->{'dipspades'} : " ")."\n";
	push @conf, "bin.velvetg = ".(defined($global_opt->{'bin'}->{'velvetg'}) ? $global_opt->{'bin'}->{'velvetg'} : " ")."\n";
	push @conf, "bin.velveth = ".(defined($global_opt->{'bin'}->{'velveth'}) ? $global_opt->{'bin'}->{'velveth'} : " ")."\n";
	push @conf, "bin.Picard = ".(defined($global_opt->{'bin'}->{'picard'}) ? $global_opt->{'bin'}->{'picard'} : " ")."\n";
	push @conf, "bin.QUAST = ".(defined($global_opt->{'bin'}->{'quast'}) ? $global_opt->{'bin'}->{'quast'} : " ")."\n";

	open MISC_CONF, "> $cwd/misc.conf" or die "Can't write to misc.conf!";
	print MISC_CONF @conf;
	close (MISC_CONF);

	return;
}

1;
