#!/bin/bash

## Octane for Lucas
TMP_DIR_RELATIVE=octane_swe_v8_3_19_64bit
SIMPOINT_DIR=/prj/qct/qctps/modeling/ral_armv8/workloads/linux/Simpoints/64bit/Octane/swe_v8_3.19

sed_expression="([a-zA-Z0-9\-]*)-([0-9]+)-bb-validation:([0-9\.]+(e-?[0-9]+)?)"

prev_bm=""
sum_weighted_distance="0.0"
sum_weights="0.0"
for line in $(grep "" $TMP_DIR_RELATIVE/*/*-validation | sed -r "s@$TMP_DIR_RELATIVE/[^\/]*/@@g"); do
  bm=$(echo $line | sed -r "s/$sed_expression/\1/g")
  simpoint=$(echo $line | sed -r "s/$sed_expression/\2/g")
  euclidean_distance=$(echo $line | sed -r "s/$sed_expression/\3/g")
  euclidean_distance=$(echo "scale=10; ${euclidean_distance/[eE]/*10^}" | bc) # Remove scientific notation for bc
  checkpoint_file=$(cd $SIMPOINT_DIR/$bm && ls ${bm}-${simpoint}-*.ckpt.bz2)
  weight_string=$(echo $checkpoint_file | sed -r "s/${bm}-${simpoint}-([0-9]+).ckpt.bz2/\1/g")
  weight=$(echo "scale=10; $weight_string / 10000" | bc)
  weighted_distance=$(echo "$euclidean_distance * $weight" | bc)

  if [[ -n $prev_bm ]]; then
    if [[ $bm != $prev_bm ]]; then
      echo "# $prev_bm TOTAL: $sum_weighted_distance (total weight: $sum_weights )"
      sum_weighted_distance="0.0"
      sum_weights="0.0"
    fi
  fi
  sum_weighted_distance=$(echo "$sum_weighted_distance + $weighted_distance" | bc)
  sum_weights=$(echo "$sum_weights + $weight" | bc)

  echo $bm,$simpoint,$weight,$euclidean_distance,$weighted_distance

  prev_bm=$bm
done

echo "# $prev_bm TOTAL: $sum_weighted_distance (total weight: $sum_weights )"
