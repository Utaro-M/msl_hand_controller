#!/usr/bin/env python

import rospy
from std_msgs.msg import Float32MultiArray
from std_msgs.msg import MultiArrayDimension

class TestPublisher(object):
    def __init__(self):
        self.rpub = rospy.Publisher('/manus/right_hand/rumble', Float32MultiArray, queue_size=1)
        self.lpub = rospy.Publisher('/manus/left_hand/rumble', Float32MultiArray, queue_size=1)
        self.msg = Float32MultiArray()
        self.dim = MultiArrayDimension()
        self.dim.size = 5
        self.msg.layout.dim = [self.dim ]
        # self.msg.layout.size = 5
        self.flag = 1
        rospy.Timer(rospy.Duration(3), self.pub)

    def pub(self,event):
        if self.flag == 1:
            self.msg.data = [1.0]*5
        else:
            self.msg.data = [0.0]*5
        self.flag *= -1
        self.rpub.publish(self.msg)
        self.lpub.publish(self.msg)

if __name__ == '__main__':
    print("TestPublisher")
    rospy.init_node("test_publisher")
    Test_Publisher_obj = TestPublisher()
    rospy.spin()
