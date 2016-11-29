#! /bin/bash
H=../../HDS/PTR3_HVPS/PTR3_HVPS_lib/hdl

for i in *.vhd*; do
  echo
  echo $i
  if [ -f $H/$i ]; then
    diff -b $i $H/$i | grep "^[<>] *[^- ]"
  else
    echo "  $H/$i not found"
  fi
done | less
