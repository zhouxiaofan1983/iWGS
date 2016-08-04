#!/usr/bin/perl -w
use strict;
use Cwd;
use File::Which;

# comment or comment out the lines below to customize the tools to download/install
my %tools = (
    #	'pIRS' => 1,        # likely requires manual configuration to install
    'ART'         => 1,
    'PBSIM'       => 1,     # a slightly modified version provided
    'Trimmomatic' => 2,
    'NextClip'    => 2,
    'Lighter'     => 2,
    #	'Quake' => 2,
    #	'ABYSS' => 3,       # likely requires manual configuration to install
    #	'ALLPATHS-LG' => 3, # ALLPATHS-LG is not supported on MacOS
    'CA'      => 3,	    # version 8.3rc1 is used; the pre-compiled rc2 package has a problem
    'Canu'    => 3,
    #   'DBG2OLC' => 3,     # DBG2OLC requires blasr, which is not supported on MacOS
    #	'DISCOVAR' => 3,    # DISCOVAR is not supported on MacOS
    #   'Falcon' => 3,      # likely requires manual configuration to install
    #	'MaSuRCA' => 3,	    # has to register at http://www.genome.umd.edu/masurca_compile.html to obtain the package
    #   'Metassembler' => 3, # Metassembler does not install correctly on MacOS	
    #   'Meraculous'   => 3, # Meraculous is not supported on MacOS
    'Minia'        => 3,
    # 'Platanus'     => 3,  # unstable download link
    #	'SGA' => 3,         # likely requires manual configuration to install
    'SOAPdenovo2' => 3,
    'SPAdes'      => 3,
    'Velvet'      => 3,
    'KmerGenie'   => 3,
    'QUAST'       => 4,
    #   'REAPR'       => 4, # REAPR requires VM to work on MacOS
    #	'BWA' => 5,         # required for SGA scaffolding
    #	'SAMtools' => 5,    # required for SGA scaffolding
    'FASTX' => 5,           # required for Velvet
);

my $cwd = getcwd;

my %category = reverse %tools;

if ( defined( $category{'1'} ) ) {
    print "\n########## Tools for reads simulation: ##########\n\n";
}

if ( defined( $tools{'pIRS'} ) ) {
    my $path = ( -e "pIRS/pirs" ) ? "pIRS/pirs" : File::Which::which("pirs");
    if ( defined($path) ) {
        print "pIRS is already installed!\n\n";
    } else {
        if ( -d "pIRS" ) { system "rm -rf pIRS"; }
        print "Getting pIRS (source code): version 2.0.1\n";
        unless ( -e "pirs-2.0.1.tar.gz" ) { system "wget -q https://github.com/galaxy001/pirs/archive/v2.0.1.tar.gz -O pirs-2.0.1.tar.gz"; }
        system "tar xf pirs-2.0.1.tar.gz";
        system "mv pirs-2.0.1 pIRS";
        print "Finished downloading.\nPlease follow pIRS instructions to finish the installation.\n\n";
    }
}

if ( defined( $tools{'ART'} ) ) {
    my $path = ( -e "ART/art_illumina" ) ? "ART/art_illumina" : File::Which::which("art_illumina");
    if ( defined($path) ) {
        print "ART is already installed!\n\n";
    } else {
        if ( -d "ART" ) { system "rm -rf ART "; }
        print "Getting ART (pre-compiled): version 06.05.16\n";
        unless ( -e "artbinmountrainier20160605macos64tgz.tgz" ) { system "wget -q http://www.niehs.nih.gov/research/resources/assets/docs/artbinmountrainier20160605macos64tgz.tgz"; }
        system "tar xf artbinmountrainier20160605macos64tgz.tgz";
        system "mv art_bin_MountRainier ART";
        print "Done!\n\n";
    }
}

if ( defined( $tools{'PBSIM'} ) ) {
    my $path = ( -e "PBSIM/bin/pbsim" ) ? "PBSIM/bin/pbsim" : File::Which::which("pbsim");
    if ( defined($path) ) {
        print "PBSIM is already installed!\n\n";
    } else {
        if ( -d "PBSIM" ) {
            print "Compiling PBSIM (source code): version 1.0.3\n";
        } else {
            print "Getting PBSIM (source code): version 1.0.3\n";
	        unless (-e "pbsim-1.0.3.tar.gz") { system "wget -q https://pbsim.googlecode.com/files/pbsim-1.0.3.tar.gz"; }
            system "tar xf pbsim-1.0.3.tar.gz";
	        system "mv pbsim-1.0.3 PBSIM";
	        system "wget -q https://raw.githubusercontent.com/zhouxiaofan1983/iWGS/master/tools/PBSIM/data/model_qc_clr.alyrata -O $cwd/PBSIM/data/model_qc_clr.alyrata";
        }
	chdir("$cwd/PBSIM");
        print "Compiling...\n";
        system "./configure --prefix=$cwd/PBSIM > install.log 2>&1";
        system "make >> install.log 2>&1";
        system "make install >> install.log 2>&1";
        chdir($cwd);
        print "Done!\n\n";
    }
}

if ( defined( $category{'2'} ) ) {
    print "\n########## Tools for reads quality control: ##########\n\n";
}

if ( defined( $tools{'Trimmomatic'} ) ) {
    my $path = ( -e "Trimmomatic/trimmomatic.jar" ) ? "Trimmomatic/trimmomatic.jar" : File::Which::which("trimmomatic.jar");
    if ( defined($path) ) {
        print "Trimmomatic is already installed!\n\n";
    } else {
        if ( -d "Trimmomatic" ) { system "rm -rf Trimmomatic"; }
        print "Getting Trimmomatic (pre-compiled): version 0.36\n";
        unless ( -e "Trimmomatic-0.36.zip" ) { system "wget -q http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.36.zip"; }
        system "unzip -q Trimmomatic-0.36.zip";
        system "mv Trimmomatic-0.36 Trimmomatic";
        system "ln -s $cwd/Trimmomatic/trimmomatic-0.36.jar $cwd/Trimmomatic/trimmomatic.jar";
        print "Done!\n\n";
    }
}

if ( defined( $tools{'NextClip'} ) ) {
    my $path = ( -e "NextClip/bin/nextclip" ) ? "NextClip/bin/nextclip" : File::Which::which("nextclip");
    if ( defined($path) ) {
        print "NextClip is already installed!\n\n";
    } else {
        if ( -d "NextClip" ) { system "rm -rf NextClip"; }
        print "Getting NextClip (source code): version 1.3.1\n";
        unless ( -e "NextClip_v1.3.1.tar.gz" ) { system "wget -q https://github.com/richardmleggett/nextclip/archive/NextClip_v1.3.1.tar.gz"; }
        system "tar xf NextClip_v1.3.1.tar.gz";
        system "mv nextclip-NextClip_v1.3.1 NextClip";
        chdir("$cwd/NextClip");
        print "Compiling...\n";
        system "make all MAC=1 > install.log 2>&1";
        chdir($cwd);
        print "Done!\n\n";
    }
}

if ( defined( $tools{'Lighter'} ) ) {
    my $path = ( -e "Lighter/lighter" ) ? "Lighter/lighter" : File::Which::which("lighter");
    if ( defined($path) ) {
        print "Lighter is already installed!\n\n";
    } else {
        if ( -d "Lighter" ) { system "rm -rf Lighter"; }
        print "Getting Lighter (source code): version 1.1.1\n";
        unless ( -e "Lighter-1.1.1.tar.gz" ) { system "wget -q https://github.com/mourisl/Lighter/archive/v1.1.1.tar.gz -O Lighter-1.1.1.tar.gz"; }
        system "tar xf Lighter-1.1.1.tar.gz";
        system "mv Lighter-1.1.1 Lighter";
        chdir("$cwd/Lighter");
        print "Compiling...\n";
        system "make > install.log 2>&1";
        chdir($cwd);
        print "Done!\n\n";
    }
}

if ( defined( $tools{'Quake'} ) ) {
    my $path = ( -e "Quake/bin/quake.py" ) ? "Quake/bin/quake.py" : File::Which::which("quake.py");
    if ( defined($path) ) {
        print "Quake is already installed!\n\n";
    } else {
        if ( -d "Quake" ) { system "rm -rf Quake"; }
        print "Getting Quake (source code): version 0.3.5\n";
        unless ( -e "quake-0.3.5.tar.gz" ) { system "wget -q http://www.cbcb.umd.edu/software/quake/downloads/quake-0.3.5.tar.gz"; }
        system "tar xf quake-0.3.5.tar.gz";
        print "Finished downloading.\nPlease follow Quake instruction to finish the installation.\n\n";
    }
}

if ( defined( $category{'3'} ) ) {
    print "\n########## Tools for de novo assembly: ##########\n\n";
}

if ( defined( $tools{'ABYSS'} ) ) {
    my $path = ( -e "ABYSS/bin/abyss-pe" ) ? "ABYSS/bin/abyss-pe" : File::Which::which("abyss-pe");
    if ( defined($path) ) {
        print "ABYSS is already installed!\n\n";
    } else {
        if ( -d "ABYSS" ) { system "rm -rf ABYSS"; }
        print "Getting ABYSS (source code): version 1.9.0\n";
        unless ( -e "abyss-1.9.0.tar.gz" ) { system "wget -q https://github.com/bcgsc/abyss/releases/download/1.9.0/abyss-1.9.0.tar.gz"; }
        system "tar xf abyss-1.9.0.tar.gz";
        system "mv abyss-1.9.0 ABYSS";
        print "Finished downloading.\nPlease follow ABYSS instructions to finish the installation.\n\n";

        # uncomment and finish the following lines to install ABYSS if BOOST, sparsehash, openmpi, and sqlite are installed
        # chdir("$cwd/ABYSS");
        # my $boost = undef;		# the path to BOOST inlude folder: e.g. /usr/include/boost
        # my $sparsehash = undef;	# the path to SPARSEHASH include folder: e.g. /usr/local/sparsehash/include
        # my $openmpi = undef;		# the path to OPENMPI
        # my $sqlite = undef;		# the path to SQLite
        # system "./configure --prefix=$cwd/ABYSS --with-boost=$boost CPPFLAGS=-I$sparsehash --with-mpi=$openmpi --enable-maxk=96 --with-sqlite=$sqlite";
        # system "make";
        # system "make install";
        # chdir($cwd);
    }
}

if ( defined( $tools{'CA'} ) ) {
    my $path = ( -e "CA/bin/runCA" ) ? "CA/bin/runCA" : File::Which::which("runCA");
    if ( defined($path) ) {
        print "Celera Assembler is already installed!\n\n";
    } else {
        if ( -d "CA" ) { system "rm -rf CA"; }
        print "Getting Celera Assembler (pre-compiled): version 8.3rc2\n";
        unless ( -e "wgs-8.3rc2-Darwin_amd64.tar.bz2" ) { system "wget -q http://downloads.sourceforge.net/project/wgs-assembler/wgs-assembler/wgs-8.3/wgs-8.3rc2-Darwin_amd64.tar.bz2"; }
        system "tar xf wgs-8.3rc2-Darwin_amd64.tar.bz2";
        system "mv wgs-8.3rc2 CA";
        system "ln -s $cwd/CA/Darwin-amd64/bin $cwd/CA/bin";
        print "Done!\n\n";
    }
}

if ( defined( $tools{'Canu'} ) ) {
    my $path = ( -e "Canu/bin/canu" ) ? "Canu/bin/canu" : File::Which::which("canu");
    if ( defined($path) ) {
        print "Canu is already installed!\n\n";
    } else {
        if ( -d "Canu" ) { system "rm -rf Canu"; }
        print "Getting Canu (pre-compiled): version 1.3\n";
        unless ( -e "canu-1.3.Darwin-amd64.tar.bz2" ) { system "wget -q https://github.com/marbl/canu/releases/download/v1.3/canu-1.3.Darwin-amd64.tar.bz2"; }
        system "tar xf canu-1.3.Darwin-amd64.tar.bz2";
        system "mv canu-1.3 Canu";
        system "ln -s $cwd/Canu/Darwin-amd64/bin $cwd/Canu/bin";
        print "Done!\n\n";
    }
}

if ( defined( $tools{'FALCON'} ) ) {
    my $path = ( -e "FALCON/fc_env/bin/fc_run.py" ) ? "FALCON/fc_env/bin/fc_run.py" : File::Which::which("FALCON/fc_env/bin/fc_run.py");
    if ( defined($path) ) {
        print "FALCON is already installed!\n\n";
    } else {
        if ( -d "FALCON" ) { system "rm -rf FALCON"; }
        print "Getting FALCON (source code): version up-to-date\n";
        system "git clone -q git://github.com/PacificBiosciences/FALCON-integrate.git FALCON";
        print "Finished downloading.\nPlease follow FALCON instructions to finish the installation.\n\n";

        # uncomment and finish the following lines to install FALCON
        # chdir($cwd/FALCON);
        # system "git checkout master";
        # system "make init";
        # system "source env.sh";
        # system "make config-edit-user";
        # system "make -j all";
        # chdir($cwd);
    }
}

if ( defined( $tools{'Minia'} ) ) {
    my $path = ( -e "Minia/bin/minia" ) ? "Minia/bin/minia" : File::Which::which("minia");
    if ( defined($path) ) {
        print "Minia is already installed!\n\n";
    } else {
        if ( -d "Minia" ) { system "rm -rf Minia"; }
        print "Gettings Minia (source code): version 2.0.3\n";
        system "wget -q http://gatb-tools.gforge.inria.fr/versions/src/minia-2.0.3-Source.tar.gz";
	system "tar xf minia-2.0.3-Source.tar.gz";
	system "mv minia-2.0.3-Source Minia";
	mkdir("$cwd/Minia/build");
	chdir("$cwd/Minia/build");
        print "Compiling...\n";
	system "cmake -DSKIP_DOC=1 .. > install.log 2>&1";
	system "make -j 4 >> install.log 2>&1";
	mkdir("$cwd/Minia/bin");
	system "mv minia $cwd/Minia/bin";
	chdir($cwd);
	print "Done!\n\n";
    }
}

if ( defined( $tools{'Platanus'} ) ) {
    my $path = ( -e "Platanus/platanus" ) ? "Platanus/platanus" : File::Which::which("platanus");
    if ( defined($path) ) {
        print "Platanus is already installed!\n\n";
    } else {
        if ( -d "Platanus" ) { system "rm -rf Platanus"; }
        print "Gettings Platanus (source code): version 1.2.4\n";
	system "wget -q http://platanus.bio.titech.ac.jp/?ddownload=150 -O platanus.tar.gz";
        system "tar xf platanus.tar.gz";
	system "mv Platanus_v1.2.4 Platanus";
	chdir("$cwd/Platanus");
        print "Compiling...\n";
	system "make";
	chdir($cwd);
        print "Done!\n\n";
    }
}

if ( defined( $tools{'SGA'} ) ) {
    my $path = ( -e "SGA/bin/sga" ) ? "SGA/bin/sga" : File::Which::which("sga");
    if ( defined($path) ) {
        print "SGA is already installed!\n\n";
    } else {
        if ( -d "SGA" ) { system "rm -rf SGA"; }
        print "Getting SGA (source code): version 0.10.14\n";
        unless ( -e "sga-0.10.14.tar.gz" ) { system "wget -q https://github.com/jts/sga/archive/v0.10.14.tar.gz -O sga-0.10.14.tar.gz"; }
        system "tar xf sga-0.10.14.tar.gz";
        system "mv sga-0.10.14 SGA";
        print "Finished downloading.\nPlease follow SGA instruction to finish the installation.\n\n";
    }
}

if ( defined( $tools{'SOAPdenovo2'} ) ) {
    my $path = ( -e "SOAPdenovo2/SOAPdenovo2" ) ? "SOAPdenovo2/SOAPdenovo2" : File::Which::which("SOAPdenovo2");
    if ( defined($path) ) {
        print "SOAPdenovo2 is already installed!\n\n";
    } else {
        if ( -d "SOAPdenovo2" ) { system "rm -rf SOAPdenovo2"; }
        print "Getting SOAPdenovo2 (pre-compiled): version 2.04/r240\n";
        unless ( -e "SOAPdenovo2-bin-r240-mac.tgz" ) { system "wget -q http://downloads.sourceforge.net/project/soapdenovo2/SOAPdenovo2/bin/r240/SOAPdenovo2-bin-r240-mac.tgz"; } 
	unless (-d "SOAPdenovo2") { mkdir("SOAPdenovo2") }
        system "tar xf SOAPdenovo2-bin-r240-mac.tgz";
	system "mv SOAPdenovo-63mer SOAPdenovo-127mer $cwd/SOAPdenovo2";
        system "ln -s $cwd/SOAPdenovo2/SOAPdenovo-127mer $cwd/SOAPdenovo2/SOAPdenovo2";
        print "Done!\n\n";
    }
}

if ( defined( $tools{'SPAdes'} ) ) {
    my $path = ( -e "SPAdes/bin/spades.py" ) ? "SPAdes/bin/spades.py" : File::Which::which("spades.py");
    if ( defined($path) ) {
        print "SPAdes is already installed!\n\n";
    } else {
        if ( -d "SPAdes" ) { system "rm -rf SPAdes"; }
        print "Getting SPAdes (pre-compiled): version 3.9\n";
        unless ( -e "SPAdes-3.9.0-Darwin.tar.gz" ) { system "wget -q http://spades.bioinf.spbau.ru/release3.9.0/SPAdes-3.9.0-Darwin.tar.gz"; } 
        system "tar xf SPAdes-3.9.0-Darwin.tar.gz";
        system "mv SPAdes-3.9.0-Darwin SPAdes";
        print "Done!\n\n";
    }
}

if ( defined( $tools{'Velvet'} ) ) {
    my $path = ( -e "Velvet/velvetg" ) ? "Velvet/velvetg" : File::Which::which("velvetg");
    if ( defined($path) ) {
        print "Velvet is already installed!\n\n";
    } else {
        if ( -d "Velvet" ) { system "rm -rf Velvet"; }
        print "Getting Velvet (source code): version 1.2.10\n";
        unless ( -e "velvet_1.2.10.tgz" ) { system "wget -q http://www.ebi.ac.uk/~zerbino/velvet/velvet_1.2.10.tgz"; }
        system "tar xf velvet_1.2.10.tgz";
        system "mv velvet_1.2.10 Velvet";
        chdir("$cwd/Velvet");
        print "Compiling...\n";
        system "make \'CATEGORIES=8\' \'MAXKMERLENGTH\'=96 \'OPENMP\'=1 > install.log 2>&1";
        chdir($cwd);
        print "Done!\n\n";
    }
}

if ( defined( $tools{'KmerGenie'} ) ) {
    my $path = ( -e "KmerGenie/kmergenie" ) ? "KmerGenie/kmergenie" : File::Which::which("kmergenie");
    if ( defined($path) ) {
        print "KmerGenie is already installed!\n\n";
    } else {
        if ( -d "KmerGenie" ) { system "rm -rf KmerGenie"; }
        print "Getting KmerGenie (source code): version 1.7016\n";
        unless ( -e "kmergenie-1.7016.tar.gz" ) { system "wget -q http://kmergenie.bx.psu.edu/kmergenie-1.7016.tar.gz"; }
        system "tar xf kmergenie-1.7016.tar.gz";
        system "mv kmergenie-1.7016 KmerGenie";
        chdir("$cwd/KmerGenie");
        print "Compiling...\n";
        system "make > install.log 2>&1";
        chdir($cwd);
        print "Done!\n\n";
    }
}

if ( defined( $category{'4'} ) ) {
    print "\n########## Tools for assembly evaluation: ##########\n\n";
}

if ( defined( $tools{'QUAST'} ) ) {
    my $path = ( -e "QUAST/quast.py" ) ? "QUAST/quast.py" : File::Which::which("quast.py");
    if ( defined($path) ) {
        print "QUAST is already installed!\n\n";
    } else {
        if ( -d "QUAST" ) { system "rm -rf QUAST"; }
        print "Getting QUAST (pre-compiled): version 4.2\n";
        unless ( -e "quast-4.2.tar.gz" ) { system "wget -q https://downloads.sourceforge.net/project/quast/quast-4.2.tar.gz"; }
        system "tar xf quast-4.2.tar.gz";
        system "mv quast-4.2 QUAST";
        chdir("$cwd/QUAST");
        system "./install.sh > /dev/null";
        chdir($cwd);
        print "Done!\n\n";
    }
}

if ( defined( $category{'5'} ) ) {
    print "\n########## Other dependencies: ##########\n\n";
}

if ( defined( $tools{'BWA'} ) ) {
    my $path = ( -e "dependencies/bwa" ) ? "dependencies/bwa" : File::Which::which("bwa");
    if ( defined($path) ) {
        print "BWA is already installed!\n\n";
    } else {
        print "Getting BWA (source code): BWA version 0.7.13\n";
        unless ( -e "bwa-0.7.13.tar.bz2" ) { system "wget -q http://downloads.sourceforge.net/project/bio-bwa/bwa-0.7.13.tar.bz2"; }
        system "tar xf bwa-0.7.13.tar.bz2";
        unless ( -d "dependencies" ) { mkdir("dependencies"); }
	chdir("$cwd/bwa-0.7.13");
	print "Compiling...\n";
	system "make > install.log 2>&1";
	system "mv bwa $cwd/dependencies";
	chdir($cwd);
	system "rm -rf bwa-0.7.13";
	print "Done!\n\n";
    }
}

if (defined($tools{'SAMtools'}))    {
    my $path = ( -e "dependencies/samtools" ) ? "dependencies/samtools" : File::Which::which("samtools");
    if ( defined($path) )	{
        print "SAMtools is already installed!\n\n";
    }	else	{
	print "Getting SAMtools (source code): version 1.3\n";
	unless (-e "samtools-1.3.tar.bz2") { system "wget -q https://github.com/samtools/samtools/releases/download/1.3/samtools-1.3.tar.bz2"; }
	system "tar xf samtools-1.3.tar.bz2";
	unless (-d "dependencies")  {
		mkdir("dependencies");
	}
	chdir("$cwd/samtools-1.3");
	print "Compiling...\n";
	system "make > install.log 2>&1";
	system "mv samtools $cwd/dependencies";
	chdir($cwd);
	system "rm -rf samtools-1.3";
	print "Done!\n\n";
    }
}


if ( defined( $tools{'FASTX'} ) ) {
    my $path = ( -e "dependencies/fastx_reverse_complement" ) ? "dependencies/fastx_reverse_complement" : File::Which::which("fastx_reverse_complement");
    if ( defined($path) ) {
        print "FASTX is already installed!\n\n";
    } else {
        print "Getting FASTX-toolkit (pre-compiled): version 0.0.13\n";
        unless ( -e "fastx_toolkit_0.0.13_binaries_MacOSX.10.5.8_i386.tar.bz2" ) { system "wget -q http://hannonlab.cshl.edu/fastx_toolkit/fastx_toolkit_0.0.13_binaries_MacOSX.10.5.8_i386.tar.bz2"; }
        mkdir("fastx");
        system "tar xf fastx_toolkit_0.0.13_binaries_MacOSX.10.5.8_i386.tar.bz2 -C fastx";
        unless ( -d "dependencies" ) { mkdir("dependencies"); }
        system "mv fastx/bin/fastx_reverse_complement dependencies";
        system "rm -rf fastx";
        print "Done!\n\n";
    }
}

exit;
