from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import urllib

import numpy as np
import tensorflow as tf
import pandas as pd
import csv
import math

data_dir = "output_fft.csv"
data_dir2 = "output_organized.csv"
num_classes = 2
userId = "264"
fft_data = False


def extract_data(data_dir):
    print("[INFO] Extracting data...")

    #! abs(complex) might work
    df = pd.read_csv(data_dir, na_values=0.0)
    df = df.fillna(0)
    # print(df)
    _data = df.as_matrix()

    _data_filtered = []

    _data_filtered = _data

    # for x in _data:
    #     if(str(x[0]) == userId):
    #         _data_filtered.append(x)

    x = []
    y = []
    x2 = []
    x3 = []
    for row in _data_filtered:
        x.append(row[3:])
        y.append(row[1])
    if(fft_data):
        print(len(x))
        for row in x:
            row2 = []
            row3 = []
            for cell in row:
                cp = complex(cell)
                sq = pow(cp.real, 2) + pow(cp.imag, 2)
                cell = math.sqrt(sq)
                if(cell == '0j'):
                    cell = 0.0
                row2.append(cell)
                row3.append(cp.real)
                row3.append(cp.imag)
            x2.append(row2)
            x3.append(row3)

        for i in range(len(x2)):
            if(x2[i] == '0j'):
                print("WHATTTTTTTTTT")
                x2[i] = 0.0
    else:
        x3 = x

    if(fft_data):
        x2 = np.array(x2)
        x2 = x2[:, :51]
        x3 = np.array(x3)
        x3 = x3[:, :51]
        y = np.array(y)
    else:
        x3 = np.array(x3)
        y = np.array(y)
    # print(x2[1])
    # print(y[1])

    # _data_filtered = np.array(x, dtype=np.complex_)
    return x3, y


def train_test_split(data, percent=0.8):
    print("[INFO] splitting train and test data...")
    num_tuples = len(data)
    train_indices = np.random.choice(num_tuples,
                                     round(num_tuples * percent),
                                     replace=False)
    test_indices = np.array(list(set(range(num_tuples)) - set(train_indices)))
    return train_indices, test_indices

# Need to work on exporting the models


def serving_input_receiver_fn():
    serialized_tf_example = tf.placeholder()


def main():
    # Split data into training and testing,
    if(fft_data):
        x, y = extract_data(data_dir)
    else:
        x, y = extract_data(data_dir2)

    print(x.shape)
    print(y.shape)

    # print(x[0])
    x = x.astype(dtype=np.float32)
    y = y.astype(dtype=np.int)
    train_indices, test_indices = train_test_split(x)
    x_train = np.array(x[train_indices])
    x_test = np.array(x[test_indices])
    y_train = np.array(y[train_indices])
    y_test = np.array(y[test_indices])
    num_tuples = len(x)
    z, num_features = x.shape
    print(num_features)
    # print(x_train[0])

    COLUMN_NAMES = ["Label", "X1", "X2"]

    # Specify that all features have real-value data
    feature_columns = [tf.feature_column.numeric_column(
        "x", shape=[num_features], dtype=tf.float32)]

    # feature_columns = [
    #     tf.feature_column.numeric_column(name)
    #     for name in COLUMN_NAMES[1:]
    # ]

    # Build 3 layer DNN with 10, 20, 10 units respectively.
    # classifier = tf.estimator.DNNClassifier(feature_columns=feature_columns,
    #                                         hidden_units=[10, 20, 10],
    #                                         n_classes=3,
    #                                         model_dir="/tmp/my_model")

    # Optimizers = Adagrad, Ftrl,
    # Activation tf.nn.relu/tanh/sigmoid
    print("[INFO] Creating Model...")
    classifier = tf.estimator.DNNClassifier(feature_columns=feature_columns,
                                            hidden_units=[
                                                512, 256, 128],
                                            n_classes=num_classes,
                                            optimizer=tf.train.AdagradOptimizer(
                                                learning_rate=0.1
                                            ),
                                            activation_fn=tf.nn.relu,
                                            # optimizer='Adagrad'
                                            model_dir="./models/dnn_03"
                                            )
    # classifier = tf.estimator.DNNClassifier(feature_columns=feature_columns,
    #                                         hidden_units=[
    #                                             512, 256, 128],
    #                                         n_classes=num_classes,
    #                                         optimizer=tf.train.AdamOptimizer(
    #                                             learning_rate=0.1
    #                                         ),
    #                                         activation_fn=tf.nn.relu,
    #                                         # optimizer='Adagrad'
    #                                         model_dir="./models/dnn_04"
    #                                         )

    # Define the training inputs
    train_input_fn = tf.estimator.inputs.numpy_input_fn(
        x={"x": x_train},
        y=y_train,
        num_epochs=None,
        shuffle=True)

    # Train model.
    print("[INFO] Beginning Training...")

    classifier.train(input_fn=train_input_fn, steps=2000)

    # Define the test inputs
    test_input_fn = tf.estimator.inputs.numpy_input_fn(
        x={"x": x_test},
        y=y_test,
        num_epochs=1,
        shuffle=False)

    # Evaluate accuracy.
    accuracy_score = classifier.evaluate(input_fn=test_input_fn)["accuracy"]

    print("\nTest Accuracy: {0:f}\n".format(accuracy_score))

    # # Classify two new flower samples.
    # new_samples = np.array(
    #     [[5.5, 7.9],
    #      [10.2, 3.4]], dtype=np.float32)
    # predict_input_fn = tf.estimator.inputs.numpy_input_fn(
    #     x={"x": new_samples},
    #     num_epochs=1,
    #     shuffle=False)

    # predictions = list(classifier.predict(input_fn=predict_input_fn))
    # predicted_classes = [p["classes"] for p in predictions]

    # tf.estimator.DNNClassifier.export_savedmodel(
    #     classifier,
    #     "./models/export/dnn_01",
    # )


if __name__ == "__main__":
    # extract_data(data_dir)
    main()
