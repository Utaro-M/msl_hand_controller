#!/usr/bin/env python

import sys
import yaml
import rospy
from control_msgs.msg import FollowJointTrajectoryAction
from control_msgs.msg import FollowJointTrajectoryFeedback
from control_msgs.msg import FollowJointTrajectoryResult
import actionlib
from trajectory_msgs.msg import JointTrajectory
from trajectory_msgs.msg import JointTrajectoryPoint
from dynamixel_workbench_msgs.msg import DynamixelStateList
import math

class DynamixelJointTrajectoryServer():
    _feedback = FollowJointTrajectoryFeedback()
    _result = FollowJointTrajectoryResult()
    _namespace = None
    _conf_file = None
    _joint_names = None

    def __init__(self, ns, conf, min_max_file):
        self._namespace = ns
        self._conf_file = conf
        self._min_max_file = min_max_file
        self.min_max_flag = True
        rospy.init_node(ns + '_server', anonymous=True)
        self.r = rospy.Rate(100)
        self.server = actionlib.SimpleActionServer('/' + ns + '/follow_joint_trajectory_action', FollowJointTrajectoryAction, self.execute, False)
        self.server.start()
        self.joint_command_pub = rospy.Publisher('/' + ns + '/joint_trajectory', JointTrajectory, queue_size=2)
        self.dynamixel_state_sub = rospy.Subscriber('/' + ns + '/dynamixel_state', DynamixelStateList, self.state_callback)
        self.interpolatingp = False
        with open(self._conf_file) as f:
            yml = yaml.load(f, Loader=yaml.FullLoader)
            self._joint_names = yml.keys()
            self._current_limit = [yml[yml.keys()[0]]["Current_Limit"],
                                   yml[yml.keys()[1]]["Current_Limit"],
                                   yml[yml.keys()[2]]["Current_Limit"],
                                   yml[yml.keys()[3]]["Current_Limit"],
                                   yml[yml.keys()[4]]["Current_Limit"],
                                   yml[yml.keys()[5]]["Current_Limit"]]
        with open(self._min_max_file) as f:
            self.min_max_yml = yaml.load(f, Loader=yaml.FullLoader)

    def execute(self, goal):
        self.min_max_flag = True
        success = True
        pub_msg = JointTrajectory()
        pub_msg.header = goal.trajectory.header
        pub_msg.joint_names = self._joint_names
        hand_thumb_roll_id  = goal.trajectory.joint_names.index(self._joint_names[0])
        hand_thumb_pitch_id = goal.trajectory.joint_names.index(self._joint_names[1])
        hand_index_yaw_1_id = goal.trajectory.joint_names.index(self._joint_names[2])
        hand_index_yaw_2_id = goal.trajectory.joint_names.index(self._joint_names[3])
        hand_middle_yaw_id  = goal.trajectory.joint_names.index(self._joint_names[4])
        hand_lock_id = goal.trajectory.joint_names.index(self._joint_names[5])
        pub_msg.points = []
        wait_time = 0.0
        for p in goal.trajectory.points:
            point = JointTrajectoryPoint()
            if len(p.positions) != 0:
                i =0
                for pos in p.positions:
                    if (self.min_max_yml[self._joint_names[i]]["Min_Pos"] / 180.0 * math.pi)  <= pos and pos <= (self.min_max_yml[self._joint_names[i]]["Max_Pos"] / 180.0 * math.pi):
                        pass
                    else:
                        rospy.logerr('%s: %s is MIN MAX OVER ! (check config/*_min_max.yaml)' , self._joint_names[i], str(pos))
                        self.min_max_flag = False
                    i+=1
                point.positions = [
                    p.positions[hand_thumb_roll_id],
                    p.positions[hand_thumb_pitch_id],
                    p.positions[hand_index_yaw_1_id],
                    p.positions[hand_index_yaw_2_id],
                    p.positions[hand_middle_yaw_id],
                    p.positions[hand_lock_id]]
            if len(p.velocities) != 0:
                point.velocities = [
                    p.velocities[hand_thumb_roll_id],
                    p.velocities[hand_thumb_pitch_id],
                    p.velocities[hand_index_yaw_1_id],
                    p.velocities[hand_index_yaw_2_id],
                    p.velocities[hand_middle_yaw_id],
                    p.velocities[hand_lock_id]]
            if len(p.effort) != 0:
                point.effort = [
                    p.effort[hand_thumb_roll_id] * self._current_limit[0],
                    p.effort[hand_thumb_pitch_id] * self._current_limit[1],
                    p.effort[hand_index_yaw_1_id] * self._current_limit[2],
                    p.effort[hand_index_yaw_2_id] * self._current_limit[3],
                    p.effort[hand_middle_yaw_id] * self._current_limit[4],
                    p.effort[hand_lock_id] * self._current_limit[5]]
            else:
                point.effort = [
                    1.0 * self._current_limit[0],
                    1.0 * self._current_limit[1],
                    1.0 * self._current_limit[2],
                    1.0 * self._current_limit[3],
                    1.0 * self._current_limit[4],
                    1.0 * self._current_limit[5]]
            point.time_from_start = p.time_from_start
            pub_msg.points.append(point)
            wait_time = p.time_from_start.to_sec()
        start_time = rospy.get_rostime()
        if self.min_max_flag:
            self.joint_command_pub.publish(pub_msg)
        while True:
            now = rospy.get_rostime()
            if self.server.is_preempt_requested():
                rospy.loginfo('%s: Preempted' % "Hand")
                self.server.set_preempted()
                success = False
                break
            if ((now - start_time).to_sec() > wait_time) and (not self.interpolatingp):
                break
            self.r.sleep()

        if success:
            self._result.error_code = FollowJointTrajectoryResult.SUCCESSFUL
            self.server.set_succeeded(self._result)

    def state_callback(self, msg):
        if msg.dynamixel_state == []:
            self.interpolatingp = True
        else:
            self.interpolatingp = False

if __name__ == '__main__':
    args = sys.argv
    namespace = args[1]
    conf_file = args[2]
    min_max_file = args[3]

    try:
        s = DynamixelJointTrajectoryServer(namespace, conf_file, min_max_file)
        rospy.spin()
    except rospy.ROSInterruptException: pass
