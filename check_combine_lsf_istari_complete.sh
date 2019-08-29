#!/bin/bash
SIMDIR=$1
echo "Working on LSF output results directory" $SIMDIR
TARGET=$2
echo "TARGET processor is 32 bit or 64 bit" $TARGET

usage()
{
  echo "Usage:: Run the following command";
  echo "./check_combine_lsf_istari_complete <LSF output directoy> <target processor configuration (32/64)>";
  echo;
}

test_array=("richards" "deltablue" "crypto" "raytrace" "earleyboyer" "regexp" "splay" "navierstokes" "pdfjs" "mandreel" "gbemu" "codeload" "box2d" "zlib" "typescript")
MAX=$((${#test_array[@]} - 1))

check_complete()
{
 status=0
 for directory in $SIMDIR/*
 do
   cd $SIMDIR
   find .  -type f -name "*.out" |
   while read file;
   do
       check=$(cat $file | grep "Successfully completed.")
       len=$(expr length "$check")
       #echo $len
       if [ $len -eq 0 ]
       then
	      echo "Still running in LSF. So Exiting"
	      echo $file
          exit 1
	   fi
   done
   status=${PIPESTATUS[1]}
   #echo "Status is" $status
   if [ "$status" == "1" ] 
   then
       echo "breaking"
       break
   fi
 done
}

combine()
{
   echo "Removing old joined file" 
   echo "Joining log files since LSF jobs are completed" 
   rm -rf $SIMDIR/combipc_$TARGET.txt
   
   for directory in $SIMDIR/*/
   do
      cd $SIMDIR
       find . -name "*.out" |
       while read file
       do
         cat $file >> $SIMDIR/combipc_$TARGET.txt
       done
  done
}

usage;
check_complete;
if [ "$status" == "0" ] 
then
   combine
else
   echo "Cannot join log files since LSF jobs are still running"
fi
