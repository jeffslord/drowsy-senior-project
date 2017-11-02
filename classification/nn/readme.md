# Neural Network
## Tensorflow
The current implementation for our neural network test is a deep neural network implemented with tensorflow's DNNClassifier. The results are promisng in a simple 2-Dimensional test with 99.95% accuracy with a simple example problem.

### Parameters
The adjustable parameters for the DNN include:
- Optimizer
- Activation function.

### Tensorboard
It is possible to visualize the neural network using tensorboard. If you have the exported log files (maybe other files too? need to clarify) you can launch tensorboard.

tensorboard --logdir='path_to_log_files'
