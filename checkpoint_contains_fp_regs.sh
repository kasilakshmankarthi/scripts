#!/bin/bash

if [[ -z $(strings $1 | grep -E "^fpReg\[[0-9]+\]=" | sed -r 's/^fpReg\[[0-9]+\]=//g' | grep -vE "^[0 ]+$") ]]; then
  echo "Checkpoint $1 does not contain any nonzero FP registers"
else
  echo "Checkpoint $1 contains nonzero FP registers (and is affected by HYDRAPE-733)"
fi
