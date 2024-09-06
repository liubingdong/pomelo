#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pandas as pd
import argparse
import os


parser = argparse.ArgumentParser(prog='function_merge_table.py',
    description='''\
      --------------------------------------------------------------------------------
      pure_merge_table.py is designed to 
      combine tables into one file in txt or biom format.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
pure_merge_table.py -i input_dir -o merge.tsv -n index

''', formatter_class=argparse.RawDescriptionHelpFormatter)



parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input directory containing each sample function annotations.')
parser.add_argument('-o', '--output', required=True, type=str,
                    help='Merged function annotations in tsv or biom format.')
parser.add_argument('-n', '--id',required=False,type=str,default='index',
                    help='Select index for merge.')
parser.add_argument('-b', '--biom',action="store_true",required=False,
                    help='Output the biom format.[default:False]')
parser.add_argument('-r', '--relab',action="store_true",required=False,
                    help='Select the relative abundance.[default:False]')


def main ():
    args = parser.parse_args()
    file_merge=os.listdir(args.input)
    newdata=[]
    for i in file_merge:
      data_temp=pd.read_csv(os.path.join(args.input,i),sep='\t',low_memory=False )
      newdata.append(data_temp)
    if len(newdata)==1:
      newdata_merge=newdata[0]
    elif len(newdata)==2:
      newdata_merge=pd.merge(newdata[0], newdata[1], on=args.id, how='outer')
      newdata_merge=newdata_merge.fillna(0)
    elif len(newdata)>2:
      newdata_merge=pd.merge(newdata[0], newdata[1], on=args.id, how='outer')
      for i in range(2,len(newdata)):
          try:
              newdata_merge=pd.merge(newdata_merge, newdata[i], on=args.id, how='outer')
          except:
              break
    newdata_merge=newdata_merge.fillna(0).sort_values(by=args.id).reset_index(drop=True)  
    
    if args.biom==True and args.relab==False :
        # modify the format to match the biom
        # Below is different from merge_table.py
        newdata_merge=newdata_merge.rename(columns={args.id:'OTU ID'})
        newdata_merge.insert(newdata_merge.shape[1],'taxonomy',newdata_merge['OTU ID'])
        newdata_merge.to_csv('merge_temp.txt',sep='\t',index=False)
        os.system("sed -i -e '1i # Constructed from biom file' -e 's/index/taxonomy/g' -e 's/ko://g' -e 's/OTU ID/\#OTU ID/g' merge_temp.txt")
        os.system("biom convert -i merge_temp.txt --to-hdf5 --table-type='OTU table' --process-obs-metadata taxonomy -o " +  args.output)
        os.system("rm -rf merge_temp.*")
    elif args.biom==True and args.relab==True :
            print '--relab and --biom are not allowed to co-exist!'
    elif args.biom==False and args.relab==True :
        name=newdata_merge.columns.values.tolist()
        del name[0]
        for i in name:
            sum=newdata_merge[i].sum()
            newdata_merge[i]=newdata_merge[i]/sum
        newdata_merge.to_csv(args.output,sep='\t',index=False)
    else:
        newdata_merge.to_csv(args.output,sep='\t',index=False)

if __name__ == "__main__":
    main()
    