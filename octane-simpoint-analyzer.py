#!/usr/bin/python
import string
import os
import sys
import re
import subprocess
import commands
import argparse


#######################################################
# class SimpointResultClass
# A storage class for  simpoint results from LSF runs
#######################################################
class SimpointResultClass:
    """A storage class for  simpoint results from LSF runs"""
    def __init__(self, bm, interval, cycles, instr, weight, cpi, weighted_cpi):
        self.bm_ = bm
        self.interval_ = interval
        self.cycles_ = cycles
        self.instr_ = instr
        self.weight_ = weight
        self.cpi_ = cpi
        self.weighted_cpi_ = weighted_cpi

    def __repr__(self):
        return ("( benchmark: %s interval: %s cycles: %s instructions: %s weight: %s cpi: %s weighted_cpi: %s )"\
                %(repr(self.bm_), repr(self.interval_), repr(self.cycles_), repr(self.instr_), \
                  repr(self.weight_), repr(self.cpi_), repr(self.weighted_cpi_)))

#######################################################
# class SimpointStatsClass
# A storage class for  simpoint statistics
#######################################################
class SimpointStatsClass:
    """A storage class for  simpoint statistics"""
    def __init__(self, num_intervals, weighted_cpi, instr, cycles):
        self.num_intervals_ = num_intervals
        self.weighted_cpi_ = weighted_cpi
        self.instr_ = instr
        self.cycles_ = cycles

    def intervals(self):
        return self.num_intervals_

    def cpi(self):
        return self.weighted_cpi_

    def instr(self):
        return self.instr_

    def cycles(self):
        return self.cycles_

    def __repr__(self):
        return ("( num_intervals: %s weighted_cpi: %s instr: %s cycles: %s )" \
                %(repr(self.num_intervals_), repr(self.weighted_cpi_), repr(self.instr_), \
                  repr(self.cycles_)))

#######################################################
# validateArgs()
#######################################################
# Determine if we're valid command-line wise.
def validateArgs():
    if not os.path.isdir(args.outdir):
        return False
    return True

#######################################################
# get_weight_for_simpoint(test_name, test_interval)
#######################################################
#To return the match weight for a given interval for a given test
def get_weight_for_simpoint(test_name, test_interval):
    key = "%s %s" %(test_name, test_interval)
    if dict__results.has_key(key):
        return dict__results[key].weight_
    else:
        return "-1"

################################################################################
# parse_out_files(location)
################################################################################
def parse_out_files(location):
    global list_test_intervals, dict__stats, dict__results
    pati = ".*instructions,.*"
    cwd = os.getcwd()

    os.chdir(location)
    sorted_file_list = commands.getoutput("ls *.out")
    prev_bm = ""
    for f in sorted_file_list.split():
        bm_list = f.split("-")
        bm = bm_list[0]
        if bm != prev_bm:
            sum_weight_cpi = 0.0
        prev_bm = bm
        interval = bm_list[1]
        weight = float(bm_list[2].replace(".out","")) / 10000.0
        found = 0
        file = open(f, "r")
        for line in file:
            if re.compile(pati).search(line):
                cycles = line.split(" ")[4]
                instr = line.split(" ")[2]
                found = 1
                break
        file.close()
        if found:
            cpi_calc = float(cycles)/float(instr)
            cpi_calc_weight = float(weight)*float(cpi_calc)
            sum_weight_cpi += cpi_calc_weight

            key = bm + " " + interval;
            list_test_intervals.append(key)

            info = SimpointResultClass(bm, interval, cycles, instr, weight, cpi_calc, cpi_calc_weight)
            dict__results[key] = info

            if not dict__stats.has_key(bm):
                dict__stats[bm] = SimpointStatsClass(1, 1.0/sum_weight_cpi, instr, cycles)
            else:
                new_intervals = dict__stats[bm].intervals() + 1
                new_instr = int(dict__stats[bm].instr()) + int(instr)
                new_cycles = int(dict__stats[bm].cycles()) + int(cycles)
                dict__stats[bm] = SimpointStatsClass(new_intervals, 1.0/sum_weight_cpi, new_instr, new_cycles)
    os.chdir(cwd)

#######################################################
# report_wipc(format)
#######################################################
#To return the weighted ipc for a given interval for a given test
def report_wipc(format):
    if format == "email":
        print "\nTest-Name Intervals CPI"
        for key in test_array:
            print key, dict__stats[key].intervals(), dict__stats[key].cpi()
    else:
        print "\nTest-Name CPI Intervals"
        for key in test_array:
            print key, dict__stats[key].cpi(), dict__stats[key].intervals()

#######################################################
# report_score()
#######################################################
#To return the weighted ipc for a given interval for a given test
def report_score():
    print "\nInterval Weight"
    for key in list_test_intervals:
        print "'" + key + "'", dict__results[key].weighted_cpi_

#######################################################
# report_ipc()
#######################################################
#To return the ipc from the summary file
def report_ipc():
    #Output stats header
    print "\nTest-Name Instructions Cycles"
    for key in test_array:
        print key, dict__stats[key].instr(), dict__stats[key].cycles()

################################################################################
# proc_args()
################################################################################
def proc_args():
    global args
    # Command-line setup.
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose",
                        action = "store_true",
                        help = "increase output verbosity")
    #Email format is test name first, IPC last
    #Stdout format is IPC first, test name last
    parser.add_argument("-f", "--format",
                        choices = ["email", "stdout"],
                        default = "email",
                        help = "Specify LSF output format (email/stdout)")
    parser.add_argument("-s", "--readscores",
                        dest = "scoredir",
                        action = "store_true",
                        help="Report scores")
    parser.add_argument("-i", "--readipc",
                        dest = "summfile",
                        action ="store_true",
                        help = "Report IPC")
    parser.add_argument("-o", "--outdir",
                        default = "",
                        required = True,
                        help = "Path to a location where the .out files are located.")
    args = parser.parse_args()
    if not validateArgs():
        print "Argument validation failed. Aborting."
        sys.exit(1)

################################################################################
# main()
################################################################################
def main():
    #Test array
    global test_array, outdir
    test_array = ["richards", "deltablue", "crypto", "raytrace", "earleyboyer", "regexp", "splay", "navierstokes", "pdfjs", "mandreel", "gbemu", "codeload", "box2d", "zlib", "typescript"]
    outdir = os.path.abspath(args.outdir)

    if not str(outdir)=="":
        print "Directory Path: ", outdir
        print "Format: ", args.format
        parse_out_files(outdir)

        if args.scoredir:
            report_score()
        if args.summfile:
            report_ipc()
        report_wipc(args.format)

    print

#######################################################
#######################################################
# Main
if __name__ == "__main__":
    # Global variables
    test_array = []
    args = []
    list_test_intervals = []
    dict__stats = {}
    dict__results = {}
    proc_args()
    main()
