The SVM had to be built from scratch to understand the steps. The already existing SVM's serve as a good reference, but it was not as simple as we had hoped to modify them to fit our needs. So our own was built
The current version being used is jeff_linear_svm

The SVM takes data that is stored in the CSV format, organized as follows:

| Classifier (True/False) | Feature 1 | Feature 2 | ... | Feature N |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| 0  | float  | float  | ...  | float  |
| 1  | float  | float  | ...  | float  |
| 1  | float  | float  | ...  | float  |
| 0  | float  | float  | ...  | float  |
| ...  | ...  | ...  | ...  | ...  |

In a 2-Dimensional space, the SVM produces the following:
(The following are screenshots from a 2-D test for x > y and y > x)

![Text](/classification/data/images/graph1.PNG?raw=true "Optional Title")
