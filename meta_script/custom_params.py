#!/usr/bin/python
# -*- coding: UTF-8 -*-
from parse_add_parameters import add_parameters,get_params_str
import argparse

parser = argparse.ArgumentParser(prog='custom_params.py',
    epilog='''
Usage:
custom_params.py -i parameters file -n script_name 
''', formatter_class=argparse.RawDescriptionHelpFormatter)


parser.add_argument('-i', '--input', required=True, type=str,
                    help='Input parameters file which includes custom parameters in tsv format.')

parser.add_argument('-n', '--name', required=True, type=str,
                    help='Input script name which you want to set.')

def main ():
	args = parser.parse_args()
	parameter_f = open(args.input, 'U')
	params = add_parameters(parameter_f)
	parameter_f.close()
	if args.name in params.keys():
	    add_arg=get_params_str(params[args.name])
	    print add_arg
	#else : print 'No costum parameter for ' + args.name + ', plz check the parameters file.'

if __name__ == "__main__":
    main()



























