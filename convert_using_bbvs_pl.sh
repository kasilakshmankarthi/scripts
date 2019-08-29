SRC=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/simpoint/results_bbvec
DST=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/simpoint/results_bbvec_pp
SIMPOINT_DIR=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/simpoint/simpoint

cd $SRC
for file in $(ls *)
do
	str1="$file"
	sz=$(stat -c %s $str1)
	if [ -s $file ] && [ $sz -gt 20 ]
	then
	    str2=$(echo $str1 | sed -e "s/.bb/.std.bb/g") 
		echo $str2
		cat $file | $SIMPOINT_DIR/scripts/standardize_bbvs.pl > $DST/$str2
	fi
done

