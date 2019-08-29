#!/bin/bash

echo "Running interactive session...."
bsub -P 70806.00.rtp_perf_analysis -R "select[type==LINUX64] && select[sles11] && rusage[mem=10000]" -Is /bin/bash
