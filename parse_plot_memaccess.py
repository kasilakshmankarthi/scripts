#!/usr/bin/python
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
parser.add_option("-p", "--param",
                  dest = "param",
                  default = "",
                  help="Input param")
parser.add_option("-t", "--test",
                  dest = "test",
                  default="",
                  help="Test name")
parser.add_option("-s", "--simpoint",
                  dest = "simpoint",
                  default = "",
                  help="Simpoint")
parser.add_option("-w", "--weight",
                  dest = "weight",
                  default = "",
                  help="Weight")
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
        stdout = open("<>/%s/%s.combined" %(test_name, test_name), "r")
        #stdout = open(os.getcwd() + "/weights32/%s.std.weights.txt" %test_name, "r")
    if int(target) == 64:
        #64-bit simpoints
        stdout = open("<>/%s/%s.combined" %(test_name, test_name), "r")
        #stdout = open(os.getcwd() + "/weights64/%s.std.weights.txt" %test_name, "r")

    for line in stdout:
        broken = line.split()
        #print broken[0]
        if int(broken[0]) == test_interval:
            #print broken[1]
            return broken[1]

#######################################################
#######################################################
#To return the weighted ipc for a given interval for a given test
def parse_and_report_wipc_output(fn, target, soc):

    #Test array
    test_array=["richards", "deltablue", "crypto", "raytrace", "earleyboyer", "regexp", "splay", "navierstokes", "pdfjs", "mandreel", "gbemu", "codeload", "box2d", "zlib", "typescript"]
    #test_array=["navierstokes"]

    #Create the test/simpoints table
    tot = 0
    for i in range(0,len(test_array)):
            test = test_array[i]
            tot += print_simpoint_count__for_tests(test, target)
            print test, print_simpoint_count__for_tests(test, target)
    print "Total Simpoints", tot

    #Output stats header
    print "SimPoint-Name", "SimPoint-Interval", "Weights", "Instructions", "Cycles", "Weighted-CPI"

    #List to hold condensed stats
    simpoint_condensed = []

    for i in range(0,len(test_array)):
            test = test_array[i]
            #print test
            stdout = open(fn, "r")

            simpoint_name = "nothing"
            simpoint_interval = 0
            #empty list
            simpoint_list = []
            #false=0/true=1
            switch = 0
            #To count the number of simpoints for each test
            count = 0
            #To compute the weighted ipc for each test
            sum_weight_ipc = 0
            sum_weight_cpi = 0

            for line in stdout:
                ipc_match = re.match(".*MIPS.*", line)
                if ipc_match is not None:
                    ipc = ipc_match.group()
                    broken=ipc.split()
                    Instructions = broken[2]
                    Cycles = broken[4]
                    #print "1",int(Instructions), int(Cycles)
                    switch = 1

                if switch == 1:
                    if soc == "istari":
                        my_regex =  r"/tmp/" + re.escape(test) + r".*ckpt"
                    else:
                        my_regex =  r"/prj/.*run_simpoint.*\s" + re.escape(test) + r"\s\d{1,}"
                    simpoint_match = re.match(my_regex, line)

                    if simpoint_match is not None:
                        simpoint = simpoint_match.group()
                        print simpoint
                        if soc == "istari":
                            broken1 = simpoint.split("/")
                            broken2 = broken1[2].split("-")
                            simpoint_name = str(broken2[0])
                            simpoint_interval = broken2[1]
                        else:
                            broken = simpoint.split()
                            simpoint_name = str(broken[1])
                            simpoint_interval = broken[2]

                        print "2:",simpoint_name, simpoint_interval, int(Instructions), int(Cycles)

                        switch = 0
                        count += 1

                        cpi_calc = float(Cycles)/float(Instructions)

                        weight = get_weight_for_simpoint(test, int(simpoint_interval), target)

                        cpi_calc_weight = float(weight)*cpi_calc
                        sum_weight_cpi += cpi_calc_weight

                        octane_stat = [ simpoint_name.replace('\'', ''), (simpoint_interval), str(weight), (Instructions), (Cycles), str(cpi_calc_weight) ]
                        #print octane_stat
                        #print "[%s]" % (','.join(octane_stat))
                    #simpoint_list.append(octane_stat)
            if sum_weight_cpi != 0:
                simpoint_condensed.append([ simpoint_name, str(count), str(1/sum_weight_cpi)])

    for item in simpoint_condensed:
        print "[%s]" % (','.join(item))

#######################################################
#######################################################
test_array=(
"400.perlbench",
# "401.bzip2",
# "403.gcc",
# "429.mcf",
# "445.gobmk",
# "456.hmmer",
# "458.sjeng",
# "462.libquantum",
# "464.h264ref",
# "471.omnetpp",
# "473.astar",
# "483.xalancbmk"
# "483.xalancbmk"
)

params_array=(
"2"
# "6"
# "9"
# "1"
# "5"
# "2"
# "1"
# "1"
# "3"
# "1"
# "2"
# "1"
)

#To return the weighted ipc for a given interval for a given test
def specint2006(parsefile, test, param, simpoint, weight, flag):
MAX1=$((${#test_array[@]} - 1))
echo "Total Tests" `expr "$MAX1" + "1"`
for i in `seq 0 $MAX1`
do
    test=${test_array[i]}
    echo $test
    param=${params_array[j]}
    echo $param
    for j in `seq 1 $param`
    do
        count=$(ls ${dir}/${test}-${j}-*memdump.out | wc -l)
        iter=1
        flag=0
        for OUTPUT in $(ls ${dir}/${test}-${j}-*memdump.out | xargs -n 1 basename)
        do
           #echo $test          #Test name
           #echo $j  #Param name
           simpoint=`echo ${OUTPUT} |cut -d'-' -f3`
           weight=`echo ${OUTPUT} |cut -d'-' -f4`
           #echo $simpoint $weight
           if [ $iter -eq $count ]; then
               flag=1
           fi
           python $pys -f $dir/$OUTPUT -t $test -p $param -s $simpoint -w $weight -b $flag
           iter=`expr $iter + 1`
        done
    done
done

#To return the weighted ipc for a given interval for a given test
def parse_and_plot(parsefile, test, param, simpoint, weight, flag):

    #List to hold condensed stats
    instrs = []
    cache_lines = []
    #weight = int(weight)/100
    lbl = simpoint + "-" + str(weight)
    stdout = open(parsefile, "r")

    for line in stdout:
        score_match = re.match( ".*mtrace_instr.*", line)

        if score_match is not None:
            scoreline = score_match.group()
            broken = scoreline.split("=")
            broken1 = broken[1].split(",")
            instrs.append(broken1[0])
            #print instrs
            cache_lines.append(broken[2])
            #print cache_lines

    #subplots_adjust(hspace=0.000)
    number_of_subplots = int(param)
    print number_of_subplots

    #for v in enumerate(xrange(number_of_subplots)):
    #ax1 = plt.subplot(number_of_subplots,1,1)
    ax1.plot(instrs, cache_lines, 'yo-', label=''+str(lbl))
        #ax1.title(''+str(test))
        #ax1.ylabel('Cache lines')
        #ax1.xlabel('Instrs (MM)')
    ax1.legend(loc='upper left');

    #print flag
    #print v
    if int(flag) == 1:
        #v += 1
        print flag
        plt.grid()
        plt.show()

    #if v == int(param):
    #    plt.grid()
    #    plt.show()
    #    v = 0

#######################################################
#######################################################
# Main
if __name__ == "__main__":
    (options, args) = parser.parse_args()
    if not validateArgs():
        sys.exit(1)

    #if not str(options.parsefile)=="":
    #    print options.scoredir
    parse_and_plot(options.parsefile, options.test, options.param, options.simpoint, options.weight, options.flag)
