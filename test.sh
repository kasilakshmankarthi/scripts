#!/bin/bash
DIR=$(readlink -f "$0")
BASEDIR=$(dirname "$DIR")
echo $BASEDIR
#bname=${basename $BASEDIR}
#echo $bname
wid=3

relative_archive_directory=$(sed -rn \
   "s@^${wid},/prj/qct/qctps/modeling/ral_workloads/linux/ModelWorkloads/(.*)@\1@p" \
    /prj/qct/qctps/modeling/ral_workloads/Workload_Directory.csv | head -n1)

echo $relative_archive_directory
