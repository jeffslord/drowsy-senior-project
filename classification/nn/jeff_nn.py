from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import urllib

import numpy as np
import tensorflow as tf

data_dir = "../data/sample2.csv"
num_classes = 2

def extract_data(data_dir):
  _data = np.genfromtxt(data_dir, delimiter=',', skip_header=1, dtype=float)
  return _data

def train_test_split(data, percent=0.8):
  num_tuples = len(data)
  print(num_tuples)
  train_indices = np.random.choice(num_tuples,
                                   round(num_tuples * percent),
                                   replace=False)
  test_indices = np.array(list(set(range(num_tuples)) - set(train_indices)))
  return train_indices, test_indices

def main():
  # Split data into training and testing,
  data = extract_data(data_dir)
  x = data[:, 1:]
  y = data[:, 0]
  y = y.astype(dtype=np.int)
  train_indices, test_indices = train_test_split(data)
  x_train = np.array(x[train_indices])
  x_test = np.array(x[test_indices])
  y_train = np.array(y[train_indices])
  y_test = np.array(y[test_indices])
  num_tuples = len(data)
  z,num_features = x.shape
  print(num_features)
  print(x_train)

  # Specify that all features have real-value data
  feature_columns = [tf.feature_column.numeric_column("x", shape=[num_features])]

  # Build 3 layer DNN with 10, 20, 10 units respectively.
  # classifier = tf.estimator.DNNClassifier(feature_columns=feature_columns,
  #                                         hidden_units=[10, 20, 10],
  #                                         n_classes=3,
  #                                         model_dir="/tmp/my_model")

  # Optimizers = Adagrad, Ftrl,
  # Activation tf.nn.relu/tanh/sigmoid
  classifier = tf.estimator.DNNClassifier(feature_columns=feature_columns,
                                          hidden_units=[10, 20, 10],
                                          n_classes=num_classes,
                                          optimizer=tf.train.AdagradOptimizer(
                                              learning_rate=0.1
                                          ),
                                          activation_fn=tf.nn.relu
                                          #optimizer='Adagrad'
                                          #model_dir="/tmp/my_model1")
                                          )

  # Define the training inputs
  train_input_fn = tf.estimator.inputs.numpy_input_fn(
      x={"x": x_train},
      y=y_train,
      num_epochs=None,
      shuffle=True)

  # Train model.
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

  # Classify two new flower samples.
  new_samples = np.array(
      [[5.5, 7.9],
       [10.2, 3.4]], dtype=np.float32)
  predict_input_fn = tf.estimator.inputs.numpy_input_fn(
      x={"x": new_samples},
      num_epochs=1,
      shuffle=False)

  predictions = list(classifier.predict(input_fn=predict_input_fn))
  predicted_classes = [p["classes"] for p in predictions]

  print(
      "New Samples, Class Predictions:    {}\n"
      .format(predicted_classes))

if __name__ == "__main__":
    main()