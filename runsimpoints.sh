SRC=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/simpoint/results_bbvec_pp
DST=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/simpoint/clusters
SIMPOINT_DIR=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/simpoint/simpoint

cd $SRC
for file in $(ls *)
do
   $SIMPOINT_DIR/SimPoint.2.0/bin/runsimpoint $file $DST
done

