from app import app
from flask import request
from classification import jeff_nonlinear_svm as svm
import numpy as np
import json
import csv
from werkzeug.datastructures import FileStorage
import urllib
import datetime
import os


@app.route('/')
@app.route('/index', methods=['POST', 'GET'])
def index():
    if(request.method == 'POST'):
        # data = request.path
        # data = request.method
        # data = request.form['key']
        data = request.form['file']
        data = json.loads(data)
        new = np.array()
        for x in data:
            np.append(new, x)
        print(data)
        svm.process(data)
        # data = svm.extract_data(data)
        return data
    elif(request.method == 'GET'):
        return
    return "Hello World!"


@app.route('/train', methods=['POST', 'GET'])
def train():
    """
    Provide id of user and the data(will be entire file i think)
    """
    if(request.method == 'POST'):
        id = request.form['id']
        data = request.form['sample']
        for x in request.files:
            print(x)
        file1 = request.files['file']
        # file1 = request.form['file1']
        print('id = ' + id)
        print('data = ' + data)

        filename = file1.filename
        contents = file1.read()
        print(filename)
        print(contents)
        # print(file1.stream)
        # need this seek to reset pointer
        file1.seek(0)
        trial = 0
        searching = True
        datadir = os.path.join(os.getcwd(), 'data', 'training')
        while(searching):
            found = False
            for file in os.listdir(datadir):
                if('trial='+str(trial) in file):
                    found = True
                    break
            if(found):
                trial += 1
            else:
                searching = False
        print(trial)
        # while(notFound):
        #    for filename in os.listdir(os.path.realpath()
        savename = "./data/training/id=" + str(id) + "_trial=" + str(trial) + \
            "_date=" + str(datetime.datetime.now()) + '.csv'
        print(savename)
        file1.save(savename)

        npdata = np.genfromtxt('./saved_file.csv', delimiter=',',
                               skip_header=1, dtype=float)
        print(npdata)
        svm.process('./saved_file.csv')

        return data
    elif(request.method == 'GET'):
        # get
        return 'get'


@app.route('/classify', methods=['POST', 'GET'])
def classify():
    """
    id and single lines of data
    """
    # do classifying
    if(request.method == 'POST'):
        id = request.form['id']
        data = request.form['sample']
        print('id = ' + id)
        print('data = ' + data)
        return data
    elif(request.method == 'GET'):
        return 'get'


def process(data):
    print("Doing processing...")
