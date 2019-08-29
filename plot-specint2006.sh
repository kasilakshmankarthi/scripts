#!/bin/bash

dir=/prj/qct/qctps/modeling/ral_armv8_scratch02/usr/kasilka/specscripts/U89_90_spec2006_aarch64_gcc_4.9_memdump
pys=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/scripts/parse_plot_memaccess.py

test_array=(
"400.perlbench"
# "401.bzip2"
# "403.gcc"
# "429.mcf"
# "445.gobmk"
# "456.hmmer"
# "458.sjeng"
# "462.libquantum"
# "464.h264ref"
# "471.omnetpp"
# "473.astar"
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