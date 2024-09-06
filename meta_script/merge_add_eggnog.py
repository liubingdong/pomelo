#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pandas as pd
import numpy as np
import os
import argparse


parser = argparse.ArgumentParser(prog='merge_add_eggnog',
    description='''\
      --------------------------------------------------------------------------------
      merge_add_eggnog.py is designed to 
      merge results generated from EggNog and addtional databases such as ARDB,VFDB,etc.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
merge_add_eggnog.py -1 add_database_anotation dir -2 eggnog_database_anotation file -o final.tsv 

''', formatter_class=argparse.RawDescriptionHelpFormatter)


parser.add_argument('-1', '--input1', required=True, type=str,
                    help='Input table containing each contig function annotations generated from diamond.')
parser.add_argument('-2', '--input2', required=False, type=str,
                    help='Input table containing each contig function annotations generated from emapper.')
parser.add_argument('-o', '--output', required=True, type=str,
                    help='Final table including mutiple function annotations.')


def main ():
    args = parser.parse_args()
    
    # first combine all add_database annotations in each sample
    files1=os.listdir(args.input1)
    new_data=[]
    for i in files1:
      against_seq=i.split('.')[1]
      data=pd.read_csv(os.path.join(args.input1,i),sep='\t',header=0)
      data.rename(columns={'sseqid':against_seq}, inplace = True)
      data_sub=data[['#query_name',against_seq]]
      new_data.append(data_sub)
    if len(new_data)==1:
        adddata_merge=new_data[0]
    elif len(new_data)==2:
        adddata_merge=pd.merge(new_data[0], new_data[1], on='#query_name', how='outer')
        adddata_merge=adddata_merge.fillna('None').sort_values(by='#query_name').reset_index(drop=True)
    elif len(new_data)>2:
            adddata_merge=pd.merge(new_data[0], new_data[1], on='#query_name', how='outer')
            for i in range(2,len(new_data)):
                try:
                    adddata_merge=pd.merge(adddata_merge, new_data[i], on='#query_name', how='outer')
                except:
                    break
    adddata_merge=adddata_merge.fillna('None').sort_values(by='#query_name').reset_index(drop=True)
    try:
      # combie add_data annotations with eggnog_data annotations
      eggnog_data=pd.read_csv(args.input2,sep='\t',skiprows=[0,1,2])
      eggnog_data=eggnog_data[:-3]
      final_data=pd.merge(adddata_merge, eggnog_data, on='#query_name', how='outer')
      final_data=final_data.fillna('None').sort_values(by='#query_name').reset_index(drop=True)
      final_data.to_csv(args.output,sep='\t',index=False)
    except:
      adddata_merge.to_csv(args.output,sep='\t',index=False)
if __name__ == "__main__":
    main()



