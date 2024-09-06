#!/bin/sh

help_message () {
	echo "------------------------------------------------------------------------------------------------------------"
	echo "single_fuction.sh is meant to generate function annotation for metagenomeic analysis."
	echo "Usage: "
	echo "single_fuction.sh -i query.faa -d database.faa -o output_dir  -t 4 -m sensitive"	
	echo "Here is the pipeline detaided information,and users are allowed to set addtional each one below in parameters file:"
	echo " ----------             --------              ------ "
	echo "|input_data| --------》| diamond | --------》| ouput | "
	echo " ----------             --------              ————-- "
	echo " "
	echo " "


	echo "Options:"
	echo ""
	echo "	-i STR         		Query data in fasta format"
	echo "	-d STR         		Against data in fasta format"
	echo "	-o path         	Generated results directory" 
	echo "	-m STR          	Selected the diamond method: sensitive(default),more-sensitive,very-sensitive"
	echo "	-t INT          	Number of thread (default=1)"
	echo "	-e INT          	Min E-value expected when searching for diamond search."
	echo "	-s INT          	Min bit score expected for diamond search."
	echo "	-p STR          	parameters file"
	echo "	-h STR            	help information"
	echo "------------------------------------------------------------------------------------------------------------";}
 
 # load in params
OPTS=`getopt -o i:d:o:m:t:e:s:p:h --long help -- "$@"`

# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

# default params
thread=1; method=sensitive

while true; do
	case "$1" in
		-i) query_seq=$2 shift 2;;
		-d) against_seq=$2 shift 2;;
		-o) output=$2 shift 2;;
		-m) method=$2 shift 2;;
		-t) thread=$2 shift 2;;
		-e) evalue=$2 shift 2;;
		-s) score=$2 shift 2;;
		-p) parameters=$2 shift 2;;	
		-h | --help) help_message; exit 1; shift 1;;
		*) help_message;break ;;
	esac
done

# obtain the seq data info
BASE1=${against_seq##*/}
against_seq_format=${BASE1##*.}
against_seq_name=${BASE1%.*}

BASE2=${query_seq##*/}
query_seq_name=${BASE2%.*}

mkdir -p ${output}

if [ "$against_seq_format" = fa ] || [ "$against_seq_format" = faa ] || [ "$against_seq_format" = fasta ]; then
	echo 'The input fasta file needs to change into dmnd format.'
	diamond makedb --in $against_seq -d $against_seq_name
	mv ${against_seq_name}.dmnd ${output}/
else
	echo 'The input against file should be end with fa, faa, or fasta,.'
fi



if [ x"$parameters" != x ]; then 
	add_arg_diamond=$(custom_params.py -i $parameters -n diamond)
	echo "diamond additional parameters is activated :"
fi




if [ ! -s ${output}/${against_seq_name}.dmnd ] && [ "$against_seq_format" != dmnd ]; then 
	echo "Against file format is wrong, plz check it. Exiting..."; 
else
	diamond blastp -d ${output}/${against_seq_name}.dmnd --out ${output}/${query_seq_name}.${against_seq_name}.raw.tsv --outfmt 6 --sensitive --query $query_seq --threads $thread  $add_arg_diamond	
	diamond_filter.py -i ${output}/${query_seq_name}.${against_seq_name}.raw.tsv -o ${output}/${query_seq_name}.${against_seq_name}.filter.tsv -e $evalue -s $score
fi






























