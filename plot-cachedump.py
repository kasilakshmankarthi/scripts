#!/usr/bin/python
import string
import os
import sys
import re
import numpy as np
import matplotlib.pyplot as plt

from pylab import *
from optparse import OptionParser

test_array = [
"400.perlbench",
"401.bzip2",
"403.gcc",
"429.mcf",
"445.gobmk",
"456.hmmer",
"458.sjeng",
"462.libquantum",
"464.h264ref",
"471.omnetpp",
"473.astar",
"483.xalancbmk"
]

params_array = [
"3",
"6",
"9",
"1",
"5",
"2",
"1",
"1",
"3",
"1",
"2",
"1"
]

sysmem_addr=[
 [1814938, 2543157, 5312891],
 [3299879,587131,522860,3632160,3080167,2421952],
 [2178736,2104555,3642427,2842278,3946138,5339397,6950811,7566352,822337],
 [13739079],
 [221638,226446,219041,219582,221816],
 [373898,48991],
 [1433126],
 [1058783],
 [140690,95991,435016],
 [1253508],
 [2161720,542806],
 [2500357]
]

color_array = ['red','green','blue','black','magenta','yellow', 'lightgrey', 'darkkhaki','royalblue', 'orange', 'violet', 'pink']

dir = "<>/U89_90_spec2006_aarch64_gcc_4.9_memdump/"

plt_sp_interval = 201

#To parse file
def parse_file(parsefile, test, param, simpoint, weight, ax1, instrs, cachelines):

    stdout = open(parsefile, "r")

    for line in stdout:
        score_match = re.match( "postExec\smtrace_instr.*", line)

        if score_match is not None:
            scoreline = score_match.group()
            broken = scoreline.split("=")
            broken1 = broken[1].split(",")
            instrs.append(broken1[0])
            cachelines.append(broken[2])
            #print cachelines

#def specint2006():
#Go over subtest
for i in range(0,len(test_array)):
    test = test_array[i]
    param = int(params_array[i]) + 1
    row = 1

    #Go over a given subtest with input param
    for k in range(1, int(param)):
        if k > 3:
           ax1 = plt.subplot(3,1,row)
        else:
           ax1 = plt.subplot(3,1,k)

        my_regex =  test + r"-" + str(k) + r".*" + r"memdump.out"
        files = [f for f in os.listdir(dir) if re.match(my_regex, f)]

        maxunique = 0
        minunique = 5000000000
        totunique = 0
        tit = ""

        for t in range(0,len(files)):
            splitfn = files[t].split("-");
            simpoint = splitfn[2]
            if int(simpoint) < plt_sp_interval:
                #print "Skipping simpoint", simpoint
                continue
            weight = float(splitfn[3])
            weight = weight/100
            parsefile = str(dir) + files[t]
            instrs = []
            cachelines = []
            #print parsefile
            parse_file(parsefile, test, param, simpoint, weight, ax1, instrs, cachelines)
            #print cachelines
            #print "maxcachelines", int(min(cachelines, key=int))

            lbl = simpoint + "-" + str(weight) + "%"
            ax1.plot(instrs, cachelines, 'yo-', color=color_array[t], label=''+str(lbl))
            ax1.legend(loc='best', fancybox=True, framealpha=0.25)
            tit = str(test) + "-" + str(k)

            if cachelines:
                maxunique = max(maxunique, int(max(cachelines, key=int)))
                minunique = min(minunique, cachelines[int(len(cachelines))-1], key=int)
                totunique += int(max(cachelines, key=int))
                #print tit, simpoint, weight, max(cachelines, key=int)
            #else:
                #print tit, simpoint, weight, 0

            ax1.set_title(''+str(tit))
            ax1.set_ylabel('Unique Cache lines')
            ax1.set_xlabel('Instrs (MM)')
            ax1.grid(True)

        #print str(tit), len(files), maxunique, minunique
        ax1.axhline(y=sysmem_addr[i][k-1] , xmin=0, xmax=1, linewidth=2, color='k')

        #Increment row counter
        row += 1

        if row >= 4 or k == int(params_array[i]):
            row = 1
            #sname = str(test) + ".png"
            #savefig('some.png', bbox_inches='tight')
            plt.show()
