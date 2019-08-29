#SRC=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/benchmarks/octane/results_octane/hyd64_stats
SRC=/prj/qct/qctps/modeling/benchmark_scratch/usr/kasilka/antutu_sp_android/wl-build/js_simpoint_generation/Antutu/64/ART-antutuv5.6/deltablue
cd $SRC
for filename in $(ls *) 
do 
rename 's/angel_//g' $filename
#echo $filename
#rename 's/wl_//g' $filename
done;
