#!/bin/bash

## Octane for Lucas
DATA_DIR=/prj/qct/qctps/modeling/benchmark_scratch/usr/lucasc/simpoints/octane64
SIMPOINT_DIR=/prj/qct/qctps/modeling/ral_armv8/workloads/linux/Simpoints/64bit/Octane/swe_v8_3.19
TMP_DIR=/prj/qct/qctps/modeling/ral_armv8_scratch/usr/alindsay/validate_simpoints/octane_swe_v8_3_19_64bit

linux_dir=/prj/qct/qctps/modeling/ral_armv8/workloads/linux/3.13/9.1
T=arm-linux-gnueabihf

ARMV8ISS=/prj/qct/qctps/modeling/ral_armv8_scratch/usr/alindsay/validate_simpoints/armv8iss
BASE_DIR=/prj/qct/qctps/modeling/ral_armv8_scratch/usr/alindsay/validate_simpoints

target=arm-linux-gnueabihf

function validate_simpoint() {
  local dir=$1
  local bm=$2
  local simpoint=$3 # Reminder: 1-indexed for Simpoint 2.0
  local bb_file=$4

  local id=$bm-$simpoint

  # First, run the simpoint checkpoint
  local checkpoint_bz2=$(cd $SIMPOINT_DIR/$bm && ls $id-[0-9]*.ckpt.bz2)
  local checkpoint=$dir/${checkpoint_bz2%.bz2}

  bb_dir=$dir/bb
  mkdir -p $bb_dir

  if [[ ! -f $bb_dir/$id-bb-0.bb ]]; then

    armv8iss_script=$dir/$id-armv8iss-bb.sh
    echo "#!/bin/bash
    if [[ ! -f $checkpoint ]]; then
      cp $SIMPOINT_DIR/$bm/$checkpoint_bz2 $dir/
      bunzip2 $dir/$checkpoint_bz2
    fi

    $ARMV8ISS \\
        -D linux=linux \\
        -D ARGS=\"\\\"--kernel $linux_dir/sysroot/boot/$T/Image --dtb $linux_dir/sysroot/boot/rtsm_ve-aemv8a.dtb -- debug root=/dev/vda console=ttyAMA0 maxcpus=1 init=/sbin/$T/init norandmaps\\\"\" \\
        -D SIM_TYPE_ARMV8ISS \\
        -D LOAD_CHECKPOINT=$checkpoint \\
        -D CONSOLE_FILE_OUTPUT \\
        -D CONSOLE_FILE_OUTPUT_FILENAME=$dir/$id-armv8iss-bb.uart \\
        -D VBLK_PATH=$linux_dir/deploy/image-minimal.ext2 \\
        -f /prj/qct/qctps/modeling/ral_modeling/releases/piface/latest/mdl/mach-vexpress.mdl \\
        -e 'on t.periodic { if (t.cycles > 100100000) exit; }' \\
        -m bbvec \\
        -e 'bbvec.fileBase=\"$bb_dir/$id-bb\";' \\
        -e 'bbvec.intervalSize=100;' \\
        -e 'bbvec.userspaceOnly=0;' \\
        -e 'bbvec.combinePIDs=1;' \\
        -m instr_1 \\
        $linux_dir/sysroot/bin/$T/bootwrapper &> $dir/$id-armv8iss-bb.out \\

    # Clean up after ourselves
    rm -f $checkpoint" > $armv8iss_script
    chmod +x $armv8iss_script

    bsub -K \
      -R "select[sles11]" \
      -oo $dir/$id-armv8iss-bb.lsf \
      -q regression_long_queue \
      $armv8iss_script
  fi


  # Make input file for comparison script
  comparison_input=$dir/$id-bb-comparison.in
  echo "# The top line in this file is the measured bb vector from the checkpoint" > $comparison_input
  echo "# The second line in this file is the corresponding bb vector from those originally collected" >> $comparison_input
  echo "# The subsequent lines in this file are all the other bb vectors from the original run" >> $comparison_input
  grep "^T" $bb_dir/$id-bb-0.bb >> $comparison_input
  grep "^T" $bb_file | tail -n +$simpoint | head -n1 >> $comparison_input
  grep "^T" $bb_file | head -n $(($simpoint - 1)) >> $comparison_input
  grep "^T" $bb_file | tail -n +$(($simpoint + 1)) >> $comparison_input

  validation_file=$dir/$id-bb-validation
  grep "^T" $comparison_input | head -n2 | $BASE_DIR/vector_distance.py > $validation_file
}

function validate_benchmark() {
  local bm=$1

  local bm_tmp=$TMP_DIR/$bm

  mkdir -p $bm_tmp
  cd $bm_tmp

  local bb_file=$(ls -S $DATA_DIR/$bm/$bm-*.bb | head -n 1)
  for checkpoint_file in $(cd $SIMPOINT_DIR/$bm && ls ${bm}-*.ckpt.bz2); do
    local simpoint=$(echo $checkpoint_file | sed -r "s/${bm}-([0-9]+)-[0-9]+.ckpt.bz2/\1/g")
    validate_simpoint $bm_tmp $bm $simpoint $bb_file &
  done
}

function main() {
  set -ex

  mkdir -p $TMP_DIR
  for bm in $(ls $SIMPOINT_DIR); do
    validate_benchmark $bm &
  done
}

main
