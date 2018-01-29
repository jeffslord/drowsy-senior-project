# Everything here will have to be recreated in ios for the app to do

import requests
from classification import jeff_nonlinear_svm as svm
import numpy as np
import json
import pandas as pd

url = 'http://127.0.0.1:5000/index'
data_url = './data/sample3.csv'
# data = svm.extract_data(data_url)
# datafile = open(data_url, 'rb')
# files = {'upload': datafile}

# data = np.genfromtxt(data_url, delimiter=',', skip_header=1, dtype=float)
# print(data)
# data = data.tolist()
# print(data)
# data = np.array(data)
# print(data)

# The json results in a string so it can't be processed like an array
# data = json.dumps(data)
# data = json.loads(data)
# new = np.array([])
# for x in data:
#     temp = np.array([])
#     for y in x:
#         np.append(temp, y)
#         print(y)
#         print(temp)
#     np.append(new, temp)
# # print(data)
# print(data[0, 1])

# data = {
#     'file': data
# }
# print(data[:, 0])
# print(data)

# r = requests.post(url, data=data)
# print(r.status_code)
# print(r.text)


def classify_test():
    payload = {
        'id': 0,
        'sample': 1
    }
    r = requests.post(url, data=payload)
    print(r.content)
    return


def train_test():
    files = {
        'file': ('upload', open(data_url, 'rb'), 'text/csv')
    }
    payload = {
        'id': 0,
        'sample': 0
    }
    r = requests.post(url, data=payload, files=files)
    print(r.content)
    return


# url = 'http://127.0.0.1:5000/classify'
# classify_test()
url = 'http://127.0.0.1:5000/train'
train_test()
