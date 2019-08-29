SRC=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/python_samples/ipc/split
PY_SRC=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/hpm/hydrapm/model/src
cd $SRC
rm -f summary.txt
for filename in $(ls *) 
do 
    python $PY_SRC/hstats.py -g $filename >> $SRC/summary.txt
done;
