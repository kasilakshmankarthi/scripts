#!/bin/bash -e

#SPEC data/bin directory settings
spec2006_bin_dir="/prj/qct/qctps/enablement/benchmark/spec/spec2006_linux/bin/"
spec2006_bin_suffix="_base.lin47BLD2012-09_cortex-a15_arm_neon.elf"
spec2006_data="/prj/qct/qctps/modeling/ral_armv8/workloads/linux/latest/sysroot/share/spec2006"
spec2000_bin_dir="/prj/qct/qctps/enablement/benchmark/spec/spec2000_linux/bin/"
spec2000_bin_suffix="_base.lin47BLD2012-09_cortex-a15_arm_neon.elf"
spec2000_data="/prj/qct/qctps/modeling/ral_armv8/workloads/linux/latest/sysroot/share/spec2000"

#First, gather defaults
spec_bin_dir=$spec2006_bin_dir
spec_bin_suffix=$spec2006_bin_suffix
spec_data=$spec2006_data
spec_version=2006
data_set="ref" #ref, test, or train
tests=$(cd $spec2006_data && ls)
inputs=""
scripts_dir="/prj/qct/qctps/modeling/ral_armv8_scratch/usr/${USER}/specscripts"
simpoints_dir=""
linux_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"/tmp-eglibc

function usage() {
cat << EOF
Usage: $0 OPTIONS

Options:
  -h    Display this help message and exit
  -x    Directory containing benchmark binaries (default: $spec2006_bin_dir)
  -b    Suffix of binaries in -x (default: $spec2006_bin_suffix)
  -s    Scripts directory to store temporary scripts/output files (default: $scripts_dir)
  -d    Directory to store checkpoints and final output (default: $simpoints_dir)
  -t    Name of specific tests to run (i.e. 403.gcc - defaults to all)
  -i    CSV input number(s) to run for test (defaults to all)
  -l    Simulation linux directory (default: $linux_dir)
  -p    SPEC2000 or SPEC2006 (default: SPEC2006)
  -a    Data set to use (i.e. ref, text, train - default: $data_set)
EOF
}

#Keep track of whether the default SPEC binary directories have been changed
#via an option, so we don't overwrite them if we later encounter an option to
#change to SPEC2000
default_tests=true
default_bin_dir=true
default_bin_suffix=true

while getopts "hx:b:s:d:t:i:l:p:a:" OPTION
do
  case $OPTION in
    x)
      spec_bin_dir=$OPTARG
      default_bin_dir=false
      ;;
    b)
      spec_bin_suffix=$OPTARG
      default_bin_suffix=false
      ;;
    s)
      scripts_dir=$OPTARG
      ;;
    d)
      simpoints_dir=$OPTARG
      ;;
    t)
      tests=$OPTARG
      default_tests=false
      ;;
    i)
      inputs=$OPTARG
      ;;
    l)
      linux_dir=$OPTARG
      ;;
    p)
      case $OPTARG in
        SPEC2006|spec2006)
          spec_version=2006
          spec_data=$spec2006_data
          if [[ $default_bin_dir == true ]]; then
            spec_bin_dir=$spec2006_bin_dir
          fi
          if [[ $default_bin_suffix == true ]]; then
            spec_bin_suffix=$spec2006_bin_suffix
          fi
          if [[ $default_tests == true ]]; then
            tests=$(cd $spec2006_data && ls)
          fi
          ;;
        SPEC2000|spec2000)
          spec_version=2000
          spec_data=$spec2000_data
          if [[ $default_bin_dir == true ]]; then
            spec_bin_dir=$spec2000_bin_dir
          fi
          if [[ $default_bin_suffix == true ]]; then
            spec_bin_suffix=$spec2000_bin_suffix
          fi
          if [[ $default_tests == true ]]; then
            tests=$(cd $spec2000_data && ls)
          fi
          ;;
        *)
          echo "Error: -p must be one of SPEC2000, SPEC2006"
          usage
          exit 1
          ;;
      esac
      ;;
    a)
      data_set=$OPTARG
      ;;
    h|?)
      usage
      exit
    ;;
  esac
done

if [[ -z $simpoints_dir ]]; then
  echo "Error: Please supply a directory to place completed checkpoints in."
  usage
  exit 1
fi

target="arm-linux-gnueabihf"
semihosting_cmdline="--kernel $linux_dir/sysroot/boot/$target/Image --dtb $linux_dir/sysroot/boot/rtsm_ve-aemv8a.dtb -- earlyprintk debug norandmaps root=/dev/vda console=ttyAMA0 mem=2048M maxcpus=1 init=/sbin/$target/init virtio_mmio.device=1K@0x1c0d0000:50"
boot_checkpoint=$scripts_dir/$target-busybox-boot.ckpt

[[ -d $scripts_dir ]] || mkdir -p $scripts_dir
[[ -d $simpoints_dir ]] || mkdir -p $simpoints_dir

criu_cmd="criu"
criu_load=""
if [[ -f $scripts_dir/criu ]]; then
  criu_cmd="./$criu_cmd"
  criu_load="angel-load $scripts_dir/criu criu
chmod +x criu"
fi

function create_boot_checkpoint() {
  armv8iss \
    -D linux=linux \
    -D ARGS="\"$semihosting_cmdline\"" \
    -D SIM_TYPE_ARMV8ISS \
    -D CHECKPOINT_PATH=$boot_checkpoint \
    -D SAVE_BOOT_CHECKPOINT \
    -D EXIT_AFTER_CHECKPOINT \
    -D CONSOLE_FILE_OUTPUT \
    -D CONSOLE_FILE_OUTPUT_FILENAME=$scripts_dir/restore.boot \
    -D VBLK_PATH=$linux_dir/deploy/image-minimal.ext2 \
    -f /prj/qct/qctps/modeling/ral_modeling/releases/piface/latest/mdl/mach-vexpress.mdl \
    $linux_dir/sysroot/bin/$target/bootwrapper
}

function generate_head() {
  local script=$1     # path to script to be written
  local bm=$2         # benchmark number and name
  local sbm=${bm/*./} # short benchmark name (no number)

  local cp_cmd="cp -rs /share/spec${spec_version}/$bm/* ."

  #Transforms for benchmarks which don't conform
  #These benchmarks have non-standard binary names
  if [[ $spec_version -eq 2000 ]]; then
    sbm=$(echo $sbm | sed 's/gcc/cc1/')

  elif [[ $spec_version -eq 2006 ]]; then
    sbm=$(echo $sbm | sed 's/sphinx3/sphinx_livepretend/')
    sbm=$(echo $sbm | sed 's/xalancbmk/Xalan/')
  fi
  #These benchmarks crash if their data files aren't writable
  if [[ $bm == "255.vortex" ]] || [[ $bm == "435.gromacs" ]]; then
    cp_cmd="cp -a /share/spec${spec_version}/$bm/${data_set}* . && chmod -R +w ${data_set}*"
  fi

  echo Generating $script
  echo "set -ex
cd /tmp
exe=./${sbm}
angel-load ${spec_bin_dir}${sbm}${spec_bin_suffix} \${exe}
chmod +x $sbm
$criu_load
$cp_cmd" > $script
}

function check_script() {
  local script=$1

  bash -n $script || (echo script && exit)
}

# Generate a script to execute a SPEC benchmark. This script is called both
# when generating basic block vectors ($ff_file="/path/to/fast_forward_file")
# and when capturing CRIU checkpoints based on the collected basic block
# vectors ($ff_file="").
function generate_save_script() {
  if [[ ! $1 || ! $2 || ! $3 || ! $4 ]]; then
    echo "generate_save_script() requires four or five arguments"
    exit 1
  fi

  local dir=$1      # simpoint scripts directory
  local bm=$2       # benchmark name
  local n=$3        # data set number (i.e. line number in $data_set.cmd file)
  local cmd_file=$4 # SPEC .cmd file for this $dataset
  local ff_file=$5  # fast-forward file for this set of simpoints (blank if capturing bb vectors)

  if [[ -z $ff_file ]]; then
    local id=$bm-$n-bb
  else
    local id=$bm-$n-ckpt
  fi
  local script=$dir/$id.save.sh

  generate_head $script $bm
  local cmd=$(head -n $n $cmd_file | tail -n 1 | sed -r "
s///                              # Strip DOS line endings
s/-[eo] [^ ]+ //g                   # Remove any stdout and stderr redirection arguments
s/%BMARK_NAME%//                    # Remove unused naming replacement marker

s/(.*)-c [^ ]+ (.*)/\1\2/           # Remove '-c dir' ('cd dir' added later)" | \
sed -r "
s/(.*)-i ([^ ]+\.(in|config|out)) ?(.*)/\1\4 < \2/ # If benchmark takes input, pass it via shell
                                    # redirection. Only match files with extensions we recognize
                                    # because 454.calculix takes a non-filename -i parameter.
t skip
s% ?$% < /dev/null%                 # If it doesn't take input, pass it /dev/null anyway so it doesn't \
                                    # open a tty, which will mess up CRIU
: skip")

  local cd_cmd=$(sed -nr "$n,$n s/.*-c ([^ ]+) .*/cd \1/p" $cmd_file)
  local criu_cmd_mod=$criu_cmd
  local exe_prefix=""
  if [[ $cd_cmd ]]; then
    exe_prefix="."
    if [[ $criu_cmd =~ "./" ]]; then
      local criu_cmd_mod=".$criu_cmd"
    fi
  fi

  echo "export ff_file=$ff_file
$cd_cmd
set +e

if [[ \$ff_file ]]; then
  angel-load \$ff_file /tmp/$bm-$n.ff
fi

#Start the benchmark in a stopped state
( mypid=\$(exec sh -c 'echo \$PPID'); kill -SIGSTOP \$mypid; exec setsid $cmd &> /tmp/stdio & ) &
initial_pid=\$!

#Attach to the process, fast-forward it to just after it forks, and detach
#leaving it stopped. We break at the fork to ensure that we aren't either
#missing instances of a PC at the beginning of the benchmark process or
#erroneously counting branches at the end of the parent process. We
#intentionally count any instances which occur between the fork and the exec()
#of the benchmark because the basic block vector plugin counted them.
echo \"set follow-fork-mode child
catch fork
continue
continue
continue
signal SIGSTOP
detach
quit\" > /tmp/gdb_script_\${initial_pid}
gdb --batch -x /tmp/gdb_script_\${initial_pid} sh \$initial_pid

#Find the pid of the forked process, which hasn't exec-ed yet
pid=\$(ps -o pid,comm | grep \"sh\" | tail -2 | head -1 | awk '{print \$1}')
#Echo this to a file so we use bbvectors from the correct process
echo \"\$pid\" > /tmp/benchmark_pid

#If we're generating basic block vectors, start the benchmark and let it run
if [[ -z \$ff_file ]]; then
  echo \"continue
continue
continue
quit\"  > /tmp/gdb_script_\${pid}
  gdb --batch -x /tmp/gdb_script_\${pid} ${exe_prefix}\$exe \$pid
else
  #Otherwise, use the fast-forward file to take checkpoints
  cat /tmp/$bm-$n.ff | grep \"^[0-9]\" | while read line
  do
    sp=\$(echo \$line | awk '{print \$1}')
    pc=\$(echo \$line | awk '{print \$3}')
    cnt=\$(echo \$line | awk '{print \$4}')

    # ignore-count = count-1
    let \"cnt--\"

    # Re-attach gdb and break on the next pc
    echo \"break * \$pc
ignore 1 \$cnt
continue
continue
continue
detach
quit\" > /tmp/gdb_script_\${pid}
    gdb --batch -x /tmp/gdb_script_\${pid} ${exe_prefix}\$exe \$pid

    #Take a checkpoint and save it off
    mkdir criudump-\$sp
    $criu_cmd_mod dump -R -t \$pid -vvv -o dump-\$sp.log -D criudump-\$sp && echo OK
    tar -cf criudump-\$sp.tar criudump-\$sp
    angel-store criudump-\$sp.tar $dir/$id.criudump-\$sp.tar
    rm criudump-\$sp.tar
    rm -rf criudump-\$sp
  done
fi

#Save off any files we generated
for f in *; do
  if [[ -f \$f && ! -L \$f ]]; then
    angel-store \$f $dir/$id.save-\$f
  fi
done
angel-store /tmp/stdio $dir/$id.save.stdio
angel-store /tmp/benchmark_pid $dir/$id.save.benchmark_pid" >> $script
  check_script $script
}

# Run a script generated by generate_save_script() on the AEM on LSF. Takes the
# same parameters as generate_save_script() except for $cmd_file.
function run_save_script() {
  if [[ ! $1 || ! $2 || ! $3 ]]; then
    echo "run_save_script() requires three or four arguments"
    exit 1
  fi

  local dir=$1      # simpoint scripts directory
  local bm=$2       # benchmark name
  local n=$3        # data set number (i.e. line number in $data_set.cmd file)
  local ff_file=$4  # fast-forward file for this set of simpoints (blank if capturing bb vectors)

  if [[ -z $ff_file ]]; then
    local id=$bm-$n-bb
  else
    local id=$bm-$n-ckpt
  fi
  local script=$dir/$id.save.sh
  local isim_script=$dir/$id.isim.sh
  local isim_out=$dir/$id.isim.out

  #If BBVecTrace.so is in $dir, use it instead of the version in $linux_dir
  if [[ -f $dir/BBVecTrace.so ]]; then
    bbvec_plugin=$dir/BBVecTrace.so
  elif [[ -f $linux_dir/sysroot/lib/x86_64-linux-gnu/BBVecTrace.so ]]; then
    bbvec_plugin=$linux_dir/sysroot/lib/x86_64-linux-gnu/BBVecTrace.so
  else
    echo "Error: BBVecTrace.so not found in $linux_dir/sysroot/lib/x86_64-linux-gnu or $dir"
    exit 1
  fi

  local trace=""
  if [[ -z $ff_file ]]; then
    trace="--plugin=$bbvec_plugin \\
      -C TRACE.BBVecTrace.interval-size=100 \\
      -C TRACE.BBVecTrace.bbvec-file-base=$dir/$id \\
      -C TRACE.BBVecTrace.user-only=1"
  fi


  local isim_system_full_path=$(which isim_system)
  local isim_cmd="$linux_dir/sysroot/lib/x86_64-linux-gnu/ld-linux.so.2 \\
      --library-path $linux_dir/sysroot/lib/x86_64-linux-gnu \\
      $isim_system_full_path \\
      --stat \\
      -C cluster.NUM_CORES=1 \\
      -C cluster.cpu0.CONFIG64=0 -C cluster.cpu1.CONFIG64=0 -C cluster.cpu2.CONFIG64=0 -C cluster.cpu3.CONFIG64=0 \\
      -C motherboard.vis.disable_visualisation=1 \\
      -C motherboard.terminal_0.start_telnet=0 \\
      -C motherboard.pl011_uart0.out_file=$dir/$id.save.uart \\
      -C motherboard.virtioblockdevice.image_path=$linux_dir/deploy/image-minimal.ext2 \\
      -C motherboard.virtioblockdevice.read_only=1 \\
      -C cluster.cpu0.semihosting-cmd_line=\"$semihosting_cmdline script=$script\" \\
      $trace \\
      $linux_dir/sysroot/bin/$target/bootwrapper"

  echo "#Loop in case we don't get the license we need on the first try
source /prj/qct/qctps/modeling/ral_armv8/env/armv8.sh
output=\"This string is non-empty to start - to force at least one iteration of this loop\"
while [[ -n \$output ]]; do
  $isim_cmd &> $isim_out
  output=\$(grep -i \"license check failed\" $isim_out)
  if [[ -n \$output ]]; then
    sleep 5m
  fi
done" > $isim_script
  check_script $isim_script
  chmod +x $isim_script

  echo Running $script

  bsub -K \
    -R "select[sles11] && rusage[aem_armv8_ve=1]" \
    -oo $dir/$id.save.lsf \
    -q regression_long_queue \
    $isim_script
}

function generate_restore_script() {
  local dir=$1
  local bm=$2
  local n=$3
  local sp=$4
  local pid=$5
  local cmd_file=$6

  local ckpt_id=$bm-$n-ckpt
  local script=$dir/$bm-$n-$sp.restore.sh

  generate_head $script $bm
  echo "set +e" >> $script

  #Load the CRIU checkpoint, untar it, and restore it (in the stopped state)
  echo "angel-load $dir/$ckpt_id.criudump-$sp.tar criudump-$sp.tar" >> $script
  echo "tar -xf criudump-$sp.tar" >> $script

  #If the benchmark cd's before executing, we will as well
  local cd_cmd=$(sed -nr "$n,$n s/.*-c ([^ ]+) .*/cd \1/p" $cmd_file)
  echo $cd_cmd >> $script

  #Load all the files used when checkpointing, so they are available to the restored process
  local path
  for path in $dir/$ckpt_id.save-* $dir/$ckpt_id.save.stdio; do
    local bn=$(basename $path)
    local f=${bn#$ckpt_id.save-}
    [[ $bn != $ckpt_id.save.stdio ]] || f=/tmp/stdio
    echo "[[ -f $f ]] || angel-load $path $f" >> $script
  done

  #Add special cases for benchmarks which desire special treatment only for the
  #CRIU checkpointing run
  if [[ $bm == "300.twolf" ]]; then
    #300 twolf requires that this file exists, even though it doesn't 'cd' into
    #the $data_set directory (we save/restore all files from only the directory
    #the benchmark ran in)
    echo "touch /tmp/$data_set/$data_set.out" >> $script
  fi

  #If we're using a relative criu command and changing directories, update the relative criu_cmd
  local criu_cmd_mod=$criu_cmd
  if [[ $cd_cmd ]] && [[ $criu_cmd =~ "./" ]]; then
    local criu_cmd_mod=".$criu_cmd"
  fi
  echo "$criu_cmd_mod restore -v2 -d -D /tmp/criudump-$sp" >> $script

  check_script $script
}

function generate_conversion_script() {
  local dir=$1
  local bm=$2
  local n=$3
  local sp=$4
  local pid=$5
  local cmd_file=$6

  generate_restore_script $dir $bm $n $sp $pid $cmd_file

  local script=$dir/$bm-$n-$sp.restore.sh

  #Trigger the armv8iss cntpid module to begin counting instructions (we don't
  #start counting before the 'criu restore' command completes, so we skip the
  #parasite instructions) and start the benchmark process.
  echo "angel-syscall 0x100 20" >> $script
  echo "kill -SIGCONT $pid" >> $script
  #Don't angel-exit when this script completes
  echo "export INTERACTIVE=true" >> $script

  check_script $script
}

function run_conversion_script() {
  local dir=$1
  local ckpt_dir=$2
  local bm=$3
  local n=$4
  local sp=$5
  local dist=$6
  local pid=$7
  local weight=$8

  local id=$bm-$n-$sp
  local script=$dir/$id.restore.sh
  local ckpt_id=$bm-$n-ckpt

  local tar=$dir/$ckpt_id.criudump-$sp.tar
  if [[ ! -f $tar ]] || [[ ! -s $tar ]]; then
    echo "Error: $tar missing or size 0, can't convert to armv8tk checkpoint"
    exit 1
  fi

  echo Running $script
  bsub -K \
    -R "type==LINUX64" \
    -oo $dir/$id.convert.lsf \
    -q regression_long_queue \
    armv8iss \
      -D linux=linux \
      -D ARGS="\"$semihosting_cmdline\"" \
      -D SIM_TYPE_ARMV8ISS \
      -D LOAD_CHECKPOINT=$boot_checkpoint \
      -D CONSOLE_FILE_OUTPUT \
      -D CONSOLE_FILE_OUTPUT_FILENAME=$dir/$id.convert.uart \
      -D VBLK_PATH=$linux_dir/deploy/image-minimal.ext2 \
      -D SCRIPT=$script \
      -f /prj/qct/qctps/modeling/ral_modeling/releases/piface/latest/mdl/mach-vexpress.mdl \
      -m cntpid \
      -D CHECKPOINT_PID=$pid \
      -D CHECKPOINT_AFTER=$dist \
      -D CHECKPOINT_PATH=$ckpt_dir/${id}-${weight}.ckpt \
      -D EXIT_AFTER_CHECKPOINT \
      -f /prj/qct/qctps/modeling/ral_armv8/modeling/releases/armv8tk/latest/mdl/checkpoint_after_pid_instrs.mdl \
      $linux_dir/sysroot/bin/$target/bootwrapper
}


function compress_checkpoint() {
  local ckpt_dir=$1
  local bm=$2
  local n=$3
  local sp=$4
  local weight=$5

  local id=$bm-$n-$sp
  local checkpoint=${ckpt_dir}/${id}-${weight}.ckpt

  if [[ ! -f ${checkpoint} ]] || [[ ! -s ${checkpoint} ]]; then
    echo "Error: $checkpoint missing or size 0, can't compress"
    exit 1
  fi

  bsub -K \
    -R "type==LINUX64" \
    -oo $dir/$id.compress.lsf \
    -q regression_queue \
    bzip2 $checkpoint
}

# Convert CRIU checkpoints to armv8tk checkpoints
function generate_armv8tk_checkpoints() {
  if [[ ! $1 || ! $2 || ! $3 || ! $4 || ! $5 ]]; then
    echo "generate_armv8tk_checkpoints() requires five arguments"
    exit 1
  fi

  local dir=$1      # simpoint scripts directory
  local ckpt_dir=$2 # directory to store checkpoints in
  local bm=$3       # benchmark name
  local n=$4        # data set number (i.e. line number in $data_set.cmd file)
  local cmd_file=$5 # path to the $data_set.cmd file
  local pid=$6      # pid of the process we're checkpointing

  local ff_file=${dir}/${bm}-${n}-bb.ff
  local wait_pids=""

  cat $ff_file | grep "^[0-9]" | while read line; do
    local sp=$(echo $line | awk '{print $1}')
    local dist=$(echo $line | awk '{print $5}')
    local criu_ckpt=${dir}/${bm}-${n}-ckpt.criudump-${sp}.tar
    local weight=$(sed -nr "2,$ s/^$sp[ \t]+([01])\.([0-9]{4})[ \t]+.*/\1\2/p" ${dir}/$bm-$n-bb-*.combined)

    ( generate_conversion_script $dir $bm $n $sp $pid $cmd_file
    run_conversion_script $dir $ckpt_dir $bm $n $sp $dist $pid $weight
    compress_checkpoint $ckpt_dir $bm $n $sp $weight ) &
    wait_pids="$wait_pids $!"
  done

  wait $wait_pids
}

# Generate all the CRIU checkpoints for one input set of one benchmark
function generate_checkpoints() {
  if [[ ! $1 || ! $2 || ! $3 || ! $4 || ! $5 ]]; then
    echo "generate_checkpoints() requires five arguments"
    exit 1
  fi

  local dir=$1        # simpoint scripts directory
  local bm=$2         # benchmark name
  local n=$3          # data set number (i.e. line number in $data_set.cmd file)
  local cmd_file=$4   # path to the $data_set.cmd file
  local result_var=$5 # variable name to store pid in before returning

  local ff_file=${dir}/$bm-$n-bb.ff

  generate_save_script $dir $bm $n $cmd_file $ff_file
  run_save_script $dir $bm $n $ff_file

  # Find the benchmark process' pid and save it to the variable named in $result_var
  local pid=$(cat $dir/$bm-$n-ckpt.save.benchmark_pid)
  eval $result_var="'$pid'"
}

function generate_fast_forward() {
  if [[ ! $1 || ! $2 || ! $3 || ! $4 ]]; then
    echo "generate_fast_forward() requires four arguments"
    exit 1
  fi

  local dir=$1 # simpoint scripts directory
  local bm=$2  # benchmark name
  local n=$3   # data set number (i.e. line number in $data_set.cmd file)
  local pid=$4 # PID of the benchmark process

  local bb_basename=${dir}/$bm-$n-bb-$pid
  local ff_file=${dir}/$bm-$n-bb.ff

  echo "Generating fast-forward file for ${bb_basename}.bb"

  # Get CSV list of simpoints
  local simpoints_list=$(cat ${bb_basename}.combined | tail -n +2 | awk '{print $1}' | sort -n | tr '\n' ',' | sed 's/,$//g')

  # Generate the fast-forward information for collecting the simpoints
  bsub -K \
    -R "select[type==LINUX64] rusage[mem=30000]" \
    -oo ${ff_file}.lsf \
    -q regression_queue \
    "$linux_dir/sysroot/bin/x86_64-linux-gnu/genfastfwd.pl --bbvec=${bb_basename}.bb --simpoints=${simpoints_list} > ${ff_file}"
}

function run_simpoint_tool() {
  if [[ ! $1 || ! $2 || ! $3 || ! $4 ]]; then
    echo "run_simpoint_tool() requires four arguments"
    exit 1
  fi

  local dir=$1 # simpoint scripts directory
  local bm=$2  # benchmark name
  local n=$3   # data set number (i.e. line number in $data_set.cmd file)
  local pid=$4 # PID of the benchmark process

  local bb_basename=${dir}/$bm-$n-bb-$pid

  echo "Running simpoint tool on ${bb_basename}.bb"

  #Fixup the .bb format to that expected by runsimpoint, renaming it (.bb => .std.bb)
  cat ${bb_basename}.bb | $linux_dir/sysroot/bin/x86_64-linux-gnu/standardize_bbvs.pl > ${bb_basename}.std.bb

  #Actually run the simpoint tool
  $linux_dir/sysroot/bin/x86_64-linux-gnu/runsimpoint ${bb_basename}.std.bb $dir

  #Combine the output to be used later
  $linux_dir/sysroot/bin/x86_64-linux-gnu/unify_simpoints.sh ${bb_basename}.std.simpoints ${bb_basename}.std.weights 100000000 0.9 > ${bb_basename}.combined
}

function generate_bbvectors() {
  if [[ ! $1 || ! $2 || ! $3 || ! $4 || ! $5 ]]; then
    echo "generate_bbvectors() requires five arguments"
    exit 1
  fi

  local dir=$1        # simpoint scripts directory
  local bm=$2         # benchmark name
  local n=$3          # data set number (i.e. line number in $data_set.cmd file)
  local cmd_file=$4   # path to the $data_set.cmd file
  local result_var=$5 # variable name to store pid in before returning

  generate_save_script $dir $bm $n $cmd_file ""
  run_save_script $dir $bm $n ""

  # Find the benchmark process' pid and save it to the variable named in $result_var
  local pid=$(cat $dir/$bm-$n-bb.save.benchmark_pid)
  eval $result_var="'$pid'"
}

# Walk through the process of generating all the simpoints for one input for
# one benchmark. Do everything from generating basic block vectors to
# generating the final checkpoints.
function generate_simpoints() {
  if [[ ! $1 || ! $2 || ! $3 ]]; then
    echo "generate_simpoints() requires three arguments"
    exit 1
  fi

  local bm=$1       # benchmark name
  local n=$2        # data set number (i.e. line number in $data_set.cmd file)
  local cmd_file=$3 # path to the $data_set.cmd file

  generate_bbvectors $scripts_dir $bm $n $cmd_file bbvector_pid
#  get_benchmark_instruction_count $scripts_dir $bm $n $bbvector_pid
  run_simpoint_tool $scripts_dir $bm $n $bbvector_pid
  generate_fast_forward $scripts_dir $bm $n $bbvector_pid
  generate_checkpoints $scripts_dir $bm $n $cmd_file ckpt_pid
  generate_armv8tk_checkpoints $scripts_dir $simpoints_dir $bm $n $cmd_file $ckpt_pid
  #TODO validation
}

function generate_all_simpoints() {

  #Do this before attempting to generate any of the simpoints so multiple
  #processes aren't all generating a new boot checkpoint
  if [[ ! -f $boot_checkpoint ]]; then
    create_boot_checkpoint
  fi

  for tst in $tests; do
    local dir=$spec_data/$tst
    local bm=$(basename $dir)
    local cmd_file=$dir/$data_set.cmd

    if [[ ! -f $cmd_file ]]; then
      echo "Error: $cmd_file does not exist"
      exit 1
    fi

    #Kick off one simpoint-generation run per line in this benchmark's $data_set input file
    for n in $(seq 1 $(wc -l $cmd_file | cut -d ' ' -f 1)); do
      #If the user specified certain inputs to be run, only run those
      if [[ -z $inputs ]] || [[ $( echo $inputs | grep -E "(^|,)$n($|,)" ) ]]; then
        generate_simpoints $bm $n $cmd_file &
      fi
    done
  done
}

source /prj/qct/qctps/modeling/ral_armv8/env/armv8.sh
generate_all_simpoints
