from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from sklearn.model_selection import train_test_split

import os
import urllib

import numpy as np
import tensorflow as tf
import pandas as pd
import csv
import math

USE_FFT = True
USER_ID = "264"
# USER_ID = ""
NUM_CLASSES = 2
FFT_DIR = "output_fft.csv"
ORG_DIR = "output_organized.csv"


def extract_data(data_dir, user_id=None):
    print("[INFO] Extracting data...")

    df = pd.read_csv(data_dir, na_values=0.0)
    df = df.fillna(0)
    df_matrix = df.as_matrix()

    data_filtered = []
    if(user_id != ""):
        for x in df_matrix:
            if(str(x[0]) == user_id):
                data_filtered.append(x)
        print("[INFO] " + user_id + " contains: " +
              str(len(data_filtered)) + " records.")
    else:
        data_filtered = df_matrix
        print("[INFO] Total Records: " + str(len(df_matrix)) + ".")
    return np.array(data_filtered)


def separate_data(data, y_col=1, x_start_col=3, x_features=50):
    print("[INFO] Separating X and Y data...")
    x = []
    y = []
    for row in data:
        x.append(row[x_start_col:x_features+x_start_col])
        y.append(row[y_col])
    return np.array(x), np.array(y)


def process_fft_data(x_data):
    print("[INFO] Processing fft data... ")
    x_data_rt = []
    x_data_real_imag = []
    for row in x_data:
        rt_row = []
        real_image_row = []
        for cell in row:
            cp = complex(cell)
            sq = pow(cp.real, 2) + pow(cp.imag, 2)
            rt = math.sqrt(sq)
            if(cell == '0j'):
                rt = 0.0
            rt_row.append(rt)
            real_image_row.append(cp.real)
            real_image_row.append(cp.imag)
        x_data_rt.append(rt_row)
        x_data_real_imag.append(real_image_row)

    return np.array(x_data_rt), np.array(x_data_real_imag)


def serving_input_receiver_fn():
    serialized_tf_example = tf.placeholder()


def process():
    # Split data into training and testing,
    if(USE_FFT):
        DATA_DIR = FFT_DIR
    else:
        DATA_DIR = ORG_DIR
    data = extract_data(DATA_DIR, USER_ID)
    print("[INFO] Data shape: " + str(data.shape))
    if(len(data) == 0):
        print("[ERROR] Empty data.")
        return
    x_data, y_data = separate_data(data)
    print("[INFO] x data shape: " + str(x_data.shape))
    print("[INFO] y data shape: " + str(y_data.shape))
    y_data = y_data.astype(dtype=np.int)
    if(USE_FFT):
        x_data_rt, x_data_real_imag = process_fft_data(x_data)
        x_data = x_data_rt
        print("[INFO] x data shape: " + str(x_data.shape))
        print("[INFO] y data shape: " + str(y_data.shape))
    print("[INFO] Train test split... ")
    x_train, x_test, y_train, y_test = train_test_split(
        x_data, y_data, test_size=0.25)
    print("[INFO] x_data shape: " + str(x_data.shape))
    print("[INFO] y_data shape: " + str(y_data.shape))

    _z, num_features = x_data.shape

    feature_columns = [tf.feature_column.numeric_column(
        "x", shape=[num_features], dtype=tf.float32)]

    print("[INFO] Creating Model...")
    model_dir = "./models/dnn_" + USER_ID
    if(USER_ID == ""):
        model_dir += "ALL"
    if(USE_FFT):
        model_dir += "_FFT"
    else:
        model_dir += "_RAW"
    classifier = tf.estimator.DNNClassifier(feature_columns=feature_columns,
                                            hidden_units=[
                                                512, 256, 128],
                                            n_classes=NUM_CLASSES,
                                            optimizer=tf.train.AdagradOptimizer(
                                                learning_rate=0.1
                                            ),
                                            activation_fn=tf.nn.relu,
                                            model_dir=model_dir
                                            )
    # Define the training inputs
    train_input_fn = tf.estimator.inputs.numpy_input_fn(
        x={"x": x_train},
        y=y_train,
        num_epochs=None,
        shuffle=True)

    # Train model.
    print("[INFO] Beginning training...")
    classifier.train(input_fn=train_input_fn, steps=2000)
    print("[INFO] Training complete.")

    test_input_fn = tf.estimator.inputs.numpy_input_fn(
        x={"x": x_test},
        y=y_test,
        num_epochs=1,
        shuffle=False)
    accuracy_score = classifier.evaluate(
        input_fn=test_input_fn)["accuracy"]
    print("\nTest Accuracy: {0:f}\n".format(accuracy_score))
    return accuracy_score


def main():
    accuracy = []
    for i in range(5):
        accuracy.append(process())
        for x in accuracy:
            print(x)


if __name__ == "__main__":
    # extract_data(data_dir)
    main()
