#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import pandas as pd
import os
import argparse

parser = argparse.ArgumentParser(prog='split_tax_table.py',
    description='''\
      --------------------------------------------------------------------------------
      split_tax_table.py is designed to 
      split the table generated from summarize_taxa.py in qiime 1.91.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
split_tax_table.py -i mapping_L7 -o output dir

''', formatter_class=argparse.RawDescriptionHelpFormatter)


parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input the table generated from summarize_taxa.py in qiime 1.91.')
parser.add_argument('-o', '--output', required=True, type=str,
                    help='Output the tables.')

def main ():
	args = parser.parse_args()
	data=pd.read_csv(args.input,header=0,sep='\t')
	data = data.drop(['barcode', 'primer','Description','Group'], axis=1) 
	colnames=data.columns.values.tolist()
	sep_num=[]
	for j in colnames:
	    res={}
	    for i in j:
	        if i in res: #表示字符在字符串中出现过，把原来统计的结果加1
	            res[i]+=1
	        else: #表示字符在字符串中第一次出现
	            res[i]=1
	    try:
	        sep_num.append(res[';'])
	    except:
	        sep_num.append(0)
	phylum_id=[]
	class_id=[]
	order_id=[]
	family_id=[]
	genus_id=[]
	species_id=[]
	for i in sep_num:
	    phylum_id.append(i==0 or i==1)
	    class_id.append(i==0 or i==2)
	    order_id.append(i==0 or i==3)
	    family_id.append(i==0 or i==4)
	    genus_id.append(i==0 or i==5)                
	    species_id.append(i==0 or i==6)	

 
	data.loc[:,phylum_id].to_csv(os.path.join(args.output,'phylum.txt') ,sep='\t',index=False)
	data.loc[:,class_id].to_csv(os.path.join(args.output,'class.txt') ,sep='\t',index=False)
	data.loc[:,order_id].to_csv(os.path.join(args.output,'order.txt') ,sep='\t',index=False)
	data.loc[:,family_id].to_csv(os.path.join(args.output,'family.txt') ,sep='\t',index=False)
	data.loc[:,genus_id].to_csv(os.path.join(args.output,'genus.txt') ,sep='\t',index=False)
	data.loc[:,species_id].to_csv(os.path.join(args.output,'species.txt') ,sep='\t',index=False)


if __name__ == "__main__":
	main()

