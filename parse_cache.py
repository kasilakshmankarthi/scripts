#!/usr/bin/env python
import re
import sys

print "probeL0D", "missL0D", "probeL1D", "missL1D", "probeL1I", "missL1I", "probeL2", "missL2", "probeL3", "missL3"
for x in range(1, 16):
        stdout = open('/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/kk_model/results_cachelatest/stdout_%d.txt' %x, "r")
    for line in stdout:
        probeL0D_match = re.match(".*_probeL0D *: *([0-9]*)", line)
        if probeL0D_match is not None:
            probeL0D = probeL0D_match.group(1)
            
        missL0D_match = re.match(".*_missL0D *: *([0-9]*)", line)
        if missL0D_match is not None:
            missL0D = missL0D_match.group(1)
            
        probeL1D_match = re.match(".*_probeL1D *: *([0-9]*)", line)
        if probeL1D_match is not None:
            probeL1D = probeL1D_match.group(1)
            
        missL1D_match = re.match(".*_missL1D *: *([0-9]*)", line)
        if missL1D_match is not None:
            missL1D = missL1D_match.group(1)
            
        probeL1I_match = re.match(".*_probeL1I *: *([0-9]*)", line)
        if probeL1I_match is not None:
            probeL1I = probeL1I_match.group(1)
            
        missL1I_match = re.match(".*_missL1I *: *([0-9]*)", line)
        if missL1I_match is not None:
            missL1I = missL1I_match.group(1)
            
        probeL2_match = re.match(".*_probeL2 *: *([0-9]*)", line)
        if probeL2_match is not None:
            probeL2 = probeL2_match.group(1)
            
        missL2_match = re.match(".*_missL2 *: *([0-9]*)", line)
        if missL2_match is not None:
            missL2 = missL2_match.group(1)
            
        probeL3_match = re.match(".*_probeL3 *: *([0-9]*)", line)
        if probeL3_match is not None:
            probeL3 = probeL3_match.group(1)
            
        missL3_match = re.match(".*_missL3 *: *([0-9]*)", line)
        if missL3_match is not None:
            missL3 = missL3_match.group(1)
            
    cache_stat = [ int(probeL0D), int(missL0D), int(probeL1D), int(missL1D), int(probeL1I), int(missL1I), int(probeL2), int(missL2), int(probeL3), int(missL3)]
    for y in range(len(cache_stat)):
        print cache_stat[y],
    print
