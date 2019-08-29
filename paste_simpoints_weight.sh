CWD=$(pwd)
#WD=$CWD/weights32
WD=$CWD/weights64

#cd /prj/qct/qctps/modeling/benchmark_scratch/usr/lucasc/simpoints/octane/
#COUNT=$(ls -l|grep ^d|wc -l)
#echo $COUNT

#32-bit
#simdir=/prj/qct/qctps/modeling/benchmark_scratch/usr/lucasc/simpoints/octane

#64-bit
simdir=/prj/qct/qctps/modeling/benchmark_scratch/usr/lucasc/simpoints/octane64

for directory in $simdir/*
do
cd $directory
FILES=$(pwd)
#echo $FILES
    simpoint=""
	weight="" 
	for file in $(ls *)
		do
		    str1="$file"
			str2="*.std.simpoints" 
			str3="*.std.weights"
			
            #String equality (note space between =)
		    if [ $str1 = $str2 ] 
		   	then
                #String assignment(note NO space between =)
			    simpoint=$file
				#echo $simpoint
			fi
			
			if [ $str1 = $str3 ]
		   	then
			    weight=$file
				#echo $weight
			fi
			
			if [ $simpoint ] && [ $weight ]
			then
			    echo -e $simpoint ' \t ' $weight
			    paste $simpoint $weight > $WD/$weight.txt
                
                break;
			fi
		done
cd $CWD
done