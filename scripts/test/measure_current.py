#!/usr/bin/env python
import rospy
import sys
import os
import csv
from sensor_msgs.msg import JointState

##exchange joint_state data to csv
##python plot_joint_states.py "test"
##next execute plot_joint_states.py
class MeasureCurrent():
    def __init__(self, ns="right_hand_controller"):
        self.state_sub = rospy.Subscriber('/' + ns + '/joint_states', JointState, self.state_callback)
        self.time_list = []
        self.position_list = []
        self.velocity_list = []
        self.current_list = []
        rospy.init_node(ns + 'measure', anonymous=True)
        self.r = rospy.Rate(100)

    def state_callback(self, msg):
        self.time_list.append([msg.header.stamp])
        self.position_list.append(msg.position)
        self.velocity_list.append(msg.velocity)
        self.current_list.append(msg.effort)

if __name__ == '__main__':
    print("main")
    args = sys.argv
    namespace = args[1]
    output_file = args[2]
    home_dir = os.path.expanduser('~/')
    try:
        s = MeasureCurrent(namespace)
        rospy.spin()
    except rospy.ROSInterruptException: pass
    if rospy.is_shutdown():
        print("write file")
        with open(os.path.join(os.path.dirname(__file__), home_dir + output_file + "_time.csv"), 'w') as f:
            writer = csv.writer(f)
            writer.writerows(s.time_list)
        with open(os.path.join(os.path.dirname(__file__), home_dir + output_file + "_position.csv"), 'w') as f:
            writer = csv.writer(f)
            writer.writerows(s.position_list)
        with open(os.path.join(os.path.dirname(__file__), home_dir + output_file + "_velocity.csv"), 'w') as f:
            writer = csv.writer(f)
            writer.writerows(s.velocity_list)
        with open(os.path.join(os.path.dirname(__file__), home_dir + output_file + "_current.csv"), 'w') as f:
            writer = csv.writer(f)
            writer.writerows(s.current_list)
