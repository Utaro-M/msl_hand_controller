#!/bin/bash
input=all_mass_props_from_solidworks.txt
out=all_mass_props_for_vrml.txt

function get(){
  link_prop=`grep "$1の質量特性:" $input -A 30`
  var=`echo ${link_prop#*$2 = } | cut -d ' ' -f 1`
  echo $var
}

function gen_link_prop(){
  l="\n########## $2 MASS PROPERTY ##########\n"
  l+="mass "
  l+=$(get $1 質量)"\n"
  l+="centerOfMass "
  l+=$(get $1 X)" "
  l+=$(get $1 Y)" "
  l+=$(get $1 Z)"\n"
  l+="momentsOfInertia ["
  l+=$(get $1 Lxx)" "
  l+=$(get $1 Lxy)" "
  l+=$(get $1 Lxz)" "
  l+=$(get $1 Lyx)" "
  l+=$(get $1 Lyy)" "
  l+=$(get $1 Lyz)" "
  l+=$(get $1 Lzx)" "
  l+=$(get $1 Lzy)" "
  l+=$(get $1 Lzz)"]"
  echo -e $l
}
function gen_link_prop_inv(){
  l="\n########## $2 MASS PROPERTY ##########\n"
  l+="mass "
  l+=$(get $1 質量)"\n"
  l+="centerOfMass "
  l+=$(get $1 X)" "
  l+=$(awk "BEGIN {print $(get $1 Y) * -1}")" "
  l+=$(get $1 Z)"\n"
  l+="momentsOfInertia ["
  l+=$(get $1 Lxx)" "
  l+=$(awk "BEGIN {print $(get $1 Lxy) * -1}")" "
  l+=$(get $1 Lxz)" "
  l+=$(awk "BEGIN {print $(get $1 Lyx) * -1}")" "
  l+=$(get $1 Lyy)" "
  l+=$(awk "BEGIN {print $(get $1 Lyz) * -1}")" "
  l+=$(get $1 Lzx)" "
  l+=$(awk "BEGIN {print $(get $1 Lzy) * -1}")" "
  l+=$(get $1 Lzz)"]"
  echo -e $l
}


echo "AUTO GENERATED FILE.  COPY AND PASTE THIS" > $out
gen_link_prop index_link0     R_INDEX_LINK0 >> $out
gen_link_prop index_link1     R_INDEX_LINK1 >> $out
gen_link_prop middle_link0    R_MIDDLE_LINK0>> $out
gen_link_prop palm_link0      R_PALM_LINK0 >> $out
gen_link_prop thumb_link0     R_THUMB_LINK0 >> $out
gen_link_prop thumb_link1     R_THUMB_LINK1 >> $out
gen_link_prop lock_link0      R_LOCK_LINK0 >> $out

gen_link_prop_inv index_link0     L_INDEX_LINK0 >> $out
gen_link_prop_inv index_link1     L_INDEX_LINK1 >> $out
gen_link_prop_inv middle_link0    L_MIDDLE_LINK0>> $out
gen_link_prop_inv palm_link0      L_PALM_LINK0 >> $out
gen_link_prop_inv thumb_link0     L_THUMB_LINK0 >> $out
gen_link_prop_inv thumb_link1     L_THUMB_LINK1 >> $out
gen_link_prop lock_link0          L_LOCK_LINK0 >> $out

echo "Finished, see $out"
