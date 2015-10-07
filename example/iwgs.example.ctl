#############################
# General options
#############################
genome = S_cerevisiae_288C.mito.fa			# the reference genome sequence in fasta format 
out_dir = iWGS_test					# all outputs will be written to the folder "./iWGS_test"
threads = 						# number of CPUs to use (default: 1)
memory = 						# number of GBs of memory to use (default: 8)

#############################
# Library options
#############################
library = L001,PE,50,100,180,9				# Illumina 100bp PE library "L001" - coverage: 50x; average insert size: 180bp; SD of insert size: 9bp
library = L002,MP,50,100,8000,400			# Illumina 100bp MP library "L002" - coverage: 50x; average insert size: 8000bp; SD of insert size: 400bp
library = L003,CLR,60,0.856,0.029			# PacBio CLR library "L003" - coverage: 60x; average read accuracy: 0.856; SD of read accuracy: 0.029
library = L004,PE,50,250,450,23				# Illumina 250bp PE library "L004" - coverage: 50x; average insert size: 450bp; SD of insert size: 23bp
library = L005,CLR,10,0.856,0.029			# PacBio CLR library "L005" - coverage: 10x; average read accuracy: 0.856; SD of read accuracy: 0.029

#############################
# Simulator options
#############################
pIRS.error_rate = 					# substitution error rate: 0, 1, or 0.0001-0.63 (default: 1 - indicate that the default setting of pIRS should be used)
pIRS.error_profile = 					# the base-calling profile for simulating substitution-error and quality score (default: the default profile of pIRS)
pIRS.gc = 						# whether to simulate GC bias: 1 - yes; 0 - no (default: 1)
pIRS.gc_profile = 					# the GC content-coverage file for simulating GC bias (default: the default profile of pIRS)
pIRS.indel = 						# whether to simulate indel errors: 1 - yes; 0 - no (default: 1)
pIRS.indel_profile =			 		# the InDel-error profile for simulating InDel-error (default: the default profile of pIRS)

ART.qual_shift1 = 					# the amount to shift the quality score of all first-reads (default: 0)
ART.qual_shift2 = 					# the amount to shift the quality score of all second-reads (default: 0)
ART.qual_profile1 = 					# the quality profile of first-reads (default: the default profile of ART)
ART.qual_profile2 = 					# the quality profile of second-reads (default: the default profile of ART)
ART.ins_rate1 = 					# the insertion rate of first-reads (default: 0.00009)
ART.ins_rate2 = 					# the insertion rate of second-reads (default: 0.00015)
ART.del_rate1 = 					# the deletion rate of first-reads (default: 0.00011)
ART.del_rate2 = 					# the deletion rate of second-reads (default: 0.00023)

PBSIM.model_qc = 					# the model of quality code for simulating read accuracy (default: the default profile of PBSIM)
PBSIM.ratio = 						# the ratio of substitution:insertion:deletion errors (default: 10:60:30)
PBSIM.accuracy_max = 					# the maximum read accuracy (default: 0.90)
PBSIM.accuracy_min = 					# the minimum read accuracy (default: 0.75)
PBSIM.length_mean = 					# the mean of read length (default: 3000)
PBSIM.length_sd = 					# the standard deviation of read length (default: 2300)
PBSIM.length_max = 					# the maximum read length (default: 25000)
PBSIM.length_min = 					# the minimum read length (default: 100)

#############################
# Quality control options
#############################
QC = L001,L002						# whether to perform QC on selected libraries (provide a list of library names separated by comma) or all libraries ("all")

Trimmomatic.trailing = 3				# the quality score cutoff for Trimmomatic quaulity-based trimming from 3' end of reads
Trimmomatic.adapters = adapters.filelist		# the file containing the list of adapter sequence files used for Trimmomatic adapter trimming 				
Trimmomatic.minlen = 25					# the minimum read length after Trimmomatic trimming

NextClip.adapter = 					# the adapter sequence for NextClip adapter trimming
NextClip.minlen = 25					# the minimum read length after NextClip trimming

Correction.tool = Lighter				# the error correction tool to be used (default: "Lighter"; also support "Quake")
Correction.kmer = 					# the k-mer size used for error correction

#############################
# Assembly protocol options
#############################
protocol = P001,ABYSS,L001,L002				# assembly protocol "P001" that uses the ABYSS assembler and libraries "L001" and "L002"
protocol = P002,ALLPATHS,L001,L002			# assembly protocol "P002" that uses the ALLPATHS-LG assembler and libraries "L001" and "L002"
protocol = P003,CA,L003					# assembly protocol "P003" that uses the Celera Assembler and the library "L003"
protocol = P004,DISCOVAR,L004				# assembly protocol "P004" that uses the DISCOVAR de novo assembler and the library "L004"
protocol = P005,MaSuRCA,L001,L002			# assembly protocol "P005" that uses the MaSuRCA assembler and libraries "L001" and "L002"
protocol = P006,Platanus,L001,L002			# assembly protocol "P006" that uses the Platanus assembler and libraries "L001" and "L002"
protocol = P007,SGA,L001,L002				# assembly protocol "P007" that uses the SGA assembler and libraries "L001" and "L002"
protocol = P008,SOAPdenovo2,L001,L002			# assembly protocol "P008" that uses the SOAPdenovo2 assembler and libraries "L001" and "L002"
protocol = P009,SPAdes,L001,L002			# assembly protocol "P009" that uses the SPAdes assembler and libraries "L001" and "L002"
protocol = P010,SPAdes,L001,L002,L005			# assembly protocol "P010" that uses the SPAdes assembler and libraries "L001", "L002", and "L005"
protocol = P011,Velvet,L001,L002			# assembly protocol "P011" that uses the Velvet assembler and libraries "L001" and "L002"

#############################
# Assembler options
#############################
ABYSS.kmer = 						# default: 0 - to be estimated using KmerGenie 
ABYSS.option = "l=1 n=5 s=100"				# GAGE-B recipe

ALLPATHS.ploidy = 					# default: 1; set to 2 for heterozygous assembly

CA.pbCNS =						# default: 1;
CA.sensitive =						# default: 0; set to 1 for lower-quality PacBio data

MaSuRCA.kmer =						# default: 0 - to be determined automatically by MaSuRCA

SPAdes.kmer = 						# default: 0 - to be estimated using KmerGenie, and used in addition to "multi-kmer" (if turned on)
SPAdes.multi-kmer = 					# default: 1 - to use multiple k-mer sizes
SPAdes.option = "--only-assembler"			# set it empty " " to enable the error-correction module

SOAPdenovo2.kmer = 					# default: 0 - to be estimated using KmerGenie
SOAPdenovo2.option = "-F -R -E -w -u"			# GAGE-B recipe

Velvet.kmer = 						# default: 0 - to be estimated using KmerGenie
Velvet.option = "-exp_cov auto -scaffolding yes"	# GAGE-B recipe

#############################
# Evaluation options
#############################
QUAST.eukaryote = 0					# whether the reference genome is eukaryotic: 1 - yes; 0 - no (default: 1)
QUAST.gage = 						# whether to generate GAGE report: 1 - yes; 0 - no (default: 1)
QUAST.gene = 						# gene annotations to be used for evaluation (default: NA)

REAPR.libs = L001,L002					# the libraries to be used for REAPR evalution

#############################
# Executable options
#############################
bin.ART = #/home/xiaofan/iWGS/tools/ART/art_illumina
bin.pIRS = #/home/xiaofan/iWGS/tools/pIRS/pirs
bin.PBSIM = #/home/xiaofan/iWGS/tools/PBSIM/bin/pbsim
bin.Trimmomatic = #/home/xiaofan/iWGS/tools/Trimmomatic/trimmomatic.jar 
bin.NextClip = #/home/xiaofan/iWGS/tools/NextClip/bin/nextclip
bin.Lighter = #/home/xiaofan/iWGS/tools/Lighter/Lighter
bin.Quake = #/home/xiaofan/iWGS/tools/Quake/bin/quake.py
bin.KmerGenie = #/home/xiaofan/iWGS/tools/kmergenie/kmergenie
bin.ABYSS = #/home/xiaofan/iWGS/tools/ABYSS/bin/abyss-pe
bin.ALLPATHS = #/home/xiaofan/iWGS/tools/ALLPATHS-LG/bin/RunAllPathsLG
bin.BLASR = #/home/xiaofan/iWGS/tools/CA/bin/blasr
bin.PBcR = #/home/xiaofan/iWGS/tools/CA/bin/PBcR
bin.PBDAGCON = #/home/xiaofan/iWGS/tools/CA/bin/pbdagcon
bin.runCA = #/home/xiaofan/iWGS/tools/CA/bin/runCA
bin.DISCOVAR = #/home/xiaofan/iWGS/tools/DISCOVAR/bin/DiscovarDeNovo
bin.MaSuRCA = #/home/xiaofan/iWGS/tools/MaSuRCA/bin/masurca
bin.Platanus = #/home/xiaofan/iWGS/tools/Platanus/platanus
bin.SGA = #/home/xiaofan/iWGS/tools/SGA/bin/sga
bin.SOAPdenovo2 = #/home/xiaofan/iWGS/tools/SOAPdenovo2/SOAPdenovo2
bin.SPAdes = #/home/xiaofan/iWGS/tools/SPAdes/bin/spades.py
bin.dipSPAdes = # /home/xiaofan/iWGS/tools/SPAdes/bin/dipspades.py
bin.velveth = #/home/xiaofan/iWGS/tools/Velvet/velveth
bin.velvetg = #/home/xiaofan/iWGS/tools/Velvet/velvetg
bin.QUAST = #/home/xiaofan/iWGS/tools/QUAST/quast.py
bin.REAPR = #/home/xiaofan/iWGS/tools/Reapr/reapr
bin.bank-transact = #/home/xiaofan/iWGS/tools/dependencies/bank-transact
bin.BWA = #/home/xiaofan/iWGS/tools/dependencies/bwa
bin.SAMtools = #/home/xiaofan/iWGS/tools/dependencies/samtools
bin.FASTX = #/home/xiaofan/iWGS/tools/dependencies/fastx_reverse_complement
