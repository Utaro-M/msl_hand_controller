#!/bin/bash

# input_C=(
# "waist"
# "chest"
# )
# output_C=(
# "BASE_LINK"
# "CHEST_LINK0"
# )

input_L=(
"index_link0"
"index_link1"
"midfinger_link0"
"palm_link0"
"thumb_link0"
"thumb_link1"
)
output_wo_LR=(
"INDEX_LINK0"
"INDEX_LINK1"
"MIDFINGER_LINK0"
"PALM_LINK0"
"THUMB_LINK0"
"THUMB_LINK1"
)

function edit_colors() {
  awk -i inplace '{
    if ( $1 == "specularColor" ) {
      $2 = 0.1
      $3 = 0.1
      $4 = 0.1
      print "          " $1 "    " $2 " " $3 " " $4
    } else if ( $1 == "shininess" ) {
      $2 = 0.5
      print "          " $1 "        " $2
    } else if ( $1 == "ambientIntensity" ) {
      $2 = 0.2
      print "          " $1 " " $2
    } else {
      print $0
    }
  }' $1
}

# for i in "${!input_C[@]}"
# do
#   meshlabserver -i .//${input_C[$i]}.wrl -o ${output_C[$i]}.obj       -s ./CAD_mesh/mesh_reduction.mlx -om fc
#   roseus "(load \"package://eus_assimp/euslisp/eus-assimp.l\")" \
#     "(setq glv (load-mesh-file \"${output_C[$i]}.obj\" :scale 1.0))" \
#     "(save-mesh-file \"${output_C[$i]}.wrl\" glv :scale 1.0)" \
#     "(exit)"
#   edit_colors ${output_C[$i]}.wrl
# done

for i in "${!input_L[@]}"
do
  meshlabserver -i ./wrl/${input_L[$i]}.wrl -o L_${output_wo_LR[$i]}.obj  -s ./wrl/mesh_reduction.mlx -om fc
  meshlabserver -i L_${output_wo_LR[$i]}.obj      -o R_${output_wo_LR[$i]}.obj  -s ./wrl/flip_Y.mlx         -om fc
  roseus "(load \"package://eus_assimp/euslisp/eus-assimp.l\")" \
    "(setq glv (load-mesh-file \"L_${output_wo_LR[$i]}.obj\" :scale 1.0))" \
    "(save-mesh-file \"L_${output_wo_LR[$i]}.wrl\" glv :scale 1.0)"\
    "(setq glv (load-mesh-file \"R_${output_wo_LR[$i]}.obj\" :scale 1.0))" \
    "(save-mesh-file \"R_${output_wo_LR[$i]}.wrl\" glv :scale 1.0)"\
    "(exit)"
  edit_colors L_${output_wo_LR[$i]}.wrl
  edit_colors R_${output_wo_LR[$i]}.wrl
done
rm *.obj*
