package Reads;

use strict;
use warnings;

use Utilities;

#############################
# Illumina reads simulation using pIRS
#############################
sub pirs	{
	(my $library, my $global_opt) = @_;

	(my $ref, my $pirs_bin, my $lib_opt, my $out_dir) = ($global_opt->{'genome'}, $global_opt->{'bin'}->{'pirs'}, $global_opt->{'library'}->{$library}, $global_opt->{'out_dir'});
	
	print "Starts the simulation of library $library:\t".localtime()."\n";	

	#set general options
	my $cmd = "$pirs_bin simulate --threads=$global_opt->{'threads'} --phred-offset=33 --eamss=quality --no-logs --read-len=$lib_opt->{'read_length'} --coverage=$lib_opt->{'depth'} --insert-len-mean=$lib_opt->{'frag_mean'} --insert-len-sd=$lib_opt->{'frag_sd'}";
	
	#set the average substitution error rate
	if ($lib_opt->{'error_rate'} != 1)	{
		$cmd .= " --subst-error-rate=$lib_opt->{'error_rate'}";
	}
	
	#set Base-calling profile
	if (defined($lib_opt->{'error_profile'})) {
		$cmd .= " --subst-error-profile=$lib_opt->{'error_profile'}";
	}
	
	#set GC content-bias profile
	if ($lib_opt->{'gc'})	{
		if (defined($lib_opt->{'gc_profile'}))	{
			$cmd .= " --gc-bias-profile=$lib_opt->{'gc_profile'}";
		}
	}	else	{
		$cmd .= " --no-gc-bias";
	}
	
	#set Indel error profile
	if ($lib_opt->{'indel'})	{
		if (defined($lib_opt->{'indel_profile'}))	{
			$cmd .= " --indel-error-profile=$lib_opt->{'indel_profile'}";
		}
	}	else	{
		$cmd .= " --no-indels";
	}
	
	#set library specific options
	if ($lib_opt->{'read_type'} eq "mp")	{
		$cmd .= " --jumping";
	}
	
	$cmd .= " --output-prefix=$library $ref";

	&Utilities::execute_cmd($cmd, "$out_dir/logs/$library.simulation.log");
	if (-s "$library\_$lib_opt->{'read_length'}\_$lib_opt->{'frag_mean'}\_1.fq" && -s "$library\_$lib_opt->{'read_length'}\_$lib_opt->{'frag_mean'}\_2.fq")	{
		system("mv $library\_$lib_opt->{'read_length'}\_$lib_opt->{'frag_mean'}\_1.fq $library\_1.fq");
		system("mv $library\_$lib_opt->{'read_length'}\_$lib_opt->{'frag_mean'}\_2.fq $library\_2.fq");
		print "The simulation of library $library is finished successfully!\n\n";
	}	else	{
		print "The simulation of library $library failed!\n\n";
	}

	return;
}

#############################
# Illumina reads simulation using ART
#############################
sub art	{
	(my $library, my $global_opt) = @_;
	
	(my $ref, my $art_bin, my $lib_opt, my $out_dir) = ($global_opt->{'genome'}, $global_opt->{'bin'}->{'art'}, $global_opt->{'library'}->{$library}, $global_opt->{'out_dir'});

	print "Starts the simulation of library $library:\t".localtime()."\n";	
	
	#set general options
	my $cmd = "$art_bin -na -i $ref -l $lib_opt->{'read_length'} -f $lib_opt->{'depth'}";
	if ($lib_opt->{'read_type'} eq "se")	{
		$cmd .= " -qs $lib_opt->{'qual_shift1'} -ir $lib_opt->{'ins_rate1'} -dr $lib_opt->{'del_rate1'}";
	}	else	{
		$cmd .= " -qs $lib_opt->{'qual_shift1'} -qs2 $lib_opt->{'qual_shift2'} -ir $lib_opt->{'ins_rate1'} -ir2 $lib_opt->{'ins_rate2'} -dr $lib_opt->{'del_rate1'} -dr2 $lib_opt->{'del_rate2'}";
	}

	#set quality profiles
	if (defined($lib_opt->{'qual_profile1'}))	{
		$cmd .= " -1 $lib_opt->{'qual_profile1'}";
	}
	if ($lib_opt->{'read_type'} ne "se" && defined($lib_opt->{'qual_profile2'}))	{
		$cmd .= " -2 $lib_opt->{'qual_profile2'}";
	}

	#set MP library indicator
	if ($lib_opt->{'read_type'} eq "mp")	{
		$cmd = " -mp";
	}
	
	#set PE/MP library specific options, do nothing for SE library
	if ($lib_opt->{'read_type'} eq "se")	{
		$cmd .= " -o $library";
	}	else	{
		$cmd .= " -m $lib_opt->{'frag_mean'} -s $lib_opt->{'frag_sd'} -o $library\_";
	}

	&Utilities::execute_cmd($cmd, "$out_dir/logs/$library.simulation.log");
	if (($lib_opt->{'read_type'} eq "se" && -s "$library.fq") || (($lib_opt->{'read_type'} eq "pe" || $lib_opt->{'read_type'} eq "mp") && -s "$library\_1.fq" && -s "$library\_2.fq"))	{
		print "The simulation of library $library is finished successfully!\n\n";
	}	else	{
		print "The simulation of library $library failed!\n\n";
	}

	return;
}

#############################
# PacBio reads simulation using PBSIM
#############################
sub pbsim	{
	(my $library, my $global_opt) = @_;

	(my $ref, my $pbsim_bin, my $lib_opt, my $out_dir) = ($global_opt->{'genome'}, $global_opt->{'bin'}->{'pbsim'}, $global_opt->{'library'}->{$library}, $global_opt->{'out_dir'});

	print "Starts the simulation of library $library\t".localtime()."\n";	
	
	mkdir("pbsim_tmp");

	#conver mean and sd of accuracy to parameters of Weibull distribution
	open PBSIM, "> pbsim_tmp/pbsim.R" or die "Can't write to pbsim_tmp/pbsim.R!\n";
	print PBSIM "mean = $lib_opt->{'accuracy_mean'}\nsd = $lib_opt->{'accuracy_sd'}\nk = (sd/mean)^(-1.086)\nc = mean/(gamma(1+1/k))\nk\nc\n";
	close (PBSIM);
	my @rout = `Rscript pbsim_tmp/pbsim.R`;
	my $shape;
	if ($rout[0] =~ /(\d+\.\d+)/)	{
		$shape = int($1+0.5)/100;
	}
	my $scale;
	if ($rout[1] =~ /(\d+\.\d+)/)	{
		$scale = int($1*100+0.5)/100;
	}
	
	#set the command for PBSIM
	my $cmd = "$pbsim_bin --data-type ".uc($lib_opt->{'read_type'})." --depth $lib_opt->{'depth'} --length-min $lib_opt->{'length_min'} --length-max $lib_opt->{'length_max'} --length-mean $lib_opt->{'length_mean'} --length-sd $lib_opt->{'length_sd'} --model_qc $lib_opt->{'model_qc'} --accuracy-min $lib_opt->{'accuracy_min'} --accuracy-max $lib_opt->{'accuracy_max'} --accuracy-mean $scale --accuracy-sd $shape --difference-ratio $lib_opt->{'ratio'} --prefix pbsim_tmp/$library $ref";

	&Utilities::execute_cmd($cmd, "$out_dir/logs/$library.simulation.log");
	system("cat pbsim_tmp/*.fastq > $library.fq");
	system("rm -rf pbsim_tmp");
	if (-s "$library.fq")	{
		print "The simulation of library $library is finished successfully!\n\n";
	}	else	{
		print "The simulation of library $library failed!\n\n";
	}

	return;
}

1;
