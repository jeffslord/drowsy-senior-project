from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from sklearn.model_selection import train_test_split
from scipy import fftpack
import os
import urllib
import numpy as np
import tensorflow as tf
import pandas as pd
import csv
import math
import sys
import os
file_path = os.path.abspath(__file__)
file_path = os.path.dirname(os.path.dirname(file_path))
print("[INFO] " + file_path)
sys.path.insert(0, file_path)
from data_process import data_processing as dp

USE_FFT = True
NORMALIZE = True
USER_ID = "517"
NUM_CLASSES = 2
DATA_DIR = os.path.join(file_path, "data", "output_organized.csv")


def process():
    data = dp.extract_data(DATA_DIR, USER_ID)
    if(len(data) == 0):
        print("[ERROR] Data is empty.")
        return
    x_data, y_data = dp.separate_data(data, 1, 3, 50)
    if(NORMALIZE):
        x_data, min_val, max_val = dp.normalize(x_data)
        print(x_data)
    if(USE_FFT):
        x_data = fftpack.fft(x_data)
        x_data_rt, x_data_real_imag = dp.process_fft_data(x_data)
        x_data = x_data_rt
    y_data = y_data.astype(dtype=np.int)
    print("[INFO] Train test split... ")
    x_train, x_test, y_train, y_test = train_test_split(
        x_data, y_data, test_size=0.2)
    print("[INFO] x_data shape: " + str(x_data.shape))
    print("[INFO] y_data shape: " + str(y_data.shape))
    _z, num_features = x_data.shape

    feature_columns = [tf.feature_column.numeric_column(
        "x", shape=[num_features], dtype=tf.float32)]

    print("[INFO] Creating Model...")
    model_dir = os.path.join(file_path, "data", "models", "dnn_" + USER_ID)
    if(USER_ID == ""):
        model_dir += "ALL"
    if(USE_FFT):
        model_dir += "_FFT"
    else:
        model_dir += "_RAW"
    if(NORMALIZE):
        model_dir += "_NORMALIZED"

    classifier = tf.estimator.DNNClassifier(
        feature_columns=feature_columns,
        hidden_units=[
            128, 64, 32],
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
    test_input_fn = tf.estimator.inputs.numpy_input_fn(
        x={"x": x_test},
        y=y_test,
        num_epochs=1,
        shuffle=False)

    # train_spec = tf.estimator.TrainSpec(train_input_fn)
    # eval_spec = tf.estimator.EvalSpec(test_input_fn)
    # tf.estimator.train_and_evaluate(, train_spec, eval_spec)

    # Train model.
    print("[INFO] Beginning training...")
    classifier.train(input_fn=train_input_fn, steps=2000)
    print("[INFO] Training complete.")

    accuracy_score = classifier.evaluate(
        input_fn=test_input_fn)["accuracy"]
    print("\nTest Accuracy: {0:f}\n".format(accuracy_score))
    return accuracy_score


def main():
    accuracy = []
    for i in range(100):
        accuracy.append(process())
        for x in accuracy:
            print(x)


if __name__ == "__main__":
    main()
