from pynput import mouse
import numpy
import xlrd
import time

from scipy.io import loadmat
#===============================================================#
#   DATE: 2020.12.7
#   FILE: \HASHI
#   NAME: Click.py
#
#   FUNC: 读取temp.mat文件中鼠标信息clickPos，进行模拟鼠标点击
#
#===============================================================#

# 打开mat文件
matData = loadmat(r'temp.mat')

# 读取数据
xLocArray = matData['clickPos'][:,0];
yLocArray = matData['clickPos'][:,1];
clickType = matData['clickPos'][:,2];

# 初始化实例
mouseExp = mouse.Controller()

# 循环
for ii in range(len(clickType)):

    # 移动鼠标
    mouseExp.position = (int(xLocArray[ii]), int(yLocArray[ii]))
    
    # print('\t 点击位置：{0} 属性：{1}'.format((int(xLocArray[ii]), int(yLocArray[ii])),clickType[ii]))
    # time.sleep(0.5)
    
    # 模拟点击
    if(clickType[ii] == 1):
        mouseExp.click(mouse.Button.left, 1)
    elif(clickType[ii] == 2 or clickType[ii] == -1):
        mouseExp.click(mouse.Button.right, 1)
    