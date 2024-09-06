#!/bin/bash
VERSION="0.99"

help_message () {
    echo""
	echo "Usage: metaWRAP [module]"
	echo ""
    echo "	Modules:"
	echo "	read_qc		Raw read QC module (read trimming and contamination removal)"
	echo "	assembly	Assembly module (metagenomic assembly)"
	echo "	taxonomy		Humann2 module (taxonomy annotation of reads and assemblies)"
	echo "	function		Binning module (metabat, maxbin, or concoct)"
	echo "	bin_refinement	Refinement of bins from binning module"
	echo "	reassemble_bins Reassemble bins using metagenomic reads"
	echo "	quant_bins	Quantify the abundance of each bin across samples"
	echo "	classify_bins	Assign taxonomy to genomic bins"
	echo "	annotate_bins	Functional annotation of draft genomes"
	echo ""
	echo "	--help | -h		show this help message"
	echo "	--version | -v	show metaWRAP version"
	echo "	--show-config	show where the metawrap configuration files are stored"
	echo "";}

if [[ $? -ne 0 ]]; then 
	echo "something went wrong with the installation!"
	exit 1
fi


if [ "$1" = "-h" ] || [ "`ls -A ${output}/function_anotation/final_anotation/`" = "" ]; then
	help_message
elif [ "$1" = read_qc ]; then
	time sh read_qc.sh ${@:2}
elif [ "$1" = assembly ]; then
	time humann2 ${@:2}
elif [ "$1" = taxonomy ]; then
	time humann2 ${@:2}
elif [ "$1" = function ]; then
	time humann2 ${@:2}
else
        echo "Please select a proper module."
        help_message
        exit 1
fi




