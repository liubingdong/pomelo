#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pandas as pd
import argparse


parser = argparse.ArgumentParser(prog='humann2_biom_filter.py',

    description='''\
      humann2_biom_filter.py version 1.0
      --------------------------------------------------------------------------------
      humann2_biom_filter.py is a self-develped script which
      help transform humann2 taxonomy results into biom format for qiime1 analysis. 
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',
    epilog='''
Usage:
humann2_biom_filter.py -i merge_table.tsv -o otu_table.tsv
''', formatter_class=argparse.RawDescriptionHelpFormatter)

parser.add_argument('-i', '--input', metavar='PATH', required=True, type=str,
                    help='Input merge_table from humann2 results.')

parser.add_argument('-o', '--output', metavar='PATH', required=True, type=str,
                    help='Output biom table for qiime1.')
def main():
   args = parser.parse_args()
   data=pd.read_csv(args.input,sep='\t')
   data['taxonomy']=data['#SampleID']
   data['taxonomy'].replace('\|' ,';',inplace =True,regex=True)
   tax=data['taxonomy']
   tax_filter=[]
   for i in range(len(tax)-1):
       if tax[i] not in tax[i+1]:
           tax_filter.append(tax[i])
   tax_filter.append(tax[len(tax)-1])
   data2=pd.DataFrame(columns=data.columns)
   for i in range(len(tax_filter)):
       data2=data2.append(data.loc[data['taxonomy']==tax_filter[i],:])
   # 修改第一列索引 
   spid=[]
   for i in range(1,len(tax_filter)+1):
       spid.append('tax_'+str(i))
   data2['#SampleID']=spid
   # 这里需要进行倍数扩大，不然下游计算会因为省略小数点后的数字而出现错误
   # 注意先剥离字符串的列
   data3=data2.drop(columns = ['#SampleID','taxonomy'])
   data3=data3*100000
   # 放大后，在添加回原有剥离的字符串了列
   data3.insert(column='#SampleID',value=data2['#SampleID'],loc=0)
   data3['taxonomy']=data2['taxonomy']
   data3.to_csv(args.output,index=False,sep='\t')
if __name__ == "__main__":
    main()
