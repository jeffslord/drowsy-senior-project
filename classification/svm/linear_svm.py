import tensorflow as tf
import numpy as np
import scipy.io as io
from matplotlib import pyplot as plt
import plot_boundary_on_data  

# Global variables.

# The number of training examples to use per training step.
BATCH_SIZE = 100  

# Define the flags useable from the command line.
tf.app.flags.DEFINE_string('train', None,
                           'File containing the training data (labels & features).')
tf.app.flags.DEFINE_integer('num_epochs', 1,
                            'Number of training epochs.')
tf.app.flags.DEFINE_float('svmC', 1,
                            'The C parameter of the SVM cost function.')
tf.app.flags.DEFINE_boolean('verbose', False, 'Produce verbose output.')
tf.app.flags.DEFINE_boolean('plot', True, 'Plot the final decision boundary on the data.')
FLAGS = tf.app.flags.FLAGS

# Extract numpy representations of the labels and features given rows consisting of:
#   label, feat_0, feat_1, ..., feat_n
#   The given file should be a comma-separated-values (CSV) file saved by the savetxt command.
#   In our case, the label will be drowsy or not drowsy, or 0 and 1.
#   The features may be the results of the FFT, or chosen frequency ranges, etc. Still need to figure that out.
def extract_data(filename):

    out = np.loadtxt(filename, delimiter=',');

    # Arrays to hold the labels and feature vectors.
    # Read how to use multi-dimensional numpy arrays. That will explain how this is splitting up the labels and features.
    # 
    labels = out[:,0]
    labels = labels.reshape(labels.size,1)
    fvecs = out[:,1:]

    # Return a pair of the feature matrix and the one-hot label matrix.
    return fvecs,labels


def main(argv=None):
    # Be verbose?
    verbose = FLAGS.verbose

    # Plot? 
    plot = FLAGS.plot
    
    # Get the data.
    train_data_filename = FLAGS.train
    
    # Here's where that extract_data function is used. Now you have the data for training, and the labels that classify the data.
    # Extract it into numpy matrices.
    train_data,train_labels = extract_data(train_data_filename)

    # If we need to convert the labels to something specific, here's where we could if it's not already set up right.
    # Convert labels to +1,-1
    train_labels[train_labels==0] = -1

    # Here's the start of tensorflow stuff. If you want to fully understand start looking up tensorflow documentation.
    # Get the shape of the training data.
    train_size,num_features = train_data.shape

    # Get the number of epochs for training.
    num_epochs = FLAGS.num_epochs

    # Get the C param of SVM
    # Large Value, optimization chooses smaller-margin hyperplane. Smaller value, optimizer will look for a larger-margin separating hyperplane.
    # With very small values of C you should get misclassified examples even if your training data was linearly separable.
    svmC = FLAGS.svmC

    # This is where training samples and labels are fed to the graph.
    # These placeholder nodes will be fed a batch of training data at each
    # training step using the {feed_dict} argument to the Run() call below.
    x = tf.placeholder("float", shape=[None, num_features])
    y = tf.placeholder("float", shape=[None,1])

    # Define and initialize the network.

    # These are the weights that inform how much each feature contributes to
    # the classification.
    W = tf.Variable(tf.zeros([num_features,1]))
    b = tf.Variable(tf.zeros([1]))
    y_raw = tf.matmul(x,W) + b

    # Optimization.
    # This is where the magic begins
    regularization_loss = 0.5*tf.reduce_sum(tf.square(W)) 
    hinge_loss = tf.reduce_sum(tf.maximum(tf.zeros([BATCH_SIZE,1]), 
        1 - y*y_raw));
    svm_loss = regularization_loss + svmC*hinge_loss;
    train_step = tf.train.GradientDescentOptimizer(0.01).minimize(svm_loss)

    # Evaluation.
    predicted_class = tf.sign(y_raw);
    correct_prediction = tf.equal(y,predicted_class)
    accuracy = tf.reduce_mean(tf.cast(correct_prediction, "float"))

    # Create a local session to run this computation.
    with tf.Session() as s:
        # Run all the initializers to prepare the trainable parameters.
        tf.initialize_all_variables().run()
        if verbose:
            print 'Initialized!'
            print
            print 'Training.'

        # Iterate and train.
        for step in xrange(num_epochs * train_size // BATCH_SIZE):
            if verbose:
                print step,
                
            offset = (step * BATCH_SIZE) % train_size
            batch_data = train_data[offset:(offset + BATCH_SIZE), :]
            batch_labels = train_labels[offset:(offset + BATCH_SIZE)]
            train_step.run(feed_dict={x: batch_data, y: batch_labels})
            print 'loss: ', svm_loss.eval(feed_dict={x: batch_data, y: batch_labels})
            
            if verbose and offset >= train_size-BATCH_SIZE:
                print

        # Give very detailed output.
        if verbose:
            print
            print 'Weight matrix.'
            print s.run(W)
            print
            print 'Bias vector.'
            print s.run(b)
            print
            print "Applying model to first test instance."
            print
            
        print "Accuracy on train:", accuracy.eval(feed_dict={x: train_data, y: train_labels})

        if plot:
            eval_fun = lambda X: predicted_class.eval(feed_dict={x:X}); 
            plot_boundary_on_data.plot(train_data, train_labels, eval_fun)
    
if __name__ == '__main__':
    tf.app.run()
