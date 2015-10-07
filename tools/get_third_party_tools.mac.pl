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
#	'ALLPATHS-LG' => 3,	# ALLPATHS-LG is not supported on MacOS
	'CA' => 3,		# version 8.3rc1 is used; the pre-compiled rc2 package has a problem
#	'DISCOVAR' => 3,	# DISCOVAR is not supported on MacOS
#	'MaSuRCA' => 3,		# has to register at http://www.genome.umd.edu/masurca_compile.html to obtain the package
	'Minia' => 3,
#	'Platanus' => 3,	# official website down at this moment....
	'SGA' => 3,
	'SOAPdenovo2' => 3,
	'SPAdes' => 3,
	'Velvet' => 3,
	'KmerGenie' => 3,
	'QUAST' => 4,
#	'REAPR' => 4,		# REAPR requires VM to work on MacOS
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
	system "wget -q http://www.niehs.nih.gov/research/resources/assets/docs/artbinchocolatecherrycake031915macos64tgz.tgz";
	system "tar xf artbinchocolatecherrycake031915macos64tgz.tgz";
	system "mv art_bin_ChocolateCherryCake ART";
	print "Done!\n\n";
}

if (defined($tools{'PBSIM'}))	{
	if (-e "PBSIM")	{
		print "Compiling PBSIM (source code): version 1.0.3\n";
	}	else	{
		print "Getting PBSIM (pre-compiled): version 1.0.3\n";
		system "wget -q https://pbsim.googlecode.com/files/pbsim-1.0.3.tar.gz";
		system "tar xf pbsim-1.0.3.tar.gz";
		system "mv pbsim-1.0.3 PBSIM";
	}
	chdir("$cwd/PBSIM");
	system "./configure --prefix=$cwd/PBSIM > install.log 2>&1";
	system "make >> install.log 2>&1";
	system "make install >> install.log 2>&1";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($category{'2'}))	{
	print "\n########## Tools for reads quality control: ##########\n\n";
}

if (defined($tools{'Trimmomatic'}))	{
	print "Getting Trimmomatic (pre-compiled): version 0.33\n";
	system "wget -q http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.33.zip";
	system "unzip -q Trimmomatic-0.33.zip";
	system "mv Trimmomatic-0.33 Trimmomatic";
	system "mv Trimmomatic/trimmomatic-0.33.jar Trimmomatic/trimmomatic.jar";
	print "Done!\n\n";
}

if (defined($tools{'NextClip'}))	{
	print "Getting NextClip (source code): version 1.3.1\n";
	system "wget -q https://github.com/richardmleggett/nextclip/archive/NextClip_v1.3.1.tar.gz";
	system "tar xf NextClip_v1.3.1.tar.gz";
	system "mv nextclip-NextClip_v1.3.1 NextClip";
	chdir("$cwd/NextClip");
	print "Compiling...\n";
	system "make all MAC=1 > install.log 2>&1";
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
	# my $boost = undef;		# the path to BOOST inlude folder: e.g. /usr/include/boost
	# my $sparsehash = undef;		# the path to SPARSEHASH include folder: e.g. /usr/local/sparsehash/include
	# my $openmpi = undef;		# the path to OPENMPI
	# my $sqlite = undef;		# the path to SQLite
	# system "./configure --prefix=$cwd/ABYSS --with-boost=$boost CPPFLAGS=-I$sparsehash --with-mpi=$openmpi --enable-maxk=96 --with-sqlite=$sqlite";
	# system "make";
	# system "make install";
}

if (defined($tools{'CA'}))	{
	print "Getting Celera Assembler (pre-compiled): version 8.3rc1\n";
	system "wget -q http://downloads.sourceforge.net/project/wgs-assembler/wgs-assembler/wgs-8.3/wgs-8.3rc1-Darwin_amd64.tar.bz2";
	system "tar xf wgs-8.3rc1-Darwin_amd64.tar.bz2";
	system "mv wgs-8.3rc1 CA";
	system "ln -s CA/Darwin_amd64/bin CA/bin";
	print "Done!\n\n";
}

if (defined($tools{'Minia'}))	{
	print "Gettings Minia (pre-compiled): version 2.0.3\n";
	system "wget -q http://gatb-tools.gforge.inria.fr/versions/src/minia-2.0.3-Source.tar.gz";
	system "tar xf minia-2.0.3-Source.tar.gz";
	system "mv minia-2.0.3-Source Minia";
	mkdir("$cwd/Minia/build");
	chdir("$cwd/Minia/build");
	system "cmake -DSKIP_DOC=1 .. > install.log 2>&1";
	system "make -j 4 >> install.log 2>&1";
	mkdir("$cwd/Minia/bin");
	system "mv minia $cwd/Minia/bin";
	chdir($cwd);
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
	print "Getting SGA (source code): version 0.10.13\n";
	system "wget -q https://github.com/jts/sga/archive/v0.10.13.tar.gz";
	system "tar xf v0.10.13.tar.gz";
	system "mv sga-0.10.13 SGA";
	print "Finished downloading.\nPlease follow SGA instruction to finish the installation.\n\n";	
}

if (defined($tools{'SOAPdenovo2'}))	{
	print "Getting SOAPdenovo2 (pre-compiled): version 2.04/r240\n";
	system "wget -q http://downloads.sourceforge.net/project/soapdenovo2/SOAPdenovo2/bin/r240/SOAPdenovo2-bin-r240-mac.tgz";
	mkdir("$cwd/SOAPdenovo2");
	system "tar xf SOAPdenovo2-bin-r240-mac.tgz -C $cwd/SOAPdenovo2";
	chdir("$cwd/SOAPdenovo2");
	system "ln -s SOAPdenovo-127mer SOAPdenovo2";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($tools{'SPAdes'}))	{
	print "Getting SPAdes (pre-compiled): version 3.6.0\n";
	system "wget -q http://spades.bioinf.spbau.ru/release3.6.0/SPAdes-3.6.0-Darwin.tar.gz";
	system "tar xf SPAdes-3.6.0-Darwin.tar.gz";
	system "mv SPAdes-3.6.0-Darwin SPAdes";
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
	print "Getting QUAST (pre-compiled): version 3.1\n";
	system "wget -q http://downloads.sourceforge.net/project/quast/quast-3.1.tar.gz";
	system "tar xf quast-3.1.tar.gz";
	system "mv quast-3.1 QUAST";
	chdir("$cwd/QUAST");
	system "./install.sh > /dev/null";
	chdir($cwd);
	print "Done!\n\n";
}

if (defined($category{'5'}))	{
	print "\n########## Other dependencies: ##########\n\n";
}

if (defined($tools{'BWA'}))	{
	print "Getting BWA toolkit (source code): version 0.7.12\n";
	system "wget -q http://downloads.sourceforge.net/project/bio-bwa/bwa-0.7.12.tar.bz2";
	system "tar xf bwa-0.7.12.tar.bz2";
	unless (-d "$cwd/dependencies")	{
		mkdir("$cwd/dependencies");
	}
	chdir("$cwd/bwa-0.7.12");
	system "make > install.log 2>&1";
	system "mv bwa $cwd/dependencies";
	chdir($cwd);
	system "rm -rf bwa-0.7.12";
	print "Done!\n\n";
}

if (defined($tools{'SAMtools'}))	{
	print "Getting SAMtools (pre-compiled): version 1.2\n";
	system "wget -q https://github.com/samtools/samtools/releases/download/1.2/samtools-1.2.tar.bz2";
	system "tar xf samtools-1.2.tar.bz2";
	unless (-d "dependencies")	{
		mkdir("dependencies");
	}
	chdir("$cwd/samtools-1.2");
	system "make > install.log 2>&1";
	system "mv samtools $cwd/dependencies";
	chdir($cwd);
	system "rm -rf samtools-1.2";
	print "Done!\n\n";
}

if (defined($tools{'FASTX'}))	{
	print "Getting FASTX (pre-compiled): version 0.0.13\n";
	system "wget -q http://hannonlab.cshl.edu/fastx_toolkit/fastx_toolkit_0.0.13_binaries_MacOSX.10.5.8_i386.tar.bz2";
	system "tar xf fastx_toolkit_0.0.13_binaries_MacOSX.10.5.8_i386.tar.bz2";
	unless (-d "dependencies")	{
		mkdir("dependencies");
	}
	system "mv bin/fastx_reverse_complement dependencies";
	system "rm -rf bin";
	print "Done!\n\n";
}
	
exit;
