#!/bin/sh

help_message () {
	echo "------------------------------------------------------------------------------------------------------------"
	echo "taxonomy.sh is meant to generate taxonomy profile for metagenomeic analysis."
	echo "Usage: "
	echo "taxonomy.sh -1 read_1.fastq -2 read_2.fastq -o output_dir  -z 4 -x 1 "	
	echo "Here is the pipeline detaided information,and users are allowed to set addtional each one below in parameters file:"
	echo " ----------             ------              ------------              ------  "
	echo "|input_data| --------》| kaiju | --------》| kaiju2table | --------》| ouput | "
	echo " ----------             ------              —————-------              ——————  "
	echo " "
	echo " "


	echo "Options:"
	echo ""
	echo "	-1 STR         		Forward Sequences data "
	echo "	-2 STR         		Reverse Sequences data "
	echo "	-s STR         		Single read files (need activate single read mode)"
	echo "	-o path         	Generated results directory" 
	echo "	-a STR          	Selected the kaiju method: greedy(default),mem"
	echo "	-z INT          	Number of thread (default=1)"
	echo "	-x INT          	Number in [0, 100],eg 0.1 represents to keep the taxa with abundance more than 0.001 in total [Default:0.1]"
	echo "	-p STR          	parameters file"
	echo "	--single_read_mode	Activate single read mode [Default:False]"
	echo "	--expand_virus_mode	Expand virus profile with full taxon path [Default:False]"		
	echo "	-h STR            	help information"
	echo "------------------------------------------------------------------------------------------------------------";}
 
# load in params
OPTS=`getopt -o 1:2:s:o:a:z:x:p:h --long help,single_read_mode,expand_virus_mode -- "$@"`

# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

# default params
thread=1; method=greedy; single=false; min=0.1; virus=false

while true; do
	case "$1" in
		-1) reads_1=$2 shift 2;;
		-2) reads_2=$2 shift 2;;
		-s) reads_s=$2 shift 2;;
		-o) output=$2 shift 2;;
		-a) method=$2 shift 2;;
		-z) thread=$2 shift 2;;
		-x) min=$2 shift 2;;
		-p) parameters=$2 shift 2;;	
		-h | --help) help_message; exit 1; shift 1;;
		--single_read_mode) single=true; shift 1;;
		--expand_virus_mode) virus=true; shift 1;;
		*) help_message;break ;;
	esac
done



if [ ! -d $output ]; then
        mkdir -p $output;
else
        echo "Warning: output path < $output >already exists."
fi


if [ x"$parameters" != x ]; then 
	add_arg_kaiju=$(custom_params.py -i $parameters -n kaiju)
	add_arg_kaiju2table=$(custom_params.py -i $parameters -n kaiju2table)
fi


echo "########################################################################################################"
echo "########################                 Kaiju taxonomy profile start           ########################"
echo "########################################################################################################"

if [ "$single" = false ]; then
	tmp=${reads_1%_*}; sample=${tmp##*/}
	if [ x"$add_arg_kaiju" != x ]; then 
	echo 'additional parameters is activated :'
	echo "kaiju -t ~/soft_ware/kaiju/kaiju/kaijudb/nodes.dmp -f ~/soft_ware/kaiju/kaiju/kaijudb/refseq/kaiju_db_refseq.fmi \
	-i $reads_1 -j $reads_2 -z $thread -o ${output}/$sample.kaiju.out $add_arg_kaiju"
	fi
	kaiju -t ~/soft_ware/kaiju/kaiju/kaijudb/nodes.dmp -f ~/soft_ware/kaiju/kaiju/kaijudb/refseq/kaiju_db_refseq.fmi \
	-i $reads_1 -j $reads_2 -z $thread -o ${output}/$sample.kaiju.out $add_arg_kaiju
elif [ "$single" = true ]; then
	tmp=${reads_s%_*}; sample=${tmp##*/}
	if [ x"$add_arg_kaiju" != x ]; then 
	echo 'additional parameters is activated :'
	echo "kaiju -t ~/soft_ware/kaiju/kaiju/kaijudb/nodes.dmp -f ~/soft_ware/kaiju/kaiju/kaijudb/refseq/kaiju_db_refseq.fmi \
	-i $reads_s -z $thread -o ${output}/$sample.kaiju.out $add_arg_kaiju"
	fi
	kaiju -t ~/soft_ware/kaiju/kaiju/kaijudb/nodes.dmp -f ~/soft_ware/kaiju/kaiju/kaijudb/refseq/kaiju_db_refseq.fmi \
	-i $reads_s -z $thread -o ${output}/$sample.kaiju.out $add_arg_kaiju
fi

if [ ! -e ${output}/$sample.kaiju.out ]; then
	echo "Something went wrong with running Kaiju! Exiting "
else
	if [ "$virus" = false ]; then
		if [ x"$add_arg_kaiju2table" != x ]; then 
		echo 'additional parameters is activated :'
		echo "kaiju2table -t ~/soft_ware/kaiju/kaiju/kaijudb/nodes.dmp -n ~/soft_ware/kaiju/kaiju/kaijudb/names.dmp \
		-r species -l superkingdom,phylum,class,order,family,genus,species -m $min -o ${output}/$sample.tsv ${output}/$sample.kaiju.out $add_arg_kaiju2table"
		fi
		kaiju2table -t ~/soft_ware/kaiju/kaiju/kaijudb/nodes.dmp -n ~/soft_ware/kaiju/kaiju/kaijudb/names.dmp \
		-r species -l superkingdom,phylum,class,order,family,genus,species -m $min -o ${output}/$sample.tsv ${output}/$sample.kaiju.out $add_arg_kaiju2table
	else
		if [ x"$add_arg_kaiju2table" != x ]; then 
		echo 'additional parameters is activated :'
		echo "kaiju2table -t ~/soft_ware/kaiju/kaiju/kaijudb/nodes.dmp -n ~/soft_ware/kaiju/kaiju/kaijudb/names.dmp \
		-r species -l superkingdom,phylum,class,order,family,genus,species -e -m $min -o ${output}/$sample.tsv ${output}/$sample.kaiju.out $add_arg_kaiju2table"
		fi		
		kaiju2table -t ~/soft_ware/kaiju/kaiju/kaijudb/nodes.dmp -n ~/soft_ware/kaiju/kaiju/kaijudb/names.dmp \
		-r species -l superkingdom,phylum,class,order,family,genus,species -e -m $min -o ${output}/$sample.tsv ${output}/$sample.kaiju.out $add_arg_kaiju2table
	fi	
fi

echo "########################################################################################################"
echo "########################            Kaiju taxonomy profile completed            ########################"
echo "########################################################################################################"


