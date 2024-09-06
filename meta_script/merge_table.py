#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import pandas as pd
import os
import argparse

parser = argparse.ArgumentParser(prog='merge_table.py',
    description='''\
      --------------------------------------------------------------------------------
      merge_table.py is designed to 
      combine each sample table generated from kaiju into one file in txt or biom format.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
merge_table.py -i input_dir -o merge.txt
merge_table.py -i input_dir -o merge.txt --relab
merge_table.py -i input_dir -o merge.txt --relab -l proka
''', formatter_class=argparse.RawDescriptionHelpFormatter)


parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input directory containing each sample taxonomy generated from kaiju.')
parser.add_argument('-o', '--output', required=True, type=str,
                    help='Merged taxonomy.')
parser.add_argument('-r', '--relab',action="store_true",required=False,
                    help='Select the relative abundance.[default:False]')
parser.add_argument('-l', '--level',required=True,type=str,choices=['proka','vir'],
					help='Split the taxonomy according to prokaryotes and viruses.')
parser.add_argument('-b', '--biom',action="store_true",required=False,
                    help='Output the biom format.[default:False]')
def main ():
	args = parser.parse_args()
	filename=os.listdir(args.input)
	# read each sample taxonomy
	data_proka=[]
	data_viruses=[]
	sample_name=[]
	for i in filename:
		sample_name=i.split('.', 1 )[0]
		data_raw=pd.read_csv(args.input+'/'+i,sep='\t')
		data_sub= data_raw.loc[data_raw["taxon_id"] == data_raw["taxon_id"]]
		data_sub=data_sub.copy()
		data_sub[sample_name]=data_sub['reads']
		data_sub=data_sub[['taxon_name',sample_name]]
		data_sub_proka=data_sub[data_sub['taxon_name'].str.contains('Bacteria;|Archaea;')]
		data_sub_viruses=data_sub[data_sub['taxon_name'].str.contains('Viruses;')]
		data_proka.append(data_sub_proka)
		data_viruses.append(data_sub_viruses)

	if args.level=='proka':
		data=data_proka
	elif args.level=='vir':
		data=data_viruses


	# merge all samples tax from one directory
	if len(data)==2:
		data_merge=pd.merge(data[0], data[1], on='taxon_name', how='outer')
		data_merge=data_merge.fillna(0)
	elif len(data)>2:
		data_merge=pd.merge(data[0], data[1], on='taxon_name', how='outer')
		for i in range(2,len(data)):
			try:
				data_merge=pd.merge(data_merge, data[i], on='taxon_name', how='outer')
			except:
				break
	data_merge=data_merge.fillna(0)
	data_merge_order=data_merge.sort_values(by="taxon_name")
	

	if args.biom==True and args.relab==False :
		# modify the format to match the biom
		data_merge_order['OTU ID']=range(0,data_merge_order.shape[0])
		colnames=data_merge_order.columns.values.tolist()
		del(colnames[0],colnames[-1])
		colnames.insert(0,'OTU ID')
		colnames.append('taxon_name')
		data_merge_order=data_merge_order[colnames]
		data_merge_order.to_csv('merge_temp.txt',sep='\t',index=False)
		os.system("sed -ig -e '1i # Constructed from biom file' -e 's/taxon_name/taxonomy/g' -e 's/OTU ID/\#OTU ID/g' merge_temp.txt")
		os.system("biom convert -i merge_temp.txt --to-hdf5  --process-obs-metadata taxonomy -o " + args.output)
		os.system("rm -rf merge_temp.*")
	elif args.biom==True and args.relab==True :
		print '--relab and --biom are not allowed to co-exist!'
	else:
		# select absolute or relative abundance
		if args.relab==True:
			sample_name=[]
			sum_order=[]
			for i in range(0,len(data)):
				sample_name.append(filename[i].split('.', 1 )[0])
				sum_order=data_merge_order[sample_name[i]].sum()
				data_merge_order[sample_name[i]]=data_merge_order[sample_name[i]]/sum_order

			data_merge_order.to_csv(args.output,sep='\t',index=False)
		else:
			data_merge_order.to_csv(args.output,sep='\t',index=False)


if __name__ == "__main__":
	main()

