from pynput import mouse
import numpy
import os.path
from scipy.io import savemat

#===============================================================#
#   DATE: 2020.12.7
#   FILE: \HASHI
#   NAME: Apex4.py
#
#   FUNC: 读取4次右键坐标，传值apex至temp.mat文件中
# 	NOTE: 与\NONOGRAM下同名文件一致
#===============================================================#



# 全局变量，确定4个端点位置
xyLoc = numpy.zeros((4,2))
# 全局变量，确定鼠标点击次数
curIndex = 0


def my_on_click(x, y, button, pressed):
    global xyLoc
    global curIndex
    # 显示
    # print(button)
    if pressed and button == mouse.Button.right:
        # 顶点位置数组赋值    
        xyLoc[curIndex,:] = [x,y]
        curIndex = curIndex + 1
        print('\t 第{0}个有效点位置：{1}'.format(curIndex,(x,y)))
    else:
        # Stop listener
        return False
 
while curIndex < 4:
    with mouse.Listener(on_click=my_on_click) as listener:
        listener.join()
        
# print(xyLoc)

# An example:
# [[136. 264.]
 # [145. 964.]
 # [843. 970.]
 # [845. 260.]]

savemat(r'temp.mat', mdict = {'apex':xyLoc})

# 显示
print('\t端点位置成功写入temp.mat文件。')

