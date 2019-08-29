#!/usr/bin/python
#
# Given a correlation file, an address counts file, and a number
# of addresses to check, this script will take the top N addresses
# with the most stalls, and generate a CSV file with the corresponding
# counts for each stall type found.
import string
import os
import sys
import re
import csv
#from numarray import *
from optparse import OptionParser

csv.field_size_limit(sys.maxsize)

#######################################################
# Command-line setup.
parser = OptionParser(usage="python parse_hstats.py")
parser.add_option("-p", "--parse",
                  dest = "parsefile",
                  default = "",
                  help="To parse and report the weighted IPC from the specified file name")


#######################################################
#######################################################
# Determine if we're valid command-line wise.
def validateArgs():
    return True


#######################################################
#######################################################
#To parse tand write only the required fields in the period file
def parse_and_report_fields(fn):
    reader = csv.reader(open(fn, "r"), delimiter="\t", quotechar='"')
    fint = os.path.dirname(os.path.realpath(fn)) + r"/" + r"summ_int"
    #print fint
    stdout = open(fint, "w")
    #print stdout
    intcsv = csv.writer(stdout, delimiter="\t", quotechar='"')

    count = 0
    ul = 3999 #9999

    for row in reader:
       subr = []
       d = list(row)
       if count == 0:
           IPC_index = d.index('windowIPC_00')
           BrMPKI_index = d.index('windowBrMPKI_00')
           L0LD_index = d.index('windowL0LdMPKI_00')
           L2_index = d.index('windowL2MPKI_00')
           print IPC_index, BrMPKI_index, L0LD_index, L2_index

       subr.append(d[0])

       for  iter in range(0, ul):
           subr.append(d[IPC_index + iter])

       for  iter in range(0, ul):
           subr.append(d[BrMPKI_index + iter])

       for  iter in range(0, ul):
           subr.append(d[L0LD_index + iter])

       for  iter in range(0, ul):
           subr.append(d[L2_index + iter])

       #print subr
       intcsv.writerow(subr)

       count += 1

    stdout.close()
    transpose_file(fint)

#######################################################
#######################################################
#Transpose the given csv file
def transpose_file(fint):
    ftr = os.path.dirname(os.path.realpath(fint)) + r"/" + r"summ_int_tr"
    print ftr
    stdout = open(ftr, "w")

    print fint
    f = open(fint, "r")
    lis=[x.split() for x in f]

    for x in zip(*lis):
        for y in x:
            value = (y+'\t')
            s = str(value)
            stdout.write(s)
        stdout.write('\n')

    stdout.close()
    f.close()

#######################################################
#######################################################
#Transpose the given csv file
def transpose_file_csv(fout):
    print fout
    stdin = open(fout, "r")
    rows = list(csv.reader(stdin))
    lenr = len(rows) - 1

    fout = os.path.dirname(os.path.realpath(fout)) + r"_tr"
    print fout
    stdout = open(fout, "w")
    writer = csv.writer(stdout)

    for j in xrange(1, lenr):
        #print row[j] for row in rows
        writer.writerow([row[j] for row in rows])

#######################################################
#######################################################
# Main
if __name__ == "__main__":
    (options, args) = parser.parse_args()
    if not validateArgs():
        sys.exit(1)

    if not str(options.parsefile)=="":
        print "Directory Path: ",options.parsefile
        parse_and_report_fields(options.parsefile)

