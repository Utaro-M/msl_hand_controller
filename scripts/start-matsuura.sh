#!/bin/bash

source /home/leus/catkin_ws/jaxon_tutorial/devel/setup.bash

source $(rospack find jaxon_ros_bridge)/scripts/upstart/byobu-utils.bash
create-session
# new-window imu `rospack find jaxon_ros_bridge`/scripts/start-imu.sh
# new-window servo `rospack find jaxon_ros_bridge`/scripts/start-servo.sh
# new-window hrpsys `rospack find jaxon_ros_bridge`/scripts/start-hrpsys.sh
# new-window ros-bridge `rospack find jaxon_ros_bridge`/scripts/start-ros-bridge.sh

new-window roscore roscore
new-window imu $(rospack find jaxon_ros_bridge)/scripts/start-imu.sh
new-window servo "(sleep 1 && rosrun trans_vm joint_enable 14 0) & $(rospack find jaxon_ros_bridge)/scripts/start-servo.sh"
# new-window servo "(sleep 1 && rosrun trans_vm joint_enable 14 0) & /home/leus/catkin_ws/jaxon_tutorial/src/trans_system/jaxon_ros_bridge/scripts/start-servo.sh"
new-window hrpsys $(rospack find jaxon_ros_bridge)/scripts/start-hrpsys.sh
new-window ros-bridge $(rospack find jaxon_ros_bridge)/scripts/start-ros-bridge.sh
new-window hand $(rospack find jaxon_ros_bridge)/scripts/enable-bando_hands.sh
#new-window wacoh "wacoh-source && roslaunch --wait trans_vm sample-start-wacoh.launch"
new-window leg-sensor "roslaunch trans_vm jaxon-start-leptrino.launch"
new-window hand-sensor "roslaunch trans_vm jaxon_start_hand_sensor.launch"
new-window msl_right_hand "ssh -t jaxonredvision \"/home/leus/catkin_ws/matsuura/devel/env.sh roslaunch msl_hand_controller right_hand_controllers_startup.launch --wait\""
new-window msl_left_hand "ssh -t jaxonredvision \"/home/leus/catkin_ws/matsuura/devel/env.sh roslaunch msl_hand_controller left_hand_controllers_startup.launch --wait\""

