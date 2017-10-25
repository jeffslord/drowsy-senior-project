import tensorflow as tf
import numpy as np # Probably need to install the numpy-mkl for it to work with scipy
import scipy.io as io 
from matplotlib import pyplot as plt
import plot_boundary_on_data
ops.reset_default_graph() # Double check this


# Extract Function from file
# data_dir includes complete directory including extension
def extract_data(data_dir):
  data = np.genfromtxt(data_dir, skip_header=1)
  labels = data[:,0]
  features = data[:,1:]
  # Returns a matrix of labels, and a matrix of features
  return labels,features


# Start the graph
sess = tf.Session()

# Load the data
# Data should be in the form : First row = header (will be excluded), leftmost column is label (0 or 1), rest is features
data_dir = ""
labels, features = extract_data(data_dir)
labels = np.array([1 if x == 1 else -1 for x in labels]) # Get array of 1 or -1, instead of 0 and 1.
# Train size = number of entries(trials), num_features = number of features(number of frequencies, or whatever else used)
train_size, num_features = features.shape

num_epochs = 1

# Separate data into training / testing
train_indices = np.random.choice(num_features, round(num_features * 0.8), replace = False)
test_indices = np.array(list(set(range(num_features)) - set(train_indices)))
training_features = features[train_indices]
testing_featuers = features[test_indices]
training_labels = labels[train_indices]
testing_labels = labels[test_indices]

# Batch size
batch_size = 100
x =
y = 
A = 
b = 
