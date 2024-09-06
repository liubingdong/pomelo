#!/usr/bin/sh
# -*- coding: UTF-8 -*-

help_message () {
	echo "------------------------------------------------------------------------------------------------------------"
	echo "read_qc.sh is meant to quality control the input sequences including estimate, trim and decontamination."
	echo "Here is the pipeline detaided information,and users are allowed to set addtional each one below in parameters file:"
	echo " --------             -------------             ---------              --------  "
	echo "| fastqc | --------》| trim_galore | --------》| bmtagger | --------》| fastqc | "
	echo " --------             --------—————             —————————              ————————  "
	echo " "
	echo " "


	echo "Usage: "
	echo "read_qc.sh -1 read_1.fastq -2 read_2.fastq -o output_dir -q 20 -t 4 -p parameters"	
	echo ""	
	echo "Options:"
	echo ""
	echo "	-1 STR         		Forward Sequences data "
	echo "	-2 STR         		Reverse Sequences data "
	echo "	-s STR         		single read for single-end and paired read (need activate single-read_mode "
	echo "	-o path         	Generated results directory" 
	echo "	-q STR          	Quality control standard (default=20)"
	echo "	-t INT          	number of thread (default=1)"
	echo "	-x STR		    	define the protencial host contamination (human=hg38, mice=mm10, rat=rn4, pig=susScr2)"
	echo "	-p STR          	parameters file"
	echo "	--single-read_mode	activate single-read_mode for single-end and paired read"			
	echo "	--skip-trimming		dont trim sequences with trimgalore"
	echo "	--skip-bmtagger		dont remove host sequences with bmtagger"
	echo "	-h STR            	help information"
	echo "------------------------------------------------------------------------------------------------------------";}
 

# default params
thread=1; qc=20; trim=true; bmtagger=true; host=hg38; single=false


# load in params
OPTS=`getopt -o 1:2:s:o:q:t:x:p:h --long help,single-read_mode,skip-trimming,skip-bmtagger -- "$@"`

# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

while true; do
	case "$1" in
		-1) reads_1=$2 shift 2;;
		-2) reads_2=$2 shift 2;;
		-s) reads_s=$2 shift 2;;
		-o) output=$2 shift 2;;
		-q) qc=$2 shift 2;;
		-t) thread=$2 shift 2;;
		-x) host=$2 shift 2;;	
		-p) parameters=$2 shift 2;;	
		-h | --help) help_message; exit 1; shift 1;;
		--single-read_mode) single=true; shift 1;;
		--skip-trimming) trim=false; shift 1;;
		--skip-bmtagger) bmtagger=false; shift 1;;
		*) help_message;break ;;
	esac
done


# confirm everythig is set up 
if [ ! -d $output ]; then
        mkdir -p $output;
else
        echo "Warning: output path < $output >already exists."
fi


if [ "$single" = false ]; then 
	echo "Forward and Reverse Sequences mode has been activated!"
	if [ ! -s $reads_1 ]; then echo "$reads_1 file does not exist. Exiting..."; fi
	if [ ! -s $reads_2 ]; then echo "$reads_2 file does not exist. Exiting..."; fi
	if [ "$reads_1" = "$reads_2" ]; then echo "The forward and reverse reads are the same file. Exiting pipeline."; fi

	tmp=${reads_1%_*}; sample=${tmp##*/}

	echo "########################################################################################################"
	echo "########################                 MAKING PRE-QC REPORT                   ########################"
	echo "########################################################################################################"
	mkdir ${output}/pre-QC_report
	if [ x"$parameters" != x ]; then 
		add_arg_fastqc=$(custom_params.py -i $parameters -n fastqc)
		if [ x"$add_arg_fastqc" != x ]; then 
			echo "pre-fastqc additional parameters is activated :"
			echo "fastqc  -t $thread -o ${output}/pre-QC_report -f fastq $reads_1 $reads_2 $add_arg_fastqc"
		fi
	fi

	fastqc  -t $thread -o ${output}/pre-QC_report -f fastq $reads_1 $reads_2 $add_arg_fastqc
	
	if [ $? -ne 0 ]; then echo "Something went wrong with making pre-QC fastqc report. Exiting."; fi

	if [ "$trim" = true ]; then
		if [ x"$parameters" != x ]; then 
			add_arg_trim=$(custom_params.py -i $parameters -n trim_galore)
			if [ x"$add_arg_trim" != x ]; then 
				echo "trim_galore additional parameters is activated :"
				echo "trim_galore --no_report_file --paired -o $output $reads_1 $reads_2 -q $qc $add_arg_trim"
			fi
		fi

		trim_galore --no_report_file --paired -o $output $reads_1 $reads_2 -q $qc $add_arg_trim
		mv ${output}/*val_1.fq ${output}/trimmed_1.fastq
		mv ${output}/*val_2.fq ${output}/trimmed_2.fastq
		if [[ ! -s ${output}/trimmed_1.fastq ]]; then echo "Something went wrong with trimming the reads. Exiting."; fi
		reads_1=${output}/trimmed_1.fastq
		reads_2=${output}/trimmed_2.fastq

	fi


	if [ "$bmtagger" = true ]; then
		echo "########################################################################################################"
		echo "########################           Remove host sequences with bmtagger         #########################"
		echo "########################################################################################################"

		mkdir ${output}/bmtagger_tmp
		if [ x"$parameters" != x ]; then 
			add_arg_bmtagger=$(custom_params.py -i $parameters -n bmtagger)
			if [ x"$add_arg_bmtagger" != x ]; then 
			echo "bmtagger additional parameters is activated :"
			echo "bmtagger.sh -b /public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/${host}/${host}.bitmask -x /public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/${host}/${host}.srprism \
			-T ${output}/bmtagger_tmp -q 1 -1 $reads_1 -2 $reads_2 -o ${output}/$sample.bmtagger.list $add_arg_bmtagger"
			fi
		fi

		bmtagger.sh -b /public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/${host}/${host}.bitmask -x /public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/${host}/${host}.srprism \
		-T ${output}/bmtagger_tmp -q 1 -1 $reads_1 -2 $reads_2 -o ${output}/$sample.bmtagger.list $add_arg_bmtagger

		if [[ $? -ne 0 ]]; then
			echo "Something went wrong with running Bmtagger! Exiting."
		else
			if [[ ! -s ${output}/${sample}.bmtagger.list ]]; then echo "No contamination reads found, which is very unlikely."; 
			else 
			contamination=$(cat ${output}/${sample}.bmtagger.list | wc -l)
			echo "$contamination contamination sequences are detected by bmtagger"
			fi
		fi
	# acording bmtagger.list to filter trimed sequences 
	filter_host.py -i $reads_1 -t ${output}/$sample.bmtagger.list -f fastq -o clean > ${output}/${sample}_1.clean.fastq
	filter_host.py -i $reads_1 -t ${output}/$sample.bmtagger.list -f fastq -o host > ${output}/${sample}_1.host.fastq
	filter_host.py -i $reads_2 -t ${output}/$sample.bmtagger.list -f fastq -o clean > ${output}/${sample}_2.clean.fastq
	filter_host.py -i $reads_2 -t ${output}/$sample.bmtagger.list -f fastq -o host > ${output}/${sample}_2.host.fastq
	reads_1=${output}/${sample}_1.clean.fastq
	reads_2=${output}/${sample}_2.clean.fastq
	fi

	echo "#########################################################################################################"
	echo "########################                 MAKING POST-QC REPORT                   ########################"
	echo "#########################################################################################################"
	mkdir ${output}/post-QC_report
	if [ x"$parameters" != x ]; then 
		add_arg_fastqc=$(custom_params.py -i $parameters -n fastqc)
		if [ x"$add_arg_fastqc" != x ]; then 
			echo "post-fastqc additional parameters is activated :"
			echo "fastqc  -t $thread -o ${output}/pre-QC_report -f fastq $reads_1 $reads_2 $add_arg_fastqc"
		fi
	fi

	fastqc  -t $thread -o ${output}/post-QC_report -f fastq $reads_1 $reads_2 $add_arg_fastqc
	
	if [ $? -ne 0 ]; then echo "Something went wrong with making post-QC fastqc report. Exiting."; fi


	echo "#########################################################################################################"
	echo "########################              READ QC PIPELINE COMPLETE!!!              #########################"
	echo "#########################################################################################################"

else
	echo "Single-read_mode for single-end and paired read has been ativated !"
	if [ ! -s $reads_s ]; then echo "$reads_s file does not exist. Exiting..."; fi
	tmp=${reads_s%_*}; sample=${tmp##*/}
	echo "########################################################################################################"
	echo "########################                 MAKING PRE-QC REPORT                   ########################"
	echo "########################################################################################################"
	mkdir ${output}/pre-QC_report
	if [ x"$parameters" != x ]; then 
		add_arg_fastqc=$(custom_params.py -i $parameters -n fastqc)
		if [ x"$add_arg_fastqc" != x ]; then 
			echo "pre-fastqc additional parameters is activated :"
			echo "fastqc  -t $thread -o ${output}/pre-QC_report -f fastq $reads_s $add_arg_fastqc"
		fi
	fi

	fastqc  -t $thread -o ${output}/pre-QC_report -f fastq $reads_s $add_arg_fastqc
	
	if [ $? -ne 0 ]; then echo "Something went wrong with making pre-QC fastqc report. Exiting."; fi

	if [ "$trim" = true ]; then
		if [ x"$parameters" != x ]; then 
			add_arg_trim=$(custom_params.py -i $parameters -n trim_galore)
			if [ x"$add_arg_trim" != x ]; then 
				echo "trim_galore additional parameters is below :"
				echo "trim_galore --no_report_file --paired -o $output $reads_s -q $qc $add_arg_trim"
			fi
		fi

		trim_galore --no_report_file -o $output $reads_s -q $qc $add_arg_trim
		mv ${output}/*trimmed.fq ${output}/trimmed.fastq
		if [[ ! -s ${output}/trimmed.fastq ]]; then echo "Something went wrong with trimming the reads. Exiting."; fi
		reads_s=${output}/trimmed.fastq	
	fi

	if [ "$bmtagger" = true ]; then
		echo "########################################################################################################"
		echo "########################           Remove host sequences with bmtagger         #########################"
		echo "########################################################################################################"

		mkdir ${output}/bmtagger_tmp
		if [ x"$parameters" != x ]; then 
			add_arg_bmtagger=$(custom_params.py -i $parameters -n bmtagger)
			if [ x"$add_arg_bmtagger" != x ]; then 
			echo "bmtagger additional parameters is activated :"
			echo "bmtagger.sh -b /public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/${host}/${host}.bitmask -x /public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/${host}/${host}.srprism \
			-T ${output}/bmtagger_tmp -q 1 -1 $reads_s -o ${output}/$sample.bmtagger.list $add_arg_bmtagger"
			fi
		fi

		bmtagger.sh -b /public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/${host}/${host}.bitmask -x /public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/${host}/${host}.srprism \
		-T ${output}/bmtagger_tmp -q 1 -1 $reads_s -o ${output}/$sample.bmtagger.list $add_arg_bmtagger

		if [[ $? -ne 0 ]]; then
			echo "Something went wrong with running Bmtagger! Exiting."
		else
			if [[ ! -s ${output}/${sample}.bmtagger.list ]]; then echo "No contamination reads found, which is very unlikely."; 
			else 
			contamination=$(cat ${output}/${sample}.bmtagger.list | wc -l)
			echo "$contamination contamination sequences are detected by bmtagger"
			fi
		fi
	# acording bmtagger.list to filter trimed sequences 
	filter_host.py -i $reads_s -t ${output}/$sample.bmtagger.list -f fastq -o clean > ${output}/${sample}.clean.fastq
	filter_host.py -i $reads_s -t ${output}/$sample.bmtagger.list -f fastq -o host > ${output}/${sample}.host.fastq
	reads_s=${output}/${sample}.clean.fastq
	fi

	echo "#########################################################################################################"
	echo "########################                 MAKING POST-QC REPORT                   ########################"
	echo "#########################################################################################################"
	mkdir ${output}/post-QC_report
	if [ x"$parameters" != x ]; then 
		add_arg_fastqc=$(custom_params.py -i $parameters -n fastqc)
		if [ x"$add_arg_fastqc" != x ]; then 
			echo "post-fastqc additional parameters is activated :"
			echo "fastqc  -t $thread -o ${output}/pre-QC_report -f fastq $reads_s $add_arg_fastqc"
		fi
	fi
	fastqc  -t $thread -o ${output}/post-QC_report -f fastq $reads_s $add_arg_fastqc
	if [ $? -ne 0 ]; then echo "Something went wrong with making post-QC fastqc report. Exiting."; fi


	echo "#########################################################################################################"
	echo "########################              READ QC PIPELINE COMPLETE!!!              #########################"
	echo "#########################################################################################################"

fi













