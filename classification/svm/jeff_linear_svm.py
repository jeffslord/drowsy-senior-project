import tensorflow as tf
import numpy as np  # Probably need to install the numpy-mkl for it to work with scipy
from matplotlib import pyplot as plt
from tensorflow.python.framework import ops
import os
ops.reset_default_graph()  # Double check this


# Extract Function from file
# data_dir includes complete directory including extension
def extract_data(data_dir):
  _data = np.genfromtxt(data_dir, delimiter=',', skip_header=1, dtype=float)
  _labels = _data[:, 0]
  _features = _data[:, 1:]
  #print(_labels)
  #print(_features)
  # Returns a matrix of labels, and a matrix of features
  return _labels, _features


# Start the graph
sess = tf.Session()

# Load the data
# Data should be in the form : First row = header (will be excluded),
# leftmost column is label (0 or 1), rest is features
data_dir = r"D:\Development\Senior Project\Sample Data\ds1.10.csv"
labels, features = extract_data(data_dir)
labels = np.array([1 if x == 1 else -1 for x in labels]) # Get array of 1 or -1, instead of 0 and 1.
# Train size = number of entries(trials), num_features = number of features(number of frequencies,
# or whatever else used)
num_tuples, num_features = features.shape
# print(features.shape)
# print("num_tuples = " + str(num_tuples))
# print("num_features = " + str(num_features))
num_epochs = 1

# Separate data into training / testing
train_indices = np.random.choice(num_tuples,
                                 round(num_tuples * 0.8),
                                 replace=False)
test_indices = np.array(list(set(range(num_tuples)) - set(train_indices)))
training_features = features[train_indices]
testing_features = features[test_indices]
training_labels = labels[train_indices]
testing_labels = labels[test_indices]

# Batch size
batch_size = 100
# Placeholders for batches
x = tf.placeholder(shape=[None, num_features], dtype=tf.float32)
y = tf.placeholder(shape=[None, 1], dtype=tf.float32)
# Variables for SVM, weight and bias, defines how much each feature contributes to the classification
W = tf.Variable(tf.random_normal(shape=[num_features, 1]), name="W")
b = tf.Variable(tf.random_normal(shape=[1, 1]))

# Model operations
model_output = tf.subtract(tf.matmul(x, W), b)

# Vector L2 'norm' function squared
l2_norm = tf.reduce_sum(tf.square(W))

# Loss Function
# Loss = max(0, 1-pred*actual) + alpha * L2_norm(W)^2
# L2 regularization parameter, alpha
# alpha is the soft-margin term. Increase for more erroroneous classification points. =0 for hard-margin.
alpha = tf.constant([0.01])
# Margin term in loss
classification_term = tf.reduce_mean(tf.maximum(0., tf.subtract(1., tf.multiply(model_output, y))))
# Put terms together
loss = tf.add(classification_term, tf.multiply(alpha, l2_norm))


# prediction Function
prediction = tf.sign(model_output)
accuracy = tf.reduce_mean(tf.cast(tf.equal(prediction, y), tf.float32))

# Optimizer
my_opt = tf.train.GradientDescentOptimizer(0.01)
train_step = my_opt.minimize(loss)

# Initialize variables
init = tf.global_variables_initializer()
sess.run(init)

# Training loop
loss_vec = []
train_accuracy = []
test_accuracy = []
num_steps = 500
for i in range(num_steps):
  rand_index = np.random.choice(len(training_features), size=batch_size)
  rand_features = training_features[rand_index]
  rand_labels = np.transpose([training_labels[rand_index]])
  sess.run(train_step, feed_dict={x: rand_features, y: rand_labels})

  temp_loss = sess.run(loss, feed_dict={x: rand_features, y: rand_labels})
  loss_vec.append(temp_loss)

  train_acc_temp = sess.run(accuracy, feed_dict={x: training_features, y: np.transpose([training_labels])})
  train_accuracy.append(train_acc_temp)

  test_acc_temp = sess.run(accuracy, feed_dict={x: testing_features, y: np.transpose([testing_labels])})
  test_accuracy.append(test_acc_temp)

  if((i + 1) % 100 == 0):
    print("Step #{} : W = {}, b = {}".format(
      str(i+1),
      str(sess.run(W)),
      str(sess.run(b))
    ))
    print("Loss = " + str(temp_loss))
    print("Train Accuracy = " + str(train_accuracy[i]))
    print("Test Accuracy = " + str(test_accuracy[i]))


saver = tf.train.Saver()
saver.save(sess, r"D:\Development\Senior Project\models\my_model", i+1)
# Extract coefficients, can visualize for 2 dimensions(2 features) but for more you can't plot a line
# [[a1], [a2]] = sess.run(W)
# [[b]] = sess.run(b)
# slope = -a2/a1
# y_intercept = b/a1
# # Extract x1 and x2 vals
# feature_vals = [d[1] for d in features]
# #Get best fit line
# best_fit = []
# for i in feature_vals:
#   best_fit.append(slope*i+y_intercept)


# print("Labels")
# print(labels)
# print("Features")
# print(features)
# print("Train Indices")
# print(train_indices)
# print("Test Indices")
# print(test_indices)
# print("Training Features")
# print(training_features)
# print("Testing Features")
# print(testing_features)