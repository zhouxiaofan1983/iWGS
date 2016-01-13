#!/usr/bin/perl -w
use strict;
use Cwd;

my %tools = (
#	'pIRS' => 1,
	'ART' => 1,
	'PBSIM' => 1,		# a slightly modified version provided
	'Trimmomatic' => 2,
	'NextClip' => 2,
	'Lighter' => 2,
#	'Quake' => 2,
	'ABYSS' => 3,
	'ALLPATHS-LG' => 3,
	'CA' => 3,
	'DISCOVAR' => 3,
#	'MaSuRCA' => 3,		# has to register at http://www.genome.umd.edu/masurca_compile.html to obtain the package
	'Meraculous' => 3,
	'Minia' => 3,
#	'Platanus' => 3,	# official website down at this moment....
	'SGA' => 3,
	'SOAPdenovo2' => 3,
	'SPAdes' => 3,
	'Velvet' => 3,
	'KmerGenie' => 3,
	'QUAST' => 4,
	'REAPR' => 4,
	'BWA' => 5,		# required for SGA scaffolding
	'SAMtools' => 5,	# required for SGA scaffolding
	'FASTX' => 5,		# required for Velvet
);

my $cwd = getcwd;

my %category = reverse %tools;

if (defined($category{'1'}))	{
	print "\n########## Tools for reads simulation: ##########\n\n";
}

if (defined($tools{'pIRS'}))	{
	print "Getting pIRS (source code): version 2.0.1\n";
	system "wget -q https://github.com/galaxy001/pirs/archive/v2.0.1.tar.gz";
	system "tar xf v2.0.1.tar.gz";
	system "mv pirs-2.0.1 pIRS";
	print "Finished downloading.\nPlease follow pIRS instructions to finish the installation.\n\n";
}

if (defined($tools{'ART'}))	{
	print "Getting ART (pre-compiled): version 03.19.15\n";
	system "wget -q http://www.niehs.nih.gov/research/resources/assets/docs/artbinchocolatecherrycake031915linux64tgz.tgz";
	system "tar xf artbinchocolatecherrycake031915linux64tgz.tgz";
	system "mv art_bin_ChocolateCherryCake ART";
	print "Done!\n\n";
}

if (defined($tools{'PBSIM'}))	{
	if (-e "PBSIM")	{
		print "Compiling PBSIM (source code): version 1.0.3\n";
		chdir("$cwd/PBSIM");
		system "./configure --prefix=$cwd/PBSIM";
		system "make > install.log 2>&1";
		system "make install >> install.log 2>&1";
		chdir($cwd);
		print "Done!\n\n";
	}	else	{
		print "Getting PBSIM (pre-compiled): version 1.0.3\n";
		system "wget -q https://pbsim.googlecode.com/files/pbsim-1.0.3-Linux-amd64.tar.gz";
		system "tar xf pbsim-1.0.3-Linux-amd64.tar.gz";
		system "mv pbsim-1.0.3-Linux-amd64 PBSIM";
		system "ln -s PBSIM/Linux-amd64/bin PBSIM/bin";
		print "Done!\n\n";
	}
}

if (defined($category{'2'}))	{
	print "\n########## Tools for reads quality control: ##########\n\n";
}

if (defined($tools{'Trimmomatic'}))	{
	print "Getting Trimmomatic (pre-compiled): version 0.35\n";
	system "wget -q http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.35.zip";
	system "unzip -q Trimmomatic-0.35.zip";
	system "mv Trimmomatic-0.35 Trimmomatic";
	system "ln -s Trimmomatic/trimmomatic-0.35.jar Trimmomatic/trimmomatic.jar";
	print "Done!\n\n";
}

if (defined($tools{'NextClip'}))	{
	print "Getting NextClip (source code): version 1.3.1\n";
	system "wget -q https://github.com/richardmleggett/nextclip/archive/NextClip_v1.3.1.tar.gz";
	system "tar xf NextClip_v1.3.1.tar.gz";
	system "mv nextclip-NextClip_v1.3.1 NextClip";
	chdir("$cwd/NextClip");
	print "Compiling...\n";
	system "make all > install.log 2>&1";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($tools{'Lighter'}))	{
	print "Getting Lighter (source code): version 1.0.7\n";
	system "wget -q https://github.com/mourisl/Lighter/archive/v1.0.7.tar.gz";
	system "tar xf v1.0.7.tar.gz";
	system "mv Lighter-1.0.7 Lighter";
	chdir("$cwd/Lighter");
	print "Compiling...\n";
	system "make > install.log 2>&1";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($tools{'Quake'}))	{
	print "Getting Quake (source code): version 0.3.5\n";
	system "wget -q http://www.cbcb.umd.edu/software/quake/downloads/quake-0.3.5.tar.gz";
	system "tar xf quake-0.3.5.tar.gz";
	system "mv quake-0.3.5 Quake";
	print "Finished downloading.\nPlease follow Quake instruction to finish the installation.\n\n";
}

if (defined($category{'3'}))	{
	print "\n########## Tools for de novo assembly: ##########\n\n";
}

if (defined($tools{'ABYSS'}))	{
	print "Getting ABYSS (source code): version 1.9.0\n";
	system "wget -q https://github.com/bcgsc/abyss/releases/download/1.9.0/abyss-1.9.0.tar.gz";
	system "tar xf abyss-1.9.0.tar.gz";
	system "mv abyss-1.9.0 ABYSS";
	print "Finished downloading.\nPlease follow ABYSS instructions to finish the installation.\n\n";
	# uncomment and finish the following lines to install ABYSS if BOOST, sparsehash, openmpi, and sqlite are installed
	# chdir("$cwd/ABYSS");
	# my $boost = undef;		# the path to BOOST inlude folder: e.g. /usr/include/boost
	# my $sparsehash = undef;		# the path to SPARSEHASH include folder: e.g. /usr/local/sparsehash/include
	# my $openmpi = undef;		# the path to OPENMPI
	# my $sqlite = undef;		# the path to SQLite
	# system "./configure --prefix=$cwd/ABYSS --with-boost=$boost CPPFLAGS=-I$sparsehash --with-mpi=$openmpi --enable-maxk=96 --with-sqlite=$sqlite";
	# system "make";
	# system "make install";
	# chdir($cwd);
}

if (defined($tools{'ALLPATHS-LG'}))	{
	print "Getting ALLPATHS-LG (source code): version 52488\n";
	system "wget -q ftp://ftp.broadinstitute.org/pub/crd/ALLPATHS/Release-LG/latest_source_code/allpathslg-52488.tar.gz";
	system "tar xf allpathslg-52488.tar.gz";
	system "mv allpathslg-52488 ALLPATHS-LG";
	print "Finished downloading.\nPlease follow ALLPAHTS-LG instructions to finish the installation.\n\n";
	# uncomment the following lines to install ALLPATHS-LG if the GCC version is 4.7.0 or above, and BOOST is installed
	# chdir("$cwd/ALLPATHS-LG");
	# system "./configure --prefix=$cwd/ALLPATHS-LG";
	# system "make";
	# system "make install";
	# chdir($cwd);
}

if (defined($tools{'CA'}))	{
	print "Getting Celera Assembler (pre-compiled): version 8.3rc2\n";
	system "wget -q http://downloads.sourceforge.net/project/wgs-assembler/wgs-assembler/wgs-8.3/wgs-8.3rc2-Linux_amd64.tar.bz2";
	system "tar xf wgs-8.3rc2-Linux_amd64.tar.bz2";
	system "mv wgs-8.3rc2 CA";
	system "ln -s CA/Linux_amd64/bin CA/bin";
	print "Done!\n\n";
}

if (defined($tools{'DISCOVAR'}))	{
	print "Getting DISCOVAR de novo (source code): version 52488\n";
	system "wget -q ftp://ftp.broadinstitute.org/pub/crd/DiscovarDeNovo/latest_source_code/discovardenovo-52488.tar.gz";
	system "tar xf discovardenovo-52488.tar.gz";
	system "mv discovardenovo-52488 DISCOVAR";
	print "Finished downloading.\nPlease follow DISCOVAR de novo instructions to finish the installation.\n\n";
	# uncomment and finish the following lines to install DISCOVAR de novo if the GCC version is 4.7.0 or above, and jemalloc (version 3.6.0 or above) is installed
	# my $jemalloc = ; # path to jemalloc lib folder: e.g. /usr/local/jemalloc/lib";
	# chdir("$cwd/DISCOVER");
	# system "./configure --prefix=$cwd/DISCOVAR --with-jemalloc=$jemalloc";
	# system "make";
	# system "make install";
	# chdir($cwd);
}

if (defined($tools{'Meraculous'}))	{
	print "Getting Meraculous (source code): version 2.0.5\n";
	system "wget -q http://downloads.sourceforge.net/project/meraculous20/release-2.0.5.tgz";
	system "tar xvf release-2.0.5.tgz";
	system "mv release-2.0.5 Meraculous";
	print "Finished downloading.\nPlease follow Meraculous instructions to finish the installation.\n\n";
	# uncomment and finish the following lines to install Meraculous if the GCC version is 4.4.7 or above, and Boost (version 1.50.0 or above) is installed
	# chdir("$cwd/Meraculous");
	# system "sh install.sh $cwd/Meraculous";
	# chdir($cwd);
}

if (defined($tools{'Minia'}))	{
	print "Gettings Minia (pre-compiled): version 2.0.3\n";
	system "wget -q http://gatb-tools.gforge.inria.fr/versions/bin/minia-2.0.3-Linux.tar.gz";
	system "tar xf minia-2.0.3-Linux.tar.gz";
	system "mv minia-2.0.3-Linux Minia";
	print "Done!\n\n";
}

=item
# will activate this when the official link become available
if (defined($tools{'Platanus'}))	{
	print "Gettings Platanus (pre-compiled): version 1.2.1\n";
	system "wget -q ";
	system "tar xf ";
	system "mv ";
	print "Done!\n\n";
}
=cut

if (defined($tools{'SGA'}))	{
	print "Getting SGA (source code): version 0.10.14\n";
	system "wget -q https://github.com/jts/sga/archive/v0.10.14.tar.gz";
	system "tar xf v0.10.14.tar.gz";
	system "mv sga-0.10.14 SGA";
	print "Finished downloading.\nPlease follow SGA instruction to finish the installation.\n\n";	
}

if (defined($tools{'SOAPdenovo2'}))	{
	print "Getting SOAPdenovo2 (pre-compiled): version 2.04/r240\n";
	system "wget -q http://downloads.sourceforge.net/project/soapdenovo2/SOAPdenovo2/bin/r240/SOAPdenovo2-bin-LINUX-generic-r240.tgz";
	system "tar xf SOAPdenovo2-bin-LINUX-generic-r240.tgz";
	system "mv SOAPdenovo2-bin-LINUX-generic-r240 SOAPdenovo2";
	chdir("$cwd/SOAPdenovo2");
	system "ln -s SOAPdenovo-127mer SOAPdenovo2";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($tools{'SPAdes'}))	{
	print "Getting SPAdes (pre-compiled): version 3.6.2\n";
	system "wget -q http://spades.bioinf.spbau.ru/release3.6.2/SPAdes-3.6.2-Linux.tar.gz";
	system "tar xf SPAdes-3.6.2-Linux.tar.gz";
	system "mv SPAdes-3.6.2-Linux SPAdes";
	print "Done!\n\n";
}

if (defined($tools{'Velvet'}))	{
	print "Getting Velvet (source code): version 1.2.10\n";
	system "wget -q http://www.ebi.ac.uk/~zerbino/velvet/velvet_1.2.10.tgz";
	system "tar xf velvet_1.2.10.tgz";
	system "mv velvet_1.2.10 Velvet";
	chdir("$cwd/Velvet");
	print "Compiling...\n";
	system "make \'CATEGORIES=8\' \'MAXKMERLENGTH\'=96 \'OPENMP\'=1 > install.log 2>&1";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($tools{'KmerGenie'}))	{
	print "Getting KmerGenie (source code): version 1.6982\n";
	system "wget -q http://kmergenie.bx.psu.edu/kmergenie-1.6982.tar.gz";
	system "tar xf kmergenie-1.6982.tar.gz";
	system "mv kmergenie-1.6982 KmerGenie";
	chdir("$cwd/KmerGenie");
	print "Compiling...\n";
	system "make > install.log 2>&1";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($category{'4'}))	{
	print "\n########## Tools for assembly evaluation: ##########\n\n";
}

if (defined($tools{'QUAST'}))	{
	print "Getting QUAST (pre-compiled): version 3.2\n";
	system "wget -q http://downloads.sourceforge.net/project/quast/quast-3.2.tar.gz";
	system "tar xf quast-3.2.tar.gz";
	system "mv quast-3.2 QUAST";
	chdir("$cwd/QUAST");
	system "./install.sh > /dev/null";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($tools{'REAPR'}))	{
	print "Getting REAPR (source code): version 1.0.18\n";
	system "wget -q ftp://ftp.sanger.ac.uk/pub/resources/software/reapr/Reapr_1.0.18.tar.gz";
	system "tar xf Reapr_1.0.18.tar.gz";
	system "mv Reapr_1.0.18 REAPR";
	chdir("$cwd/REAPR");
	system "./install.sh > install.log 2>&1";
	my $success = 0;
	open IN, "< install.log" or die "Can't open install.log!\n";
	while (<IN>)	{
		if (/^All done\!/)	{
			$success = 1;
			last;
		}
	}
	close (IN);
	chdir($cwd);
	if ($success)	{
		print "Done!\n\n";
	}	else	{
		print "Compilation failed.\nPlease check \"install.log\" for more information.\n\n";
	}
}

if (defined($category{'5'}))	{
	print "\n########## Other dependencies: ##########\n\n";
}

if (defined($tools{'BWA'}) || defined($tools{'SAMtools'}))	{
	print "Getting BWA toolkit (pre-compiled): BWA version 0.7.12, SAMtools version 1.1\n";
	system "wget -q http://downloads.sourceforge.net/project/bio-bwa/bwakit/bwakit-0.7.12_x64-linux.tar.bz2";
	system "tar xf bwakit-0.7.12_x64-linux.tar.bz2";
	unless (-d "dependencies")	{
		mkdir("dependencies");
	}
	system "mv bwa.kit/bwa bwa.kit/samtools dependencies";
	system "rm -rf bwa.kit";
	print "Done!\n\n";
}

if (defined($tools{'FASTX'}))	{
	print "Getting FASTX-toolkit (pre-compiled): version 0.0.13\n";	
	system "wget -q http://hannonlab.cshl.edu/fastx_toolkit/fastx_toolkit_0.0.13_binaries_Linux_2.6_amd64.tar.bz2";
	system "tar xf fastx_toolkit_0.0.13_binaries_Linux_2.6_amd64.tar.bz2";
	unless (-d "dependencies")	{
		mkdir("dependencies");
	}
	system "mv bin/fastx_reverse_complement dependencies";
	system "rm -rf bin";
	print "Done!\n\n";
}

exit;
