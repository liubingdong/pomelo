#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pandas as pd
import numpy as np
import os
import argparse


parser = argparse.ArgumentParser(prog='add_description.py',
    description='''\
      --------------------------------------------------------------------------------
      add_descriptions.py is designed to 
      add description according to identifier and databases.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
add_description.py -i input_dir -a KO_info.tsv -o out_dir
add_description.py -i input_file -a KO_info.tsv -o out_file

''', formatter_class=argparse.RawDescriptionHelpFormatter)



parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input tables containing each samples function annotations.')
parser.add_argument('-o', '--output', required=False, type=str,
                    help='Output tables dir when input is a directory containing multiple tables.')
parser.add_argument('-a', '--against', required=True, type=str,
                    help='Information of data annotation.')



def main ():
    args = parser.parse_args()
    if os.path.isdir(args.input):
      try:
        os.mkdir(args.output)
      except:
        print args.output+' is existed'
      info =pd.read_csv(args.against,header=None,sep='\t')
      info.columns=['index','Descrption']
      file=os.listdir(args.input)
      for i in file:
        file_name=os.path.splitext(i)[0]
        data=pd.read_csv(os.path.join(args.input,i),sep='\t',header=0)
        merge_data=pd.merge(data,info,how='left',on='index')
        outpath=os.path.join(args.output,os.path.splitext(i)[0]+'_des'+os.path.splitext(i)[1])
        merge_data['Descrption']=merge_data['Descrption'].fillna('Unannotated')
        merge_data.to_csv(outpath,sep='\t',index=False)
    elif os.path.isfile(args.input):
      info =pd.read_csv(args.against,header=None,sep='\t')
      info.columns=['index','Descrption']
      data=pd.read_csv(args.input,sep='\t',header=0)
      merge_data=pd.merge(data,info,how='left',on='index')
      outpath=os.path.join(os.path.splitext(args.input)[0]+'_des'+os.path.splitext(args.input)[1])
      merge_data['Descrption']=merge_data['Descrption'].fillna('Unannotated')      
      merge_data.to_csv(outpath,sep='\t',index=False)
    else:
      print 'Input should be tsv or txt tables or directory containing files.Plz check!'
    
if __name__ == "__main__":
    main()










