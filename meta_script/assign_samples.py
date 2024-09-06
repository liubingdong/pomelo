#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import pandas as pd
import numpy as np
import os
import collections
import argparse
import shutil
parser = argparse.ArgumentParser(prog='assign_samples.py',
    description='''\
      --------------------------------------------------------------------------------
      assign_samples.py is designed to 
      divide input files according to cores for parallel mode.
      It may cause unexpected problems and user could contact me by 382983280@qq.com.
      --------------------------------------------------------------------------------
                ''',    
    epilog='''
Usage:
assign_samples.py -i quansi_data -n 5 -o divide_output

''', formatter_class=argparse.RawDescriptionHelpFormatter)



parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input directory containing each sample function annotations and salmon results.')
parser.add_argument('-n', '--core', required=True, type=int,
                    help='CPU cores.')
parser.add_argument('-o', '--output', required=True, type=str,
                    help='output directory where input files are divided into seub groups for parallel mode.')


def main ():
    args = parser.parse_args()
    file=os.listdir(args.input)
    core=args.core
    # set useful function
    def assign(listTemp, n):
      for i in range(0, len(listTemp), n):
        yield listTemp[i:i + n]
    def flat(nums):
      res = []
      for i in nums:
          if isinstance(i, list):
              res.extend(flat(i))
          else:
              res.append(i)
      return res

    name=[]
    for i in file:
      name.append(i.split('.')[0])
      name=list(np.unique(name))
    opt_num=[]
    if len(name)>=core:
      if len(name)%core==0 :
          res=assign(name,len(name)/core)
          for i in res:
              opt_num.append(i)
      else:
          add_num=len(name)%core
          res=assign(name,len(name)/core)
          for i in res:
              opt_num.append(i)
      opt_num[core-1].extend(opt_num[core:])
      del opt_num[core:]
    else:
    # when the core > samples num
      res=assign(name,1)
      for i in res:
          opt_num.append(i)
  # assign samples into sub group dir for merging
    for i in range(0,len(name)):
      os.makedirs(os.path.join(args.output,'temp_'+str(i)))
      path=os.path.join(args.output,'temp_'+str(i))
      #out_file=os.path.join('func_merge_temp/temp_total/temp_'+str(i)+'.tsv')
      for j in flat(opt_num[i]):
          try:
              file1=os.path.join(args.input,j+'.function.tsv')
          except:
              file1=os.path.join(args.input,j+'.emapper.annotations')
          file2=os.path.join(args.input,j+'.quant.sf')
          shutil.move(file1,path)
          shutil.move(file2,path)

if __name__ == "__main__":
    main()



















