#!/bin/sh

help_message () {
	echo "------------------------------------------------------------------------------------------------------------"
	echo "parallel_function_quasi_table.sh is meant to generate function annotation for metagenomeic analysis."
	echo "Usage: parallel_function_quasi_table.sh -i quansi_data -t 10 -f CAZy -q NumReads -o CAZy_num.ts"
	echo " "
	echo " "


	echo "Options:"
	echo ""
	echo "	-i  STR                   Input directory containing each sample function annotations"
	echo "	-o  Path                  Generated results directory" 
	echo "	-f  STR                   feature which you want to estimate among the function annotations."
	echo "	-q  STR                   Select the quantities method generated from salmon.[NumReads,TPM]"
	echo "	-t  STR                   Number of thread (default=1)"
	echo "	--biom                    Output the biom format.[default:False]"	
	echo "	--relab                   Output relative abundance output.[default:False]"
	echo "	-h  STR                   Help information"		
	echo "------------------------------------------------------------------------------------------------------------";}
 
 # load in params
OPTS=`getopt -o i:o:f:q:t:h --long help,biom,relab -- "$@"`

# make sure the params are entered correctly
if [ $? -ne 0 ]; then help_message; exit 1; fi

# default params
thread=1

while true; do
	case "$1" in
		-i) input=$2 shift 2;;
		-o) output=$2 shift 2;;
		-f) feature=$2 shift 2;;
		-q) quanti=$2 shift 2;;
		-t) thread=$2 shift 2;;
		-h | --help) help_message; exit 1; shift 1;;
		--biom ) biom=\-b; shift 1;;
		--relab ) relab=\-r; shift 1;;
		*) help_message;break ;;
	esac
done

temp_dir=$(openssl rand -hex 5)
assign_samples.py -i $input -n $thread -o $temp_dir
file_dir=$(ls -A $temp_dir)
mkdir -p ${temp_dir}/temp_total

command="parallel -k -j $thread --load 100% --memfree 1G  ::: "
for F in $file_dir;do
        command="$command \"function_quasi_table.py -i ${temp_dir}/$F -o ${temp_dir}/temp_total/$F.$feature.tsv -q $quanti -f $feature\""
done
command="$command ;"
eval $command


if [ x"$biom" != x ] && [ y"$relab" != y ]; then
	echo '--relab and --biom are not allowed to co-exist!'
elif [ x"$biom" = x ] && [ y"$relab" != y ]; then
	pure_merge_table.py -i ${temp_dir}/temp_total/ -o $output -n index --relab
elif [ x"$biom" != x ] && [ y"$relab" = y ]; then
	pure_merge_table.py -i ${temp_dir}/temp_total/ -o $output -n index --biom
elif [ x"$biom" = x ] && [ y"$relab" = y ]; then
	pure_merge_table.py -i ${temp_dir}/temp_total/ -o $output -n index
fi

# filter some str for downstream
sed -i 's/ko://g' $output

rm -rf $temp_dir




