#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pandas as pd
import numpy as np
import os
import collections
import argparse


parser = argparse.ArgumentParser(prog='function_quasi_table.py',
    description='''\
      --------------------------------------------------------------------------------
      function_quasi_table.py is designed to 
      combine each sample table generated from emapper.py into one file in txt or biom format.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
function_quasi_table.py -i test -o gene.tsv -q TPM -f KEGG_ko
function_quasi_table.py -i test -o gene.tsv -q NumReads -f Preferred_name
function_quasi_table.py -i test -o gene.tsv -q NumReads -f Preferred_name --biom
function_quasi_table.py -i test -o gene.tsv -q NumReads -f Preferred_name --relab
''', formatter_class=argparse.RawDescriptionHelpFormatter)



parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input directory containing each sample function annotations generated from emapper.py.')
parser.add_argument('-o', '--output', required=True, type=str,
                    help='Merged taxonomy.')
parser.add_argument('-f', '--feature',required=True,type=str,
                    help='feature which you want to estimate among the function annotations.')
parser.add_argument('-q', '--quanti',required=True,type=str,choices=['TPM','NumReads'],
                    help='Select the quantities method generated from salmon.')
parser.add_argument('-b', '--biom',action="store_true",required=False,
                    help='Output the biom format.[default:False]')
parser.add_argument('-r', '--relab',action="store_true",required=False,
                    help='Select the relative abundance.[default:False]')



def main ():
    args = parser.parse_args()
    # get the name
    file=os.listdir(args.input)
    name=[]
    for i in file:
        name.append(i.split('.')[0])
    name=list(np.unique(name))

    newdata=[]

    # set unlist function        
    def flat(nums):
        res = []
        for i in nums:
            if isinstance(i, list):
                res.extend(flat(i))
            else:
                res.append(i)
        return res

    # obtain the feature data
    # caution the file name and modify it if your file has other name 
    for j in name:
        try:
            data=pd.read_csv(os.path.join(args.input,j+'.emapper.annotations'),sep='\t',skiprows=[0,1,2],low_memory=False)
            data=data[:-3]
        except:
            data=pd.read_csv(os.path.join(args.input,j+'.function.tsv'),sep='\t',low_memory=False)
        quasi=pd.read_csv(os.path.join(args.input,j+'.quant.sf'),sep='\t')
        data_merge=pd.merge(data,quasi, how='inner',left_on='#query_name', right_on='Name')
        # define the nan equal None
        data_merge=data_merge.fillna('None')
        
        # filter the feature you want to estimate 
        idx=[]
        for i in range(0,data_merge.shape[0]):
            if data_merge[args.feature][i]!='None' and data_merge[args.quanti][i]!=0:
                idx.append(i)
        data_merge_filter=data_merge.loc[idx]
        # re index
        data_merge_filter=data_merge_filter.reset_index()
        data_merge_filter=data_merge_filter.drop(['index','Name'],axis=1)
        
        # caculate the feature
        feature_raw=[]
        feature_split=[]
        for i in range(0,data_merge_filter.shape[0]):
                # add [] when utilise the str multiplication
                if args.quanti=='NumReads':
                    feature_raw.append([str(data_merge_filter[args.feature][i])]*int(data_merge_filter[args.quanti][i]))
                elif args.quanti=='TPM':
                    feature_raw.append([str(data_merge_filter[args.feature][i])]*int(round(data_merge_filter[args.quanti][i])))

        # unlist the list and del the []
        feature_unlist=flat(feature_raw)

        # split by comma
        for i in feature_unlist:
                    feature_split.append(str(i).split(","))
        # second unlist
        feature=flat(feature_split)

        # count the feature
        feature_num=collections.Counter(feature)
        newdata.append(pd.DataFrame(pd.Series(feature_num),columns=[j]))
    
    # re index the DataFrame and prepare for merging
    for i in range(0,len(newdata)):
            newdata[i]=newdata[i].reset_index()

    # merge all samples tax from one directory
    if len(newdata)==1:
        newdata_merge=newdata[0]
    elif len(newdata)==2:
        newdata_merge=pd.merge(newdata[0], newdata[1], on='index', how='outer')
        newdata_merge=newdata_merge.fillna(0)
    elif len(newdata)>2:
        newdata_merge=pd.merge(newdata[0], newdata[1], on='index', how='outer')
        for i in range(2,len(newdata)):
            try:
                newdata_merge=pd.merge(newdata_merge, newdata[i], on='index', how='outer')
            except:
                break
    newdata_merge=newdata_merge.fillna(0).sort_values(by='index').reset_index(drop=True)
    #newdata_merge.to_csv(args.output,sep='\t',index=False)



    if args.biom==True and args.relab==False :
        # modify the format to match the biom
        # Below is different from merge_table.py
        newdata_merge=pd.read_csv(args.input,sep='\t')
        newdata_merge=newdata_merge.rename(columns={'index':'OTU ID'})
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





          