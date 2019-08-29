echo 0 >  /sys/devices/system/cpu/cpu1/online
echo 0 >  /sys/devices/system/cpu/cpu2/online
echo 0 >  /sys/devices/system/cpu/cpu3/online
echo 0 >  /sys/devices/system/cpu/cpu4/online
echo 0 >  /sys/devices/system/cpu/cpu5/online
echo 0 >  /sys/devices/system/cpu/cpu6/online
echo 0 >  /sys/devices/system/cpu/cpu7/online
echo 0 >  /sys/devices/system/cpu/cpu8/online
echo 0 >  /sys/devices/system/cpu/cpu9/online

if false
then
echo 1 >  /sys/devices/system/cpu/cpu1/online
echo 1 >  /sys/devices/system/cpu/cpu2/online
echo 1 >  /sys/devices/system/cpu/cpu3/online
echo 1 >  /sys/devices/system/cpu/cpu4/online
echo 1 >  /sys/devices/system/cpu/cpu5/online
echo 1 >  /sys/devices/system/cpu/cpu6/online
echo 1 >  /sys/devices/system/cpu/cpu7/online
echo 1 >  /sys/devices/system/cpu/cpu8/online
echo 1 >  /sys/devices/system/cpu/cpu9/online
fi

#cpufreq-set -g performance -u $1 -d $1 -c0
#cpufreq-set -g performance -u $1 -d $1 -c1
#cpufreq-set -g performance -u $1 -d $1 -c2
#cpufreq-set -g performance -u $1 -d $1 -c3
#cpufreq-set -g performance -u $1 -d $1 -c4
#cpufreq-set -g performance -u $1 -d $1 -c5
#cpufreq-set -g performance -u $1 -d $1 -c6
#cpufreq-set -g performance -u $1 -d $1 -c7

