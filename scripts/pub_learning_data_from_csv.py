#!/usr/bin/env python3

import csv
import rospy
from std_msgs.msg import Float32MultiArray

class DataPublisher(object):
    def __init__(self, csv_file = "./SFS_F1-2022_0105_125454.496.csv"):
        self.csv_file = csv_file
        self.data = []
        self.read_from_csv()
        self.topic_name = ""
        self.msg = Float32MultiArray()
        self.publisher = rospy.Publisher(self.topic_name, Float32MultiArray, queue_size=1)
        rospy.Timer(rospy.Duration(3), self.pub)

    def read_from_csv(self):
        csv_file = open(self.csv_file, "r", encoding="utf8", newline='')
        print(csv_file)
        f = csv.reader(csv_file, delimiter=",", doublequote=True, lineterminator="\r\n", quotechar='"', skipinitialspace=True)
        content = [row for row in f]
        print(content[27])
        for i in range(len(content)):
            print(content[i][0])
            if content[i][0] == '[SENSOR1]':
                data_start = i
                print("data_start = {}".format(data_start))
                break
        self.data = content[data_start+2:]
        print("data len = {}".format(len(data)))

    def pub(self, event):
        f_data = self.content[time_step]
        self.msg.data = f_data
        self.publisher.publish(self.msg)

if __name__ == '__main__':
    print("DataPublisher")
    rospy.init_node("data_publisher")
    Data_Publisher_obj = DataPublisher("./SFS_F1-2022_0105_125454.496.csv")
    rospy.spin()

# f = csv.DictReader(csv_file, delimiter=",", doublequote=False, lineterminator="\r\n", quotechar='"', skipinitialspace=True, fieldnames="t")
# print(type(f))
# content = [row for row in f]
# # print(content[28])
# i=0
# for k in content:
#     print(k)
#     if k['t']=='PC Time(msec)':
#         print("header end")
#         break
#     else:
#         i+=1
# print(i)
# for dic in content[i:]:
#     print(dic)



# f = csv.reader(csv_file, delimiter=",", doublequote=True, lineterminator="\r\n", quotechar='"', sipinitialspace=True)
# print(f[0])

