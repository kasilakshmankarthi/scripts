 #!/bin/bash -e
test_array=(
"copy"
"scale"
"add"
#"GUPS"
)

test_size=(
1k
2k
4k
8k
16k
32k
64k
128k
256k
512k
1m
2m
4m
8m
10m
12m
14m
16m
32m
40m
}

MAX=$((${#test_array[@]} - 1))
TS=$((${#test_size[@]} - 1))
for i in `seq 0 $MAX`
do
str=${test_array[i]}
echo $str
    for i in `seq 0 $TS`
    do
        ./stream_lite_$str_lin49_x86_64b.exe ${test_size[i]} 10
    done
done
 
 
