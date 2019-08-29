 #!/bin/bash -e
 
SRC2=/local/mnt/workspace/kasilka/builds/L-latest/64_sup/wl-build/recipes-core/linux/mobile.cfg
SRC1=/local/mnt/workspace/kasilka/builds/L-latest/64_sup/kernel/.config
 
cat ${SRC1} | while read l; do
    grep -q "${l}" ${SRC2} || {
      echo "Configuration option \"${l}\" missing in ${SRC2}"
      false
    }
done

 