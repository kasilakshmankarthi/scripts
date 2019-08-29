#!/usr/bin/env python
import sys
import re

print "Instructions", "Cycles", "L0D$Miss", "L0D$Access", "L0I$Miss", "L0I$Access", "L1D$Miss", "L1I$Miss", "L2D$Hit", "L2D$Access", "L2I$Hit", "L2I$Access" 

stdout = open("/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/python_samples/octane_cache_stats.txt", "r")
for line in stdout:
    L0DMiss_match = re.match(" *([0-9]*) *raw *0x12082", line)
    if L0DMiss_match is not None:
        L0DMiss = L0DMiss_match.group(1)
        
    L0DAccess_match = re.match(" *([0-9]*) *raw *0x4", line)
    if L0DAccess_match is not None:
        L0DAccess = L0DAccess_match.group(1)
        
    L0IMiss_match = re.match(" *([0-9]*) *raw *0x10011", line)
    if L0IMiss_match is not None:
        L0IMiss = L0IMiss_match.group(1)
        
    L0IAccess_match = re.match(" *([0-9]*) *raw *0x10012", line)
    if L0IAccess_match is not None:
        L0IAccess = L0IAccess_match.group(1)
        
    L1DMiss_match = re.match(" *([0-9]*) *raw *0x120a0", line)
    if L1DMiss_match is not None:
        L1DMiss = L1DMiss_match.group(1)
        
    L1IMiss_match = re.match(" *([0-9]*) *raw *0x10010", line)
    if L1IMiss_match is not None:
        L1IMiss = L1IMiss_match.group(1)
        
    Instructions_match = re.match(" *([0-9]*) *raw *0x8", line)
    if Instructions_match is not None:
        Instructions = Instructions_match.group(1)
        
    Cycles_match = re.match(" *([0-9]*) *raw *0x11", line)
    if Cycles_match is not None:
        Cycles = Cycles_match.group(1)
        
    L2DHit_match = re.match(" *([0-9]*) *msm-l2 *0x73", line)
    if L2DHit_match is not None:
        L2DHit = L2DHit_match.group(1)
        
    L2DAccess_match = re.match(" *([0-9]*) *msm-l2 *0x22", line)
    if L2DAccess_match is not None:
        L2DAccess = L2DAccess_match.group(1)
        
    L2IHit_match = re.match(" *([0-9]*) *msm-l2 *0x61", line)
    if L2IHit_match is not None:
        L2IHit = L2IHit_match.group(1)
        
    L2IAccess_match = re.match(" *([0-9]*) *msm-l2 *0x20", line)
    if L2IAccess_match is not None:
        L2IAccess = L2IAccess_match.group(1)
        cache_stat = [ int(Instructions), int(Cycles), int(L0DMiss), int(L0DAccess), int(L0IMiss), int(L0IAccess), int(L1DMiss), int(L1IMiss), int(L2DHit), int(L2DAccess), int(L2IHit), int(L2IAccess)]
        print cache_stat
"""
    for y in range(len(cache_stat)):
        print cache_stat[y],
    print
"""
