#!/bin/bash

help_message () {
	echo "------------------------------------------------------------------------------------------------------------"
	echo "fuction.sh is meant to generate function annotation for metagenomeic analysis."
	echo "Usage: "
	echo "function.sh -i input dir -d1 eggnog dir -d2 additional databases dir  -o output_dir  -t 4 -m sensitive"	
	echo "Here is the pipeline detaided information,and users are allowed to set addtional each one below in parameters file:"
	echo " ----------             --------               ----------------               -------              --------"
	echo "|input_data| --------》| prodigal | --------》| emapper/diamond | --------》 | Salmon | --------》| output |  "
	echo " ----------             --------               ----------------               -------              --------"
	echo " "
	echo " "


	echo "Function anotation generate options:"
	echo ""
	echo "	-i  STR                   Query data in fasta format"
	echo "	-a  STR                   Original sequences data for salmon quantify"
	echo "	-o  Path                  Generated results directory" 
	echo "	-m  STR                   Selected the diamond method: sensitive(default),more-sensitive,very-sensitive"
	echo "	-t  INT                   Number of thread (default=1)"
	echo "	-d1 Path                  EggNOG databases location"
	echo "	-d2 Path                  Additional databases location"
	echo "	-e  STR                   Threshold which you want select evalue result bigger than.[default: 0.0001]"
	echo "	-s  STR                   Threshold which you want select score result bigger than.[default: 60]"
	echo "	-p  STR                   Parameters file"
	echo "	-h  STR                   Help information"

	echo "   "
	echo "   "
	echo "Function anotation summary options:"
	echo ""
	echo "	-f  STR                   Specfic anotation which you want to estimate among the function annotations."	
	echo "	-q  STR                   Select the quantities method generated from salmon.[TPM,NumReads]"	
	echo "	-b  STR                   Output the biom format.[default:False]"	
	echo "	-r  STR                   Select the relative abundance.[default:False]"	
	echo "	-p  STR                   Parameters file"
	echo "	-h  STR                   Help information"
	echo "	--biom                    Output the biom format.[default:False]"	
	echo "	--relab                   Add the relative abundance output.[default:False]"	
	echo "	--feature-mode-only       This mode will skip all steps before Function anotation summary"	
	echo "------------------------------------------------------------------------------------------------------------";}
 
 # load in params
OPTS=`getopt -o i:a:o:m:t:d1:d2:e:s:f:q:p:h --long help,biom,relab,feature-mode-only -- "$@"`

# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

# default params
thread=1; method=sensitive; evalue=0.00001; score=60; feature_mode=False

while true; do
	case "$1" in
		-i) input=$2 shift 2;;
		-a) seqdata=$2 shift 2;;
		-o) output=$2 shift 2;;
		-m) method=$2 shift 2;;
		-t) thread=$2 shift 2;;
		-d1) eggnog_database=$2 shift 2;;
		-d2) additional_database=$2 shift 2;;
		-e) evalue=$2 shift 2;;
		-s) score=$2 shift 2;;
		-f) feature=$2 shift 2;;
		-q) quanti=$2 shift 2;;
		-p) parameters=$2 shift 2;;	
		-h | --help) help_message; exit 1; shift 1;;
		--biom ) biom=\-b; shift 1;;
		--relab ) relab=\-r; shift 1;;
		--feature-mode-only ) feature_mode=true; shift 1;;
		*) help_message;break ;;
	esac
done


if [ "$feature_mode" = true ]; then
	echo "########################################################################################################"
	echo "########################         Function anotation generate skipped          ##########################"
	echo "########################################################################################################"
else
	echo "########################################################################################################"
	echo "########################         Function anotation generate started          ##########################"
	echo "########################################################################################################"

	echo "########################################################################################################"
	echo "########################                 ORF prediction start                 ##########################"
	echo "########################################################################################################"


	mkdir -p ${output}/ORF

	if [ x"$parameters" != x ]; then 
		add_arg_prodigal=$(custom_params.py -i $parameters -n prodigal)
		echo "prodigal additional parameters is activated :"
		echo $add_arg_prodigal
	fi




	command="parallel -k -j $thread --load 100% --memfree 1G  ::: "
	for F in $input/*.fa; do
	        BASE=${F##*/}
	        SAMPLE=${BASE%%_*}
	        command="$command \"prodigal -i $F -o ${output}/ORF/${SAMPLE}.gene.coords.gbk -a ${output}/ORF/${SAMPLE}.faa $add_arg_prodigal -d ${output}/ORF/${SAMPLE}.ffn $add_arg_prodigal\""
	done
	command="$command ;"
	eval  $command

	if [ $? -ne 0 ]; then 
		echo "########################################################################################################"
		echo "########################                 ORF prediction Error                     ######################"
		echo "########################################################################################################"
	else
		echo "########################################################################################################"
		echo "########################                 ORF prediction Completed                 ######################"
		echo "########################################################################################################"
	fi



	if [ x"$eggnog_database" != x ]; then 
		echo "########################################################################################################"
		echo "########################                 eggNOG prediction start              ##########################"
		echo "########################################################################################################"

		if [ x"$parameters" != x ]; then 
			add_arg_emapper=$(custom_params.py -i $parameters -n emapper)
			echo "emapper additional parameters is activated :"
			echo $add_arg_emapper
		fi

		mkdir -p ${output}/function_anotation/EggNOG
		for F in ${output}/ORF/*.faa; do
		        BASE=${F##*/}
		        SAMPLE=${BASE%%.*}
		        mkdir -p ${output}/function_anotation/EggNOG/$SAMPLE
		        emapper.py -i $F --output_dir ${output}/function_anotation/EggNOG/$SAMPLE -m diamond --cpu $thread --data_dir $eggnog_database -o $SAMPLE --seed_ortholog_evalue $evalue --seed_ortholog_score $score   $add_arg_emapper
		done

		if [ $? -ne 0 ]; then 
			echo "########################################################################################################"
			echo "########################                 EggNOG prediction Completed              ######################"
			echo "########################################################################################################"
		else
			echo "########################################################################################################"
			echo "########################                 EggNOG prediction Error                  ######################"
			echo "########################################################################################################"
		fi
	else
		echo "########################################################################################################"
		echo "########################                 EggNOG prediction skipped                ######################"
		echo "########################################################################################################"
	fi



	if [ x"$additional_database" != x ]; then
		echo "########################################################################################################"
		echo "########################           Additional databases prediction start          ######################"
		echo "########################################################################################################"
		mkdir -p ${output}/function_anotation/addtional_database
		for F in $additional_database/*; do
		        BASE_name=${F##*/}
		        additional_database_name=${BASE_name%%.*}
		        for K in ${output}/ORF/*.faa; do 
		        	BASE_name1=${K##*/}
					SAMPLE=${BASE_name1%%.*}
		        	if [ x"$parameters" != x ]; then
		        		single_function.sh -i $K -d $F -o ${output}/function_anotation/addtional_database/addtional_anotation/${SAMPLE} -t $thread -m sensitive -e $evalue -s $score -p $parameters
		        	else
		        		single_function.sh -i $K -d $F -o ${output}/function_anotation/addtional_database/addtional_anotation/${SAMPLE} -t $thread -m sensitive -e $evalue -s $score
		        	fi
		        done
		done
		
		mkdir -p ${output}/function_anotation/addtional_database/addtional_temp
		find ${output}/function_anotation/addtional_database/addtional_anotation/ -name "*raw.tsv" -exec mv '{}' ${output}/function_anotation/addtional_database/addtional_temp ';'
		find ${output}/function_anotation/addtional_database/addtional_anotation/ -name "*.dmnd" | xargs  rm


		if [ $? -ne 0 ]; then 
			echo "########################################################################################################"
			echo "########################           Additional databases prediction Error          ######################"
			echo "########################################################################################################"
		else
			echo "########################################################################################################"
			echo "########################           Additional databases prediction Completed      ######################"
			echo "########################################################################################################"
		fi
	else
		echo "########################################################################################################"
		echo "########################           Additional databases prediction skipped        ######################"
		echo "########################################################################################################"
	fi


	echo "########################################################################################################"
	echo "########################              Function anotation combination start         #####################"
	echo "########################################################################################################"


	mkdir -p ${output}/function_anotation/final_anotation/



	if [ x"$eggnog_database" != x ] && [ y"$additional_database" != y ]; then
		for F in ${output}/ORF/*.ffn; do
	        BASE=${F##*/}
	        SAMPLE=${BASE%%.*}
	       	merge_add_eggnog.py -1 ${output}/function_anotation/addtional_database/addtional_anotation/${SAMPLE} -2 ${output}/function_anotation/EggNOG/${SAMPLE}/${SAMPLE}.emapper.annotations \
	       	-o ${output}/function_anotation/final_anotation/${SAMPLE}.function.tsv
		done
	elif [ x"$eggnog_database" != x ] && [ y"$additional_database" = y ]; then
		for F in ${output}/ORF/*.ffn; do
	        BASE=${F##*/}
	        SAMPLE=${BASE%%.*}
	        ln -s ${output}/function_anotation/EggNOG/${SAMPLE}/${SAMPLE}.emapper.annotations ${output}/function_anotation/final_anotation/${SAMPLE}.emapper.annotations
	    done
	elif [ x"$eggnog_database" = x ] && [ y"$additional_database" != y ]; then 
		for F in ${output}/ORF/*.ffn; do
	        BASE=${F##*/}
	        SAMPLE=${BASE%%.*}
	       	merge_add_eggnog.py -1 ${output}/function_anotation/addtional_database/addtional_anotation/${SAMPLE}  \
	       	-o ${output}/function_anotation/final_anotation/${SAMPLE}.function.tsv
	    done
	fi

	if [ $? -ne 0 ]; then 
		echo "########################################################################################################"
	    echo "########################           Function anotation combination error            #####################"
		echo "########################################################################################################"
	else
		echo "########################################################################################################"
	    echo "########################           Function anotation combination complete         #####################"
		echo "########################################################################################################"
	fi



	echo "########################################################################################################"
	echo "########################                 Salmon quantify start                   #######################"
	echo "########################################################################################################"

	if [ x"$parameters" != x ]; then 
		add_arg_salmon_index=$(custom_params.py -i $parameters -n salmon_index)
		echo "salmon index additional parameters is activated :"
		echo $add_arg_salmon_index
	fi

	command="parallel -k -j $thread --load 100% --memfree 1G  ::: "
	for F in ${output}/ORF/*.ffn; do
	        BASE=${F##*/}
	        SAMPLE=${BASE%%.*}
	        command="$command \"salmon index -t $F -i ${output}/function_index/${SAMPLE}_transcript_index --type quasi -k 31 $add_arg_salmon_index\""
	done

	eval $command


	mkdir -p ${output}/temp/cleandata
	file=$(find $seqdata -name "*clean.fastq")

	if [ x"$seqdata" == x ]; then 
		echo "Plz rename the sequences data in this form eg. A01_1.clean.fastq"
	fi

	for F in $file;do
	        BASE=${F##*/}
	        ln -s $PWD/$F ${output}/temp/cleandata/$BASE
	done


	if [ x"$parameters" != x ]; then 
		add_arg_salmon_quant=$(custom_params.py -i $parameters -n salmon_quant)
		echo "salmon quant additional parameters is activated :"
		echo $add_arg_salmon_quant
	fi


	for F in ${output}/function_index/*; do
	        BASE=${F##*/}
	        SAMPLE=${BASE%%_*}
	        R1=${SAMPLE}_1.clean.fastq
	        R2=${SAMPLE}_2.clean.fastq
	        salmon quant -i $F --libType IU -1 ${output}/temp/cleandata/$R1 -2 ${output}/temp/cleandata/$R2 -o ${output}/salmon_out/$SAMPLE -p $thread $add_arg_salmon_quant
	        mv ${output}/salmon_out/$SAMPLE/quant.sf ${output}/salmon_out/$SAMPLE/${SAMPLE}.quant.sf
	done

	if [ $? -ne 0 ]; then 
		echo "########################################################################################################"
		echo "########################                 Salmon quantify Error                     #####################"
		echo "########################################################################################################"
	else
		echo "########################################################################################################"
		echo "########################                 Salmon quantify complete                  #####################"
		echo "########################################################################################################"
	fi
	echo "########################################################################################################"
	echo "########################         Function anotation generate completed        ##########################"
	echo "########################################################################################################"
fi


if [ "`ls -A ${output}/function_anotation/final_anotation/`" = "" ]; then
	echo "Function anotation generate process was wrong, plz check final_anotation directory!"
else
	echo "########################################################################################################"
	echo "########################            Function anotation summary start          ##########################"
	echo "########################################################################################################"
	mkdir -p ${output}/temp/quansi_data
	for F in $(ls -A ${output}/function_anotation/final_anotation/ );do
	        BASE=${F##*/}
	        final_anotation_path=$(find ${output} -name 'final_anotation')
	        ln -s $PWD/$final_anotation_path/$F ${output}/temp/quansi_data/$BASE
	done

	for F in $(find ${output}/salmon_out/ -name '*sf');do
	        BASE=${F##*/}
	        ln -s $PWD/$F ${output}/temp/quansi_data/$BASE
	done

	cp -r ${output}/temp/quansi_data ${output}/temp/quansi_data_stock

	quanti_array=(${quanti//,/ })
	for var_q in ${quanti_array[@]};do		
		mkdir -p ${output}/function_anotation_summary/${var_q}
		array=(${feature//,/ })
		for var_f in ${array[@]};do
			if [ x"$biom" != x ]; then
				parallel_function_quasi_table.sh -i ${output}/temp/quansi_data_stock/ -f $var_f -q $var_q -o ${output}/function_anotation_summary/${var_q}/${var_f}.${var_q}.biom $biom -t $thread
				echo " "
				echo "File created: ${var_f}.${var_q}.biom has been generated !"
			else
				parallel_function_quasi_table.sh -i ${output}/temp/quansi_data_stock/ -f $var_f -q $var_q -o ${output}/function_anotation_summary/${var_q}/${var_f}.${var_q}.tsv -t $thread
				echo " "
				echo "File created: ${var_f}.${var_q}.tsv has been generated !"
			fi
			# reset the input files, because assign_samples.py of parallel_function_quasi_table.sh will move data
		    rm -rf ${output}/temp/quansi_data_stock/
		    cp -r ${output}/temp/quansi_data ${output}/temp/quansi_data_stock
		done
		if [ x"$relab" != x ] && [ y"$biom" = y ]; then
			for var_f in ${array[@]};do
				function_table_trans.py -i ${output}/function_anotation_summary/${var_q}/${var_f}.${var_q}.tsv -o ${output}/function_anotation_summary/${var_q}/${var_f}.${var_q}_relab.tsv -r 
				echo " "
				echo "File created: ${var_f}.${var_q}_relab.tsv has been generated !"
			done
		fi
	done
	
	rm -rf ${output}/temp/quansi_data_stock

	if [ $? -ne 0 ]; then
		echo "########################################################################################################"
		echo "########################            Function anotation summary error          ##########################"
		echo "########################################################################################################"
	else
		echo "########################################################################################################"
		echo "########################            Function anotation summary completed      ##########################"
		echo "########################################################################################################"
	fi
fi







