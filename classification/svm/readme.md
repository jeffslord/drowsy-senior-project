# SVM
### Current
The anticipated SVM for our classification will be non-linear. The current code being used for this is **jeff_nonlinear_svm** and is made based from scikit.

### Other
The previously created SVM was linear, but will most likely not be suitable for our classification because the data may not be linearly separable. The version for this is **jeff_linear_svm**.

## The SVM takes data that is stored in the CSV format, organized as follows:
| Classifier (True/False) | Feature 1 | Feature 2 | ... | Feature N |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| 0  | float  | float  | ...  | float  |
| 1  | float  | float  | ...  | float  |
| 1  | float  | float  | ...  | float  |
| 0  | float  | float  | ...  | float  |
| ...  | ...  | ...  | ...  | ...  |

# Non-Linear SVM (scikit-learn)
## 2-D Example for visualization
### Support vector classifier using RBF kernel
![](/classification/data/images/graph-nl1.PNG?raw=true "Non-linear Separator")

# Linear SVM (TensorFlow)
### Linear Separator
![](/classification/data/images/graph1.PNG?raw=true "Linear Separator")
### Train and Test Accuracies
![](/classification/data/images/graph2.PNG?raw=true "Linear Separator")
### Loss
![](/classification/data/images/graph3.PNG?raw=true "Linear Separator")
