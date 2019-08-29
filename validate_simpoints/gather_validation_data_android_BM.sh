#!/bin/bash

## BM
TMP_DIR_RELATIVE=/prj/qct/qctps/modeling/ral_armv8/usr/kasilka/scripts/validate_simpoints/BM/
SIMPOINT_DIR=/prj/qct/qctps/modeling/ral_workloads/linux/Simpoints/32bit/BM2_1/android_webview_apk

sed_expression="([a-zA-Z0-9\-\_]*)-([0-9]+)-bb-validation:([0-9\.]+(e-?[0-9]+)?)[,]([0-9\.]+(e-?[0-9]+)?)"

prev_bm=""
sum_weighted_distance_e="0.0"
sum_weights_e="0.0"

sum_weighted_distance_m="0.0"
sum_weights_m="0.0"

#Format of validation file: print "%f,%f" % (euclidean_distance, manhattan_distance)

for line in $(grep "" $TMP_DIR_RELATIVE/*/*-validation | sed -r "s@$TMP_DIR_RELATIVE/[^\/]*/@@g"); do
  bm=$(echo $line | sed -r "s/$sed_expression/\1/g")
  #echo "Kasi Start"
  #echo $line
  #echo $bm
  simpoint=$(echo $line | sed -r "s/$sed_expression/\2/g")
  #echo $simpoint
  euclidean_distance=$(echo $line | sed -r "s/$sed_expression/\3/g")
  euclidean_distance=$(echo "scale=10; ${euclidean_distance/[eE]/*10^}" | bc) # Remove scientific notation for bc
  #echo $euclidean_distance
  
  manhattan_distance=$(echo $line | sed -r "s/$sed_expression/\5/g")
  manhattan_distance=$(echo "scale=10; ${manhattan_distance/[eE]/*10^}" | bc) # Remove scientific notation for bc
  #echo $manhattan_distance
  
  checkpoint_file=$(cd $SIMPOINT_DIR/$bm && ls ${bm}-${simpoint}-*.ckpt.bz2)
  #echo $checkpoint_file
  weight_string=$(echo $checkpoint_file | sed -r "s/${bm}-${simpoint}-([0-9]+).ckpt.bz2/\1/g")
  weight=$(echo "scale=10; $weight_string / 10000" | bc)
  #echo $weight
  weighted_distance_e=$(echo "$euclidean_distance * $weight" | bc)
  weighted_distance_m=$(echo "$manhattan_distance * $weight" | bc)
  #echo $weighted_distance_e $weighted_distance_m
  #echo "Kasi End"

  if [[ -n $prev_bm ]]; then
    if [[ $bm != $prev_bm ]]; then
      echo "# $prev_bm TOTAL-EUCLIDEAN: $sum_weighted_distance_e (total weight: $sum_weights_e ) TOTAL-MANHATTAN: $sum_weighted_distance_m (total weight: $sum_weights_m ) "
      sum_weighted_distance_e="0.0"
      sum_weights_e="0.0"
      
      sum_weighted_distance_m="0.0"
      sum_weights_m="0.0"
    fi
  fi
  sum_weighted_distance_e=$(echo "$sum_weighted_distance_e + $weighted_distance_e" | bc)
  sum_weights_e=$(echo "$sum_weights_e + $weight" | bc)
  
  sum_weighted_distance_m=$(echo "$sum_weighted_distance_m + $weighted_distance_m" | bc)
  sum_weights_m=$(echo "$sum_weights_m + $weight" | bc)

  echo $bm,$simpoint,$weight,$euclidean_distance,$weighted_distance_e, $manhattan_distance,$weighted_distance_m 

  prev_bm=$bm
done

echo "# $prev_bm TOTAL-EUCLIDEAN: $sum_weighted_distance_e (total weight: $sum_weights_e ) TOTAL-MANHATTAN: $sum_weighted_distance_m (total weight: $sum_weights_m )"
