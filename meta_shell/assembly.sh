#!/bin/sh

help_message () {
	echo "------------------------------------------------------------------------------------------------------------"
	echo "assembly.sh is meant to generate assembly contigs for metagenomeic analysis."
	echo "Usage: "
	echo "assembly.sh -1 read_1.fastq -2 read_2.fastq -o output_dir  -t 4 -m megahit"	
	echo "Here is the pipeline detaided information,and users are allowed to set addtional each one below in parameters file:"
	echo " ----------             ------------------              ------              ------  "
	echo "|input_data| --------》| megahit/metaspades| --------》| quast | --------》| ouput | "
	echo " ----------             --------—————-----              —————-              ——————  "
	echo " "
	echo " "


	echo "Options:"
	echo ""
	echo "	-1 STR         		Forward Sequences data "
	echo "	-2 STR         		Reverse Sequences data "
	echo "	-r STR         		single-end files (need activate single-end_mode)"
	echo "	-12 STR         	paired-end files (need activate paired-end_mode)"
	echo "	-m STR          	Selected the assembly tools: megahit(default),metaspades"
	echo "	-o path         	Generated results directory" 
	echo "	-t INT          	number of thread (default=1)"
	echo "	-p STR          	parameters file"
	echo "	--single_end_mode	activate single-end files mode"	
	echo "	--paired_end_mode	activate paired-end files mode"	
	echo "	-h STR            	help information"
	echo "------------------------------------------------------------------------------------------------------------";}
 


# load in params
OPTS=`getopt -o 1:2:r:12:m:o:t:p:h --long help,single-end_mode,paired-end_mode -- "$@"`

# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

# default params
thread=1; method=megahit; single=false; paired=false




while true; do
	case "$1" in
		-1) reads_1=$2 shift 2;;
		-2) reads_2=$2 shift 2;;
		-r) reads_r=$2 shift 2;;
		-12) reads_12=$2 shift 2;;
		-m) method=$2 shift 2;;
		-o) output=$2 shift 2;;
		-t) thread=$2 shift 2;;
		-p) parameters=$2 shift 2;;	
		--single_end_mode) single=true; shift 1;;
		--paired_end_mode) paired=true; shift 1;;
		-h | --help) help_message; exit 1; shift 1;;
		*) help_message;break ;;
	esac
done



# confirm everythig is set up 


if [ "$single" = true ] && [ "$paired" = true ]; then
	echo 'Single-end and paired-end are not allowed to co-exist!'
fi

if [ "$single" = false ] && [ "$paired" = false ]; then
	echo 'Forward and Reverse Sequences mode is activated!'
	if [ ! -s $reads_1 ]; then echo "$reads_1 file does not exist. Exiting..."; fi
	if [ ! -s $reads_2 ]; then echo "$reads_2 file does not exist. Exiting..."; fi
	if [ "$reads_1" = "$reads_2" ]; then echo "The forward and reverse reads are the same file. Exiting pipeline."; fi
fi





tmp=${reads_1%_*}; sample=${tmp##*/}

if [ "$method" = megahit ]; then
	echo "########################################################################################################"
	echo "########################                 Megahit assemble start                 ########################"
	echo "########################################################################################################"
	# confirm megahit output folder 
	if [ ! -d $output ]; then
	        mkdir -p $(dirname $output);
	else
	        echo "Warning: output path < $output >already existed."
	fi

	if [ x"$parameters" != x ]; then 
		add_arg_megahit=$(custom_params.py -i $parameters -n megahit)
		echo "megahit additional parameters is activated :"
	fi

	if [ "$single" = true ]; then
		if [ x"$add_arg_megahit" != x ]; then
			echo "megahit -r $reads_r -t $thread -o $output $add_arg_megahit"
		fi		
		megahit -r $reads_r -t $thread -o $output $add_arg_megahit
	elif [ "$paired" = true ]; then
		if [ x"$add_arg_megahit" != x ]; then
			echo "megahit --12 $reads_12 -t $thread -o $output $add_arg_megahit"
		fi			
		megahit --12 $reads_12 -t $thread -o $output $add_arg_megahit
	elif [ "$single" = false ] && [ "$paired" = false ]; then
		if [ x"$add_arg_megahit" != x ]; then
			echo "megahit -1 $reads_1 -2 $reads_2 -t $thread -o $output $add_arg_megahit"
		fi			
		megahit -1 $reads_1 -2 $reads_2 -t $thread -o $output $add_arg_megahit
	fi	

	if [[ $? -ne 0 ]]; then
		echo "Something went wrong with running megahit! Exiting."
	fi

	mkdir -p $output/final_contig 
	mv ${output}/final.contigs.fa $output/final_contig/${sample}_final_assembly_contigs.fa
fi




if [ "$method" = metaspades ]; then
	echo "########################################################################################################"
	echo "########################              Metaspades assemble start                 ########################"
	echo "########################################################################################################"
	if [ x"$parameters" != x ]; then 
		add_arg_metaspades=$(custom_params.py -i $parameters -n metaspades)
		echo "metaspades additional parameters is activated :"
	fi

	if [ "$single" = true ]; then
		if [ x"$add_arg_metaspades" != x ]; then
			echo "metaspades.py -s $reads_r -t $thread -o $output $add_arg_metaspades"
		fi		
		metaspades.py -s $reads_r -t $thread -o $output $add_arg_metaspades
	elif [ "$paired" = true ]; then
		if [ x"$add_arg_metaspades" != x ]; then
			echo "metaspades.py --12 $reads_12 -t $thread -o $output $add_arg_metaspades"
		fi		
		metaspades.py --12 $reads_12 -t $thread -o $output $add_arg_metaspades
	elif [ "$single" = false ] && [ "$paired" = false ]; then
		if [ x"$add_arg_metaspades" != x ]; then
			echo "metaspades.py -1 $reads_1 -2 $reads_2 -t $thread -o $output $add_arg_metaspades"
		fi		
		metaspades.py -1 $reads_1 -2 $reads_2 -t $thread -o $output $add_arg_metaspades
	fi	

	if [[ $? -ne 0 ]]; then
		echo "Something went wrong with running megahit! Exiting."
	fi


	mkdir -p $output/final_contig 
	mv ${output}/contigs.fasta $output/final_contig/${sample}_final_assembly_contigs.fa
fi


if [ x"$parameters" != x ]; then 
	add_arg_quast=$(custom_params.py -i $parameters -n quast)
	echo "quast additional parameters is activated :"
	echo "quast -t $thread -o ${output}/QUAST_out/ $output/final_contig/final_assembly_contigs.fa $add_arg_quast"
fi

quast -t $thread -o ${output}/QUAST_out/ $output/final_contig/${sample}_final_assembly_contigs.fa $add_arg_quast























