import numpy as np
from sklearn import svm, datasets
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from scipy import fftpack
import matplotlib.pyplot as plt
from sklearn.externals import joblib
import optunity
import optunity.metrics
import pandas as pd
import math
import os
import sys
file_path = os.path.abspath(__file__)
file_path = os.path.dirname(os.path.dirname(file_path))
print("[INFO] " + file_path)
sys.path.insert(0, file_path)
from data_process import data_processing as dp

USE_FFT = True
NORMALIZE = True
USER_ID = "264"
NUM_CLASSES = 2
DATA_DIR = os.path.join(file_path, "data", "output_organized.csv")


data = dp.extract_data(DATA_DIR, USER_ID)
if(len(data) == 0):
    print("[ERROR] Data is empty.")
x_data, y_data = dp.separate_data(data, 1, 3, 50)
if(NORMALIZE):
    x_data, min_val, max_val = dp.normalize(x_data)
if(USE_FFT):
    x_data = fftpack.fft(x_data)
    x_data_rt, x_data_real_imag = dp.process_fft_data(x_data)
    x_data = x_data_rt
# x_data, y_data = dp.separate_data(data)
y_data = y_data.astype(dtype=np.int)
print("[INFO] Train test split... ")
x_train, x_test, y_train, y_test = train_test_split(
    x_data, y_data, test_size=0.2)
print("[INFO] x_data shape: " + str(x_data.shape))
print("[INFO] y_data shape: " + str(y_data.shape))
_z, num_features = x_data.shape


@optunity.cross_validated(x=x_data, y=y_data, num_folds=10, num_iter=2)
def svm_auc(x_train, y_train, x_test, y_test, logC, logGamma):
    svc = svm.SVC(
        kernel='rbf',
        C=10**logC,
        gamma=10**logGamma,
    )
    svc = svc.fit(x_train, y_train)
    decision_values = svc.decision_function(x_test)
    auc = optunity.metrics.roc_auc(y_test, decision_values)
    return auc


hps, info, _ = optunity.maximize(
    svm_auc, num_evals=50, logC=[-10, 10], logGamma=[-5, 1])
print(hps)
print(info)
svc = svm.SVC(
    C=10 ** hps['logC'],
    gamma=10 ** hps['logGamma']
).fit(x_train, y_train)


# svc = svm.SVC(
#     kernel='rbf',
#     C=1.0,
#     gamma='auto',
#     max_iter=-1,
#     decision_function_shape='ovr',
#     degree=3,
#     coef0=0.0,
#     probability=True,
#     shrinking=True,
#     verbose=True)
# svc = svc.fit(x_train, y_train)


# EXPORT
print("[INFO] Creating Model...")
model_dir = os.path.join(file_path, "data", "models", "svm_" + USER_ID)
if(USER_ID == ""):
    model_dir += "ALL"
if(USE_FFT):
    model_dir += "_FFT"
else:
    model_dir += "_RAW"
if(NORMALIZE):
    model_dir += "_NORMALIZED"
joblib.dump(svc, model_dir + '.pkl')
# END EXPORT

# PREDICT
prediction = svc.predict(x_test)
accuracy = accuracy_score(y_test, prediction)
print(prediction)
print("\nAccuracy: {0:f}\n".format(accuracy))
