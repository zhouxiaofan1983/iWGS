#############################
# General options
#############################
genome = example/Kazachstania_africana.fa		# the reference genome sequence in fasta format 
out_dir = K_africana					# all outputs will be written to the folder ./K_african
threads = 4						# number of CPUs to use (default: 1)
memory = 32						# number of GBs of memory to use (default: 8)

#############################
# Library options
#############################
library = L001,SE,50,100				# Illumina 100bp SE library "L001" - coverage: 50x
library = L002,PE,50,100,180,9				# Illumina 100bp PE library "L002" - coverage: 50x; average insert size: 180bp; SD of insert size: 9bp
library = L003,MP,50,100,5000,250			# Illumina 100bp MP library "L003" - coverage: 50x; average insert size: 5000bp; SD of insert size: 250bp
library = L004,CLR,50,0.85,0.02				# PacBio CLR library "L003" - coverage: 50x; average read accuracy: 0.85; SD of read accuracy: 0.02
library = L005,PE,50,250,450,23				# Illumina 250bp PE library "L005" - coverage: 50x; average insert size: 450bp; SD of insert size: 23bp

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
# Assembly protocol options
#############################
protocol = P001,ABYSS,L001,L002,L003			# assembly protocol "P001" that uses the ABYSS assembler and libraries "L001", ¡°L002¡±, and ¡°L003¡±
protocol = P002,ALLPATHS,L002,L003			# assembly protocol "P002" that uses the ALLPATHS-LG assembler and libraries ¡°L002¡± and ¡°L003¡±
protocol = P003,CA,L002,L004				# assembly protocol "P003" that uses the Celera Assembler and libraries ¡°L002¡± and ¡°L004¡±
protocol = P004,CA,L004					# assembly protocol "P004" that uses the Celera Assembler and the library ¡°L004¡±
protocol = P005,DISCOVAR,L005				# assembly protocol "P005" that uses the DISCOVAR de novo assembler and the library ¡°L005¡±
protocol = P005,SOAPdenovo2,L001,L002,L003		# assembly protocol "P006" that uses the SOAPdenovo2 assembler and libraries "L001", ¡°L002¡±, and ¡°L003¡±
protocol = P005,SPAdes,L001,L002,L003			# assembly protocol "P007" that uses the SPAdes assembler and libraries "L001", ¡°L002¡±, and ¡°L003¡±
protocol = P006,Velvet,L001,L002,L003			# assembly protocol "P008" that uses the Velvet assembler and libraries "L001", ¡°L002¡±, and ¡°L003¡±

#############################
# Assembler options
#############################
ABYSS.kmer = 						# default: 0 - to be estimated using KmerGenie 
ABYSS.option = "l=1 n=5 s=100"				# GAGE-B recipe

ALLPATHS.ploidy = 					# default: 1; set to 2 for heterozygous assembly

CA.sensitive =						# default: 0; set to 1 for lower-quality PacBio data

SPAdes.kmer = 						# default: 0 - to be estimated using KmerGenie
SPAdes.multi-kmer = 					# default: 1 - to use multiple k-mer sizes
SPAdes.option = "--only-assembler"			# set it empty " " to enable the error-correction module

SOAPdenovo2.kmer = 					# default: 0 - to be estimated using KmerGenie
SOAPdenovo2.option = "-F -R -E -w -u"			# GAGE-B recipe

Velvet.kmer = 						# default: 0 - to be estimated using KmerGenie
Velvet.option = "-exp_cov auto -scaffolding yes"	# GAGE-B recipe

#############################
# Evaluation options
#############################
QUAST.eukaryote = 					# whether the reference genome is eukaryotic: 1 - yes; 0 - no (default: 1)
QUAST.gage = 						# whether to generate GAGE report: 1 - yes; 0 - no (default: 1)
QUAST.gene = example/Kazachstania_africana.genes	# gene annotations to be used for evaluation (default: NA)

#############################
# Executable options
#############################
bin.pIRS = /home/xiaofan/iWGS/tools/pIRS/pirs
bin.ART =/home/xiaofan/iWGS/tools/ART/art_illumina
bin.PBSIM = /home/xiaofan/iWGS/tools/PBSIM/bin/pbsim
bin.KmerGenie = /home/xiaofan/iWGS/tools/kmergenie/kmergenie
bin.ABYSS = /home/xiaofan/iWGS/tools/ABYSS/bin/abyss-pe
bin.ALLPATHS = /home/xiaofan/iWGS/tools/ALLPATHS-LG/bin/RunAllPathsLG
bin.CA = /home/xiaofan/iWGS/tools/Linux-amd64/bin/PBcR
bin.DISCOVAR = /home/xiaofan/iWGS/tools/DISCOVAR/bin/DiscovarExp
bin.SOAPdenovo2 = /home/xiaofan/iWGS/tools/SOAPdenovo2
bin.SPAdes = /home/xiaofan/iWGS/tools/SPAdes/bin/spades.py
bin.dipSPAdes = /home/xiaofan/iWGS/tools/SPAdes/bin/dipspades.py
bin.velvetg = /home/xiaofan/iWGS/tools/Velvet/velvetg
bin.velveth = /home/xiaofan/iWGS/tools/Velvet/velveth
bin.FastqToSam = /home/xiaofan/iWGS/tools/FastqToSam.jar
bin.QUAST = /home/xiaofan/iWGS/tools/QUAST/quast.py
