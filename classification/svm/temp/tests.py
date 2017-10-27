import random

for i in range(1000):
    x = random.uniform(-1000.0, 1000.0)
    y = random.uniform(-1000, 1000)

    if(x > y):
        print("0," + str(x) + "," + str(y))
    elif(y > x):
        print("1," + str(x) + "," + str(y))
