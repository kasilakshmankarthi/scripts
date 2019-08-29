#!/usr/bin/env python
##########################################################################
# Copyright (c) 2019 SARC Inc.
# All Rights Reserved.
# SARC Inc. Confidential and Proprietary.
##########################################################################
import string
import os
import sys
import re
import numpy as np
import matplotlib.pyplot as plt

from optparse import OptionParser

#######################################################
# Command-line setup.
parser = OptionParser(usage="python parse_plot_memaccess.py")
parser.add_option("-f", "--parsefile",
                  dest = "parsefile",
                  default = "",
                  help="To parse and plot the file")
parser.add_option("-b", "--flag",
                  dest = "flag",
                  default = "",
                  help="Flag is set to TRUE for showing the plot")   
                  
#######################################################
#######################################################
# Determine if we're valid command-line wise.
def validateArgs():
    return True

#######################################################
#######################################################    
#To return the match weight for a given interval for a given test
def get_weight_for_simpoint(test_name, test_interval, target):
    #print test_name, test_interval
    if int(target) == 32:
        #32-bit simpoints
        stdout = open("/prj/qct/qctps/modeling/benchmark_scratch/usr/kasilka/octane_sp_android/octane/32/webtech/%s/%s.combined" %(test_name, test_name), "r")
        #stdout = open(os.getcwd() + "/weights32/%s.std.weights.txt" %test_name, "r")
    if int(target) == 64:    
        #64-bit simpoints
        stdout = open("/prj/qct/qctps/modeling/benchmark_scratch/usr/kasilka/octane_sp_android/octane/64/webtech/%s/%s.combined" %(test_name, test_name), "r")
        #stdout = open(os.getcwd() + "/weights64/%s.std.weights.txt" %test_name, "r")
        
    for line in stdout:
        broken = line.split()
        #print broken[0]
        if int(broken[0]) == test_interval:
            #print broken[1]
            return broken[1]
            
#Histogram plot
def parse_and_plot(parsefile, flag):
                
    #List to hold condensed stats
    count = []
    size = []
    stdout = open(parsefile, "r")

    for line in stdout:
        g_match = re.match( ".*length.*", line)
                
        if g_match is not None:
            size.append(g_match.group().split("=")[2])


    n, bins, patches = plt.hist(x=size, bins='auto')
    # plt.grid(axis='y', alpha=0.75)
    # plt.xlabel('Value')
    # plt.ylabel('Frequency')
    # plt.title('My Very Own Histogram')
    # plt.text(23, 45, r'$\mu=15, b=3$')
    # maxfreq = n.max()
    # # Set a clean upper y-axis limit.
    # plt.ylim(ymax=np.ceil(maxfreq / 10) * 10 if maxfreq % 10 else maxfreq + 10)


#######################################################
#######################################################
# Main
if __name__ == "__main__":
    (options, args) = parser.parse_args()
    if not validateArgs():
        sys.exit(1)
        
    #if not str(options.parsefile)=="":
    #    print options.scoredir
    parse_and_plot(options.parsefile, options.flag)
