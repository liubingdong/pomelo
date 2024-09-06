#!/bin/sh

help_message () {
	echo "------------------------------------------------------------------------------------------------------------"
	echo "function_qiime1_plot.sh is meant to perform classic microbial data analysis based on funtion anotation biom file."
	echo "Usage: "
	echo "function_qiime1_plot.sh -i CARD.biom -o output_dir  -m mapping file -t 30 -p parameters"	
	echo "Here is the pipeline detaided information,and users are allowed to set addtional each one below in parameters file:"
	#echo " ----------             --------------------------------              ---------------------             ------  "
	#echo "|input_data| --------》| summarize_taxa_through_plots.py | --------》| alpha_rarefaction.py | --------》| ouput | "
	#echo " ----------             --------------------------------              —————----------------              ——————  "
	echo " "
	echo " "


	echo "Options:"
	echo ""
	echo "	-i STR              Function annotation table in tsv format"
	echo "	-o Path             Generated results directory" 
	echo "	-t INT              number of thread (default=1)"
	echo "	-m STR              mapiing file"
	echo "	-p STR              parameters file"
	echo "	-h STR              help information"
	echo "------------------------------------------------------------------------------------------------------------";}

# load in params
OPTS=`getopt -o i:o:t:m:p:h --long help -- "$@"`

# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

# default params
thread=1; level=proka; x=0.001; 

while true; do
	case "$1" in
		-i) input=$2 shift 2;;
		-o) output=$2 shift 2;;
		-t) thread=$2 shift 2;;
		-m) mapping=$2 shift 2;;	
		-p) parameters=$2 shift 2;;	
		-h | --help) help_message; exit 1; shift 1;;
		*) help_message;break ;;
	esac
done

mkdir -p ${output}/temp

for F in $input/*tsv; do
	BASE1=${F##*/}
	Feature1=${BASE1%%.*}
	function_table_trans.py -i $F -o ${output}/temp/${Feature1}.TPM.biom -b
done

for K in ${output}/temp/*biom;do
	BASE2=${K##*/}
	Feature2=${BASE2%%.*}
	beta_diversity_through_plots.py -i $K -o ${output}/3D_PCA/${Feature2}_bdiv_plots/ -m $mapping  --parallel -aO $thread -p $parameters
done




















