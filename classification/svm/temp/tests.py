import random
import math

for i in range(10000):
    x = random.uniform(-100.0, 100.0)
    y = random.uniform(-100, 100)

    # if(x>0 and y>0):
    #     print("2,"+str(x) + "," + str(y))
    # elif(x > y):
    #     print("0," + str(x) + "," + str(y))
    # elif(y > x):
    #     print("1," + str(x) + "," + str(y))

    if (x > y):
        print("0," + str(x) + "," + str(y))
    elif (y > x):
        print("1," + str(x) + "," + str(y))

    # if(math.sqrt(x*x + y*y) < 100):
    #     print("1," + str(x) + "," + str(y))
    # else:
    #     print("0," + str(x) + "," + str(y))

