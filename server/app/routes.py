from app import app
from flask import request
from classification import jeff_nonlinear_svm as svm
import numpy as np
import json


@app.route('/')
@app.route('/index', methods=['POST', 'GET'])
def index():
    if(request.method == 'POST'):
        #data = request.path
        #data = request.method
        #data = request.form['key']
        data = request.form['file']
        data = json.loads(data)
        new = np.array()
        for x in data:
            np.append(new, x)
        print(data)
        svm.process(data)
        #data = svm.extract_data(data)
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
        data = request.form['id']
        return
    elif(request.method == 'GET'):
        # get
        return


@app.route('/classify', methods=['POST', 'GET'])
def classify():
    # do classifying
    if(request.method == 'POST'):
        return
    elif(request.method == 'GET'):
        return


def process(data):
    print("Doing processing...")
