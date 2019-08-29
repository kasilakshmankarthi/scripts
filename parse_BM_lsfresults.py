#!/usr/bin/python
import string
import os
import sys
import re
from optparse import OptionParser

#######################################################
# Command-line setup.
parser = OptionParser(usage="python parse_lsfresults.py")
###Use the shell script to combine all files into single file###
parser.add_option("-p", "--parse",
                  dest = "parsefile",
                  default = "",
                  help="To parse and report the weighted IPC from the specified file name")
parser.add_option("-t", "--target",
                  dest = "target",
                  default = "32",
                  help="Specify target as 32-bit or 64-bit")
parser.add_option("-c", "--soc",
                  dest = "soc",
                  default = "hydra",
                  help="Specify soc as hydra or hawker or istari")
#Email format is test name first, IPC last
#Stdout format is IPC first, test name last
parser.add_option("-f", "--format",
                  dest = "format",
                  default = "",
                  help="Specify LSF output format (email/stdout)")
parser.add_option("-s", "--readscores",
                  dest = "scoredir",
                  default="",
                  help="Read scores files from the specified directory to report scores")
parser.add_option("-i", "--readipc",
                  dest = "summfile",
                  default="",
                  help="Read HydramPM summary files from the specified directory to report IPC")
parser.add_option("-b", "--breakfile",
                  dest = "breakfile",
                  default="",
                  help="Read a whole file and breaks into parts based on test")

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
#This is to check the correctness for the combined file
def print_simpoint_count__for_tests(test_name, target):
    if int(target) == 32:
        #32-bit simpoints
        stdout = open("<>/%s/%s.combined" %(test_name, test_name), "r")
        #stdout = open(os.getcwd() + "/weights32/%s.std.weights.txt" %test_name, "r")
    if int(target) == 64:
        #64-bit simpoints
        stdout = open("<>/%s/%s.combined" %(test_name, test_name), "r")
        #stdout = open(os.getcwd() + "/weights64/%s.std.weights.txt" %test_name, "r")

    non_blank_count = 0

    for line in stdout:
        if line.strip():
            non_blank_count += 1

    return non_blank_count

#######################################################
#######################################################
#To return the weighted ipc for a given interval for a given test
def parse_and_report_wipc_email(fn, target, soc):

    #Test array
    #test_array=["richards", "deltablue", "crypto", "raytrace", "EB", "regexp", "splay", "navier-stokes", "pdfjs", "mandreel", "gbemu", "code-load", "box2d", "zlib", "typescript"]
    #test_array=["richards", "deltablue", "crypto", "raytrace", "earleyboyer", "regexp", "splay", "navierstokes", "pdfjs", "mandreel", "gbemu", "codeload", "box2d", "zlib", "typescript"]
    #test_array=["navierstokes"]
    test_array=["adv_search", "create_source", "dyn_create", "search"]

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

                    print "1:",simpoint_name, simpoint_interval
                    switch = 1

                if switch == 1:
                    ipc_match = re.match(".*MIPS.*", line)
                    #re.match("([0-9]*)\sseconds.*([0-9]*)\sinstructions.*", line)
                    if ipc_match is not None:
                        ipc = ipc_match.group()
                        broken=ipc.split()
                        Instructions = broken[2]
                        Cycles = broken[4]

                        #print "2",int(Instructions), int(Cycles), int(simpoint_interval)
                        switch = 0
                        count += 1

                        #ipc_calc = float(Instructions)/float(Cycles)
                        cpi_calc = float(Cycles)/float(Instructions)

                        weight = get_weight_for_simpoint(test, int(simpoint_interval), target)

                        #ipc_calc_weight = float(weight)*ipc_calc
                        #sum_weight_ipc += ipc_calc_weight

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
"""
    print simpoint_list
    for item in simpoint_list:
        print item
"""
#######################################################
#######################################################
#To return the weighted ipc for a given interval for a given test
def parse_and_report_wipc_output(fn, target, soc):

    #Test array
    #test_array=["richards", "deltablue", "crypto", "raytrace", "EB", "regexp", "splay", "navier-stokes", "pdfjs", "mandreel", "gbemu", "code-load", "box2d", "zlib", "typescript"]
    #test_array=["richards", "deltablue", "crypto", "raytrace", "earleyboyer", "regexp", "splay", "navierstokes", "pdfjs", "mandreel", "gbemu", "code-load", "box2d", "zlib", "typescript"]
    #test_array=["navierstokes"]
    test_array=["adv_search", "create_source", "dyn_create", "search"]

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
                    print "1",int(Instructions), int(Cycles)
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
#To return the weighted ipc for a given interval for a given test
def parse_and_report_score(scoredir):
    #Score array
    #test_array=["richards", "deltablue", "crypto", "raytrace", "earleyboyer", "regexp", "splay", "navierstokes", "pdfjs", "mandreel", "gbemu", "code-load", "box2d", "zlib", "typescript"]
    test_array=["adv_search", "create_source", "dyn_create", "search"]

    #List to hold condensed stats
    score_summary = []

    for i in range(0,len(test_array)):
        test = test_array[i]
        fn = scoredir + r"/result_" + test + r".txt"
        stdout = open(fn, "r")

        for line in stdout:
            #score_match = re.match( "([a-zA-Z2]*):\s*([0-9]*)", line)
            score_match = re.match( "Score.*", line)

            if score_match is not None:
                #print score_match.group(1)
                scoreline = score_match.group(0)
                broken = scoreline.split()
                #print broken
                #score_name = score_match.group(1)
                score_name = test
                score = broken[3]

                score_summary.append([str(score_name), (score)])

    for item in score_summary:
        print "[%s]" % (','.join(item))

#######################################################
#######################################################
#To return the ipc from the summary file
def parse_and_report_ipc(fn):

    #Test array
    #test_array=["richards", "deltablue", "crypto", "raytrace", "earleyboyer", "regexp", "splay", "navierstokes", "pdfjs", "mandreel", "gbemu", "code-load", "box2d", "zlib", "typescript"]
    test_array=["adv_search", "create_source", "dyn_create", "search"]

    #Output stats header
    print "Test-Name", "Instructions", "Cycles"

    for i in range(0,len(test_array)):
            test = test_array[i]
            #print test
            stdout = open(fn, "r")

            simpoint_name = "nothing"
            #empty list
            simpoint_list = []
            #false=0/true=1
            switch = 0

            for line in stdout:
                my_regex =  r".*" + r"wl_" + test + r".*"
                simpoint_match = re.match(my_regex, line)

                if simpoint_match is not None:
                    simpoint = simpoint_match.group()
                    broken = simpoint.split()
                    simpoint_name = str(test)
                    switch = 1
                    #print "1:",simpoint_name

                if switch == 1:
                    ipc_match = re.match(".*seconds.*", line)
                    #re.match("([0-9]*)\sseconds.*([0-9]*)\sinstructions.*", line)
                    if ipc_match is not None:
                        ipc = ipc_match.group()
                        broken=ipc.split()
                        Instructions = broken[2]
                        Cycles = broken[4]

                        #print "2",int(Instructions), int(Cycles)
                        switch = 0

                        octane_stat = [ simpoint_name.replace('\'', ''), (Instructions), (Cycles) ]
                        #print octane_stat
                        print "[%s]" % (','.join(octane_stat))

#######################################################
#######################################################
#To break the summary file
def break_files(fn):

    #Test array
    test_array=["richards", "deltablue", "crypto", "raytrace", "earleyboyer", "regexp", "splay", "navierstokes", "pdfjs", "mandreel", "gbemu", "code-load", "box2d", "zlib", "typescript"]

    for i in range(0,len(test_array)):
            test = test_array[i]
            #print test
            stdin = open(fn, "r")
            fout = os.path.dirname(os.path.realpath(fn)) + r"/split/" + os.path.splitext(os.path.basename(fn))[0] + r"_" + test
            stdout= open(fout, "w")
            print stdout
            #false=0/true=1
            switch = 0

            for line in stdin:
                my_regex =  r"Subject.*" + r"wl_" + test + r".*"
                simpoint_match = re.match(my_regex, line)

                if simpoint_match is not None:
                    switch = 1

                if switch == 1:
                    stdout.write(line)
                    ipc_match = re.match(".*seconds.*", line)
                    #re.match("([0-9]*)\sseconds.*([0-9]*)\sinstructions.*", line)
                    if ipc_match is not None:
                        stdout.close()
                        switch = 0

#######################################################
#######################################################
#To combine the summary file
def combine_parse_and_report_wipc(parsedir):

    #Test array
    test_array=["richards", "deltablue", "crypto", "raytrace", "earleyboyer", "regexp", "splay", "navierstokes", "pdfjs", "mandreel", "gbemu", "code-load", "box2d", "zlib", "typescript"]

    for i in range(0,len(test_array)):
            test = test_array[i]
            fn = parsedir + r"/ipc-" + test + r".txt"
            stdout = open(fn, "r")
            stdin = open(fn, "r")
            fout = os.path.dirname(os.path.realpath(fn)) + r"/split/" + os.path.splitext(os.path.basename(fn))[0] + r"_" + test
            stdout= open(fout, "w")
            print stdout
            #false=0/true=1
            switch = 0

            for line in stdin:
                my_regex =  r"Subject.*" + r"wl_" + test + r".*"
                simpoint_match = re.match(my_regex, line)

                if simpoint_match is not None:
                    switch = 1

                if switch == 1:
                    stdout.write(line)
                    ipc_match = re.match(".*seconds.*", line)
                    #re.match("([0-9]*)\sseconds.*([0-9]*)\sinstructions.*", line)
                    if ipc_match is not None:
                        stdout.close()
                        switch = 0

#######################################################
#######################################################
# Main
if __name__ == "__main__":
    (options, args) = parser.parse_args()
    if not validateArgs():
        sys.exit(1)

    if not str(options.parsefile)=="":
        print "Directory Path: ",options.parsefile
        print "Target: ",options.target
        print "Format: ",options.format
        print "SOC: ",options.soc
        if options.format == "email":
            parse_and_report_wipc_email(options.parsefile, options.target, options.soc)
        else:
            parse_and_report_wipc_output(options.parsefile, options.target, options.soc)

    #if not str(options.parsedir)=="":
    #    print options.parsedir
    #    combine_parse_and_report_wipc(options.parsedir)

    if not str(options.scoredir)=="":
        print options.scoredir
        parse_and_report_score(options.scoredir)

    if not str(options.summfile)=="":
        print options.summfile
        parse_and_report_ipc(options.summfile)

    if not str(options.breakfile)=="":
        print options.breakfile
        break_files(options.breakfile)
