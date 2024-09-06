#!/bin/sh

help_message () {
  echo "------------------------------------------------------------------------------------------------------------"
  echo "set_value.sh is meant to modified necessary profile for metagenomeic analysis."
  echo "Usage: "
  echo "set_value.sh -i Setting_profile -1 kaiju_method -2 greedy"  
  echo "set_value.sh -i Setting_profile -1 quality_control -2 20"  
  echo " "
  echo " "


  echo "Options:"
  echo ""
  echo "  create            Create Setting profile including parameters for pipeline "
  echo "  info              Show parameters value table "
  echo "  -1 STR            Pipeline parameters name "
  echo "  -2 STR            Pipeline parameters value"
  echo "  -h STR            help information"
  echo "------------------------------------------------------------------------------------------------------------";}
 


#default function
create_default_file() {
echo -e "------ Easy Metagenomics Necessaries ------
Running settings
workspace_location=
input_data=
threads=30
parameters_file=
Data repository
bmtagger_databases=/public/home/liubd/soft_ware/metaWRAP/BMTAGGER_INDEX/
kaiju_databases=/public/home/liubd/soft_ware/kaiju/kaiju/kaijudb/
EggNog_databases=/public/home/liubd/soft_ware/eggNOG/
add_databases=/public/home/liubd/soft_ware/add_data/
Read QC section
quality_control=20
host_contamination=hg38
single-read_mode=No
skip-trimming=No
skip-bmtagger=No
more details infomation=read_qc.sh --help
Taxonomy profile section
kaiju_method=greedy
kaiju_min_abundance=0.1
single_read_mode=No
expand_virus_mode=No
more details infomation=taxonomy.sh --help
Assemble section
assemble_method=megahit
single_end_mode=No
paired_end_mode=No
more details infomation=assembly.sh --help
Function anotation section
diamond_method=sensitive
diamond_evalue=0.0001
diamond_escore=60
feature_select=CARD,VFDB,CAZy,EC,GOs,KEGG_ko
quantify_method=TPM,NumReads
biom_fomat=No
add_relab_format=Yes
more details infomation=fucntion.sh --help" > Setting_profile.tsv
}


yes_no(){
while true
do
    read -r -p "$1 [Y/n] " input

        case $input in
            [yY][eE][sS]|[yY])
                        ans="Yes"
                        break
                        ;;

            [nN][oO]|[nN])
                        ans="No"
                        break
                        ;;

            *)
                        echo "Invalid input..."
                        ;;
        esac
done
}

set_key_value() {
  local key=${1}
  local value=${2}
  if [ -n $value ]; then
    #echo $value
    local current=$(sed -n -e "s/^\($key = \)\([^ ']*\)\(.*\)$/\2/p" $CONF) # value不带单引号
    if [ -n $current ];then
      echo "Modifing $CONF : $key=$value"
      value="$(echo "${value}" | sed 's|[&]|\\&|g')"
      sed -i "s|^[#]*[ ]*${key}\([ ]*\)=.*|${key}=${value}|" ${CONF}
    fi
  fi
}



# prepare the Setting_profile
if [ "$1" = "create" ]; then
  if [ -f Setting_profile.tsv ]; then
    echo 'Setting_profile.tsv already exists.' 
    yes_no 'Do you want to replace it with default?'
    if [ $ans = Yes ]; then
      create_default_file
      echo 'Setting_profile.tsv has been replaced with default.'
    elif [ $ans = No ]; then
      echo 'Setting_profile.tsv will keep'
    fi
  elif [ ! -f Setting_profile.tsv ]; then
    echo 'Setting_profile.tsv has created.'
    create_default_file
  fi
elif [ "$1" = "info" ]; then
  if [ -f Setting_profile.tsv ]; then
    sed 's/\=/\t/g' Setting_profile.tsv |create_table.sh -15 -red,-white,-blue
  else
    echo "Setting_profile.tsv is not found, please use <set_value.sh create> to build it!"
  fi
else
  OPTS=`getopt -o 1:2:h --long help -- "$@"`
  # make sure the params are entered correctly
  if [ $? -ne 0 ]; then help_message; exit 1; fi
  while true; do
    case "$1" in
      -1) name=$2 shift 2;;
      -2) value=$2 shift 2;;
      -h | --help) help_message; exit 1; shift 1;;
      *) break ;;
    esac
  done
  if [ -f Setting_profile.tsv ]; then  
    CONF='Setting_profile.tsv'
    list=$(grep -E '=' Setting_profile.tsv | awk  -F '=' '{print $1"\t"$4}')
    for i in ${list[@]}
    do
       [ "$i" = "$name" ] && list_ans='yes'
    done
    if [ x$list_ans = xyes ]; then
      if [ x"$name" != x ] && [ y"$value" != y ]; then
        set_key_value $name $value
        echo "Parameter has been changed successfully!  "
      else
        echo "No parameters will change! "
        echo "please check the input parameters! "
      fi
    else
      echo 'Input parameters is not in Setting_profile.tsv, please check!'
    fi
  else
    echo "Setting_profile.tsv is not found, please use <set_value.sh create> to build it!"
  fi
fi


































