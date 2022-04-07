#!/usr/bin/env python
import sys
import os
import csv
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

## first, execute measure_current.py
## python plot_joint_states.py "test" "current"
## python plot_joint_states.py target_dir "current"

class Plot():
    def __init__(self,target_dir):
        time_csv = pd.read_csv(os.path.join(os.path.dirname(__file__), target_dir + output_file + "_time" + ".csv"))
        position_csv = pd.read_csv(os.path.join(os.path.dirname(__file__), target_dir + output_file + "_position" + ".csv"))
        velocity_csv = pd.read_csv(os.path.join(os.path.dirname(__file__), target_dir + output_file + "_velocity" + ".csv"))
        current_csv = pd.read_csv(os.path.join(os.path.dirname(__file__), target_dir + output_file + "_current" + ".csv"))
        self.time_data = time_csv[time_csv.keys()[0]].values# .tolist()
        self.position_data = (position_csv[position_csv.keys()[0:6]]).values# .tolist()
        self.velocity_data = velocity_csv[velocity_csv.keys()[0:6]].values# .tolist()
        self.current_data = current_csv[current_csv.keys()[0:6]].values# .tolist()
        self.time = (self.time_data - self.time_data[0]) *10**(-9)

    def plot_current(self):
        plt.title("current")
        plt.xlabel("time stamp[s]")
        plt.ylabel("current[mA]")
        for i in range (self.current_data[0].shape[0]):
            plt.plot(self.time, self.current_data[:,i], label=str(i))
        plt.legend()
        plt.show()

    def plot_position(self):
        plt.title("position")
        plt.xlabel("time stamp[s]")
        plt.ylabel("position[rad?]")
        for i in range (len(self.position_data[0])):
            plt.plot(self.time, self.position_data[:,i], label=str(i))
        plt.legend()
        plt.show()

    def plot_velocity(self):
        plt.title("velocity")
        plt.xlabel("time stamp[s]")
        plt.ylabel("velocity[m/s?]")
        for i in range (len(self.velocity_data[0])):
            plt.plot(self.time, self.velocity_data[:,i], label=str(i))
        plt.legend()
        plt.show()

if __name__ == '__main__':
    args = sys.argv
    if len(args)<2:
        print("please input 2 args")
        exit
    output_file = args[1]
    target_dir = os.path.expanduser('~/dynamixel_data/')
    s=Plot(target_dir)
    if args[2]=="position":
        s.plot_position()
    elif(args[2]=="velocity"):
        s.plot_velocity()
    elif(args[2]=="current"):
        s.plot_current()
