#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pandas as pd
import numpy as np
import os
import collections
import argparse


parser = argparse.ArgumentParser(prog='function_table_trans.py',
    description='''\
      --------------------------------------------------------------------------------
      function_table_trans.py is designed to 
      transform function merge table generated from function_quasi_table.py into biom or relab format.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
function_table_biom.py -i function.txt -o function.biom 
function_table_biom.py -i function.txt -o function_relab.txt -r 
''', formatter_class=argparse.RawDescriptionHelpFormatter)



parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input function merge table generated from function_quasi_table.py')
parser.add_argument('-o', '--output', required=True, type=str,
                    help='Output unction merge table in biom format for down-stream analysis.')
parser.add_argument('-b', '--biom',action="store_true",required=False,
                    help='Output the biom format.[default:False]')
parser.add_argument('-r', '--relab',action="store_true",required=False,
                    help='Select the relative abundance.[default:False]')


def main ():
    args = parser.parse_args()
    data=pd.read_csv(args.input,sep='\t')

    if args.biom==True and args.relab==False :
        # modify the format to match the biom
        # Below is different from merge_table.py
        data=pd.read_csv(args.input,sep='\t')
        data=data.rename(columns={'index':'OTU ID'})
        data.insert(data.shape[1],'taxonomy',data['OTU ID'])
        data.to_csv('merge_temp.txt',sep='\t',index=False)
        os.system("sed -i -e '1i # Constructed from biom file' -e 's/index/taxonomy/g' -e 's/ko://g' -e 's/OTU ID/\#OTU ID/g' merge_temp.txt")
        os.system("biom convert -i merge_temp.txt --to-hdf5 --table-type='OTU table' --process-obs-metadata taxonomy -o " +  args.output)
        os.system("rm -rf merge_temp.*")
    elif args.biom==True and args.relab==True :
            print '--relab and --biom are not allowed to co-exist!'
    elif args.biom==False and args.relab==True :
        name=data.columns.values.tolist()
        del name[0]
        for i in name:
            sum=data[i].sum()
            data[i]=data[i]/sum
        data.to_csv(args.output,sep='\t',index=False)
 

if __name__ == "__main__":
    main()

