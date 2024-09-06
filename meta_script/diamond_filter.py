#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pandas as pd
import numpy as np
import os
import argparse


parser = argparse.ArgumentParser(prog='diamond_filter',
    description='''\
      --------------------------------------------------------------------------------
      diamond_filter.py is designed to 
      select final results from diamond output according to specific condition.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
diamond_filter.py -i C1_card.tab -o C1_final.tsv -s 60  -e 0.00001

''', formatter_class=argparse.RawDescriptionHelpFormatter)



parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input table containing each contig function annotations generated from diamond.')
parser.add_argument('-o', '--output', required=True, type=str,
                    help='Final table according to specific condition.')
parser.add_argument('-s', '--score', required=False, type=str,default=60,
                    help='Threshold which you want select score result bigger than.[default: 60]')
parser.add_argument('-e', '--evalue', required=False, type=str,default=0.00001,
                    help='Threshold which you want select evalue result smaller than.[default: 0.00001]')


def get_biggest_score(x):
    df = x.sort_values(by = 'bitscore',ascending=True)
    return df.iloc[-1,:]

def main ():
    args = parser.parse_args()
    data=pd.read_csv(args.input,sep='\t',header=None)
    data.columns = ['#query_name','sseqid','pident','length','mismatch','gapopen','qstart','qend', 'sstart','send','evalue','bitscore']
    data_sub=data.groupby('#query_name',as_index=False).apply(get_biggest_score)
    data_sub_filter=data_sub.loc[(data_sub['bitscore']>float(args.score)) & (data_sub['evalue']<float(args.evalue))]
    data_sub_filter.to_csv(args.output,sep='\t',index=False)

if __name__ == "__main__":
    main()










