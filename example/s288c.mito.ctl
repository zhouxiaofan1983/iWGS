#############################
# General options
#############################
genome = example/S288C.mito.fa				
out_dir = S288C_mito					
threads = 12						
memory = 44						

#############################
# Library options
#############################		
library = L001,SE,50,100
library = L002,PE,50,100,180,9				
library = L003,MP,50,100,5000,250			
library = L004,CLR,50,0.85,0.02				
library = L005,PE,50,250,450,23				

#############################
# Simulator options
#############################
pIRS.error_rate = 					
pIRS.error_profile = 					
pIRS.gc = 						
pIRS.gc_profile = 					
pIRS.indel = 						
pIRS.indel_profile =			 		

ART.qual_shift1 = 					
ART.qual_shift2 = 					
ART.qual_profile1 = 					
ART.qual_profile2 = 					
ART.ins_rate1 = 							
ART.ins_rate2 = 					
ART.del_rate1 = 					
ART.del_rate2 = 					

PBSIM.model_qc = /home/zhoux8/scratch/DIMENSIONS/tools/simulation/pbsim-1.0.3/data/model_qc_clr-alyrata					
PBSIM.ratio = 						
PBSIM.accuracy_max = 					
PBSIM.accuracy_min = 					
PBSIM.length_mean = 					
PBSIM.length_sd = 					
PBSIM.length_max = 					
PBSIM.length_min = 					

#############################
# Assembly protocol options
#############################
protocol = P001,ABYSS,L002,L003
protocol = P002,ALLPATHS,L002,L003
protocol = P003,CA,L004
protocol = P004,DISCOVAR,L005
protocol = P005,SOAPdenovo2,L002
protocol = P006,SPAdes,L002			
protocol = P007,SPAdes,L001,L002,L003			
protocol = P008,Velvet,L002,L003

#############################
# Assembler options
#############################
ABYSS.kmer = 					
ABYSS.option = "l=1 n=5 s=100"

ALLPATHS.ploidy = 

CA.sensitive =					

SPAdes.kmer = 					
SPAdes.multi-kmer = 				
SPAdes.option = "--only-assembler"

SOAPdenovo2.kmer = 			
SOAPdenovo2.option = "-F -R -E -w -u"

Velvet.kmer = 			
Velvet.option = "-exp_cov auto -scaffolding yes"

#############################
# Evaluation options
#############################
QUAST.eukaryote = 0					
QUAST.gage = 						
QUAST.gene = 						

#############################
# Executable options
#############################
bin.pIRS = 
bin.ART = #/home/zhoux8/scratch/DIMENSIONS/tools/simulation/ART/art_illumina
bin.PBSIM = /home/zhoux8/scratch/DIMENSIONS/tools/simulation/pbsim-1.0.3/bin/pbsim
bin.KmerGenie = /home/zhoux8/scratch/DIMENSIONS/tools/assembler/kmergenie-1.6741/kmergenie
bin.SOAPdenovo2 = 
bin.SPAdes = #/gpfs21/scratch/zhoux8/DIMENSIONS/tools/assembler/SPAdes-3.1.1-Linux/bin/spades.py
bin.CA = /home/zhoux8/scratch/DIMENSIONS/tools/assembler/wgs-8.2beta/Linux-amd64/bin/PBcR
bin.ALLPATHS = /home/zhoux8/usr/bin/allpathslg/bin/RunAllPathsLG
bin.DISCOVAR = /home/zhoux8/usr/bin/discovar/bin/DiscovarExp
bin.QUAST = #/home/zhoux8/scratch/DIMENSIONS/tools/evaluation/quast-2.3/quast.py
