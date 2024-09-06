#!/bin/sh

help_message () {
	echo "------------------------------------------------------------------------------------------------------------"
	echo "taxonomy_plot.sh is meant to perform classic microbial data analysis based on kaiju result."
	echo "Usage: "
	echo "taxonomy.sh -i kaiju_table  -o output_dir  -m mapping.txt -p parameters"	
	echo "Here is the pipeline detaided information,and users are allowed to set addtional each one below in parameters file:"
	#echo " ----------             --------------------------------              ---------------------             ------  "
	#echo "|input_data| --------》| summarize_taxa_through_plots.py | --------》| alpha_rarefaction.py | --------》| ouput | "
	#echo " ----------             --------------------------------              —————----------------              ——————  "
	echo " "
	echo " "


	echo "Options:"
	echo ""
	echo "	-i Path             Directory containg samples abundance tables in tsv format"
	echo "	-o Path             Generated results directory" 
	echo "	-t INT              number of thread (default=1)"
	echo "	-m STR              mapiing file"
	echo "	-p STR              parameters file"
	echo "	-h STR              help information"
	echo "	--simple_mode STR   Skip advanced plot"
	echo "	--test_mode STR     Only for test plot "
	echo "------------------------------------------------------------------------------------------------------------";}

# load in params
OPTS=`getopt -o i:o:t:m:p:h --long help,simple_mode,test_mode -- "$@"`

# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

# default params
thread=1; level=proka; x=0.001; single=false; test=false

while true; do
	case "$1" in
		-i) input=$2 shift 2;;
		-o) output=$2 shift 2;;
		-t) thread=$2 shift 2;;
		-m) mapping=$2 shift 2;;	
		-p) parameters=$2 shift 2;;	
		-h | --help) help_message; exit 1; shift 1;;
		--simple_mode) simple=true; shift 1;;
		--test_mode) test=true; shift 1;;
		*) help_message;break ;;
	esac
done

if [ "$test" = false ]; then 
	mkdir -p ${output}/
	merge_table.py -i $input -o ${output}/all_samples_taxonomy.biom  -l proka --biom


	filter_otus_from_otu_table.py -i ${output}/all_samples_taxonomy.biom -o ${output}/all_samples_taxonomy_mc2.biom -n 2

	biom summarize-table -i ${output}/all_samples_taxonomy_mc2.biom -o ${output}/biom.summary

	#min_num=$(cat ${output}/biom.summary | awk 'NR==7 {split($2,arr,":");print arr[1]}'| awk 'NR==1 {split($1,arr,".");print arr[1]}' | sed "s/\,//g")

	#single_rarefaction.py -i ${output}/all_samples_taxonomy_mc2.biom  -o ${output}/all_samples_taxonomy_mc2_even.biom  -d $min_num

	cat $mapping | awk 'NR!=1 {split($1,arr,":");print arr[1]}'>${output}/ID.txt

	filter_samples_from_otu_table.py -i ${output}/all_samples_taxonomy_mc2.biom  -o ${output}/samples_taxonomy_raw.biom --sample_id_fp ${output}/ID.txt

	filter_otus_from_otu_table.py -i ${output}/samples_taxonomy_raw.biom -o ${output}/samples_taxonomy_mc1.biom -n 1

	sort_otu_table.py -i ${output}/samples_taxonomy_mc1.biom -o ${output}/samples_taxonomy_even.biom -l ${output}/ID.txt



	if [ x"$parameters" == x ]; then 
		summarize_taxa.py -i ${output}/samples_taxonomy_even.biom -o ${output}/result/taxon_summarize_relative/ -L 2,3,4,5,6,7 -m $mapping
		summarize_taxa.py -i ${output}/samples_taxonomy_even.biom -o ${output}/result/taxon_summarize_absolute/ -L 2,3,4,5,6,7 -m $mapping \
		--absolute_abundance

		summarize_taxa_through_plots.py \
		-i ${output}/samples_taxonomy_even.biom \
		-o ${output}/result/taxa_summary_plots_each 

		summarize_taxa_through_plots.py \
		-i ${output}/samples_taxonomy_even.biom \
		-o ${output}/result/taxa_summary_plots_Group \
		-m $mapping -c Group

		alpha_rarefaction.py -i ${output}/samples_taxonomy_even.biom -o ${output}/result/alpha_output_folder \
		-m $mapping  --parallel -aO $thread

		beta_diversity_through_plots.py -i ${output}/samples_taxonomy_even.biom -o ${output}/result/bdiv_plots/ \
		-m $mapping  --parallel -aO $thread

	elif [ x"$parameters" != x ]; then

		summarize_taxa.py -i ${output}/samples_taxonomy_even.biom -o ${output}/result/taxon_summarize_relative/ -L 2,3,4,5,6,7 -m $mapping
		summarize_taxa.py -i ${output}/samples_taxonomy_even.biom -o ${output}/result/taxon_summarize_absolute/ -L 2,3,4,5,6,7 -m $mapping \
		--absolute_abundance


		summarize_taxa_through_plots.py \
		-i ${output}/samples_taxonomy_even.biom \
		-o ${output}/result/taxa_summary_plots_each -p $parameters

		summarize_taxa_through_plots.py \
		-i ${output}/samples_taxonomy_even.biom \
		-o ${output}/result/taxa_summary_plots_Group \
		-m $mapping -c Group -p $parameters 

		alpha_rarefaction.py -i ${output}/samples_taxonomy_even.biom -o ${output}/result/alpha_output_folder \
		-m $mapping  -p $parameters --parallel -aO $thread

		beta_diversity_through_plots.py -i ${output}/samples_taxonomy_even.biom -o ${output}/result/bdiv_plots/ \
		-m $mapping  -p $parameters --parallel -aO $thread

	fi
else
	echo "Test mode has been activated "
fi

if [ "$single" = true ]; then 
	echo "simple mode has been activated "
elif [ "$single" = false ]; then
	# obtain plot r script first
	cp -rf /public/home/liubd/workplace/meta_workspace/Sample/direct ${output}/result/
	cp -rf $mapping ${output}/result/
	sed -i 's/#//g' ${output}/result/mapping.txt
	cd ${output}/result/direct
	sh auto.sh
fi










