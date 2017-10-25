import tensorflow as tf
import numpy as np # Probably need to install the numpy-mkl for it to work with scipy
import scipy.io as io 
from matplotlib import pyplot as plt
import plot_boundary_on_data
ops.reset_default_graph() # Double check this

# Start the graph
sess = tf.Session()

def extract_data(data_dir):
  data = np.genfromtxt(data_dir, skip_header=1)
  labels = data[:,0]
  features = data[:,1:]
  # Returns a matrix of labels, and a matrix of features
  return labels,features

# Load the data
# Data should be in the form : First row = header (will be excluded), leftmost column is label (0 or 1), rest is features
data_dir = ""
labels, features = extract_data(data_dir)
