import numpy as np
from sklearn import svm, datasets
from sklearn.metrics import accuracy_score
#import matplotlib.pyplot as plt

#data_dir = r"D:\Development\Senior Project\Sample Data\sample2.csv"
#data_dir = "/Users/Jeff/PycharmProjects/drowsy-senior-project/classification/data/sample1.csv"
data_dir = "/Users/Jeff/PycharmProjects/drowsy-senior-project/classification/data/sample3.csv"

graphing = False

def extract_data(data_dir):
  _data = np.genfromtxt(data_dir, delimiter=',', skip_header=1, dtype=float)
  return _data

def train_test_split(data, percent=0.8):
  num_tuples = len(data)
  print(num_tuples)
  train_indices = np.random.choice(num_tuples,
                                   round(num_tuples * 0.8),
                                   replace=False)
  test_indices = np.array(list(set(range(num_tuples)) - set(train_indices)))
  return train_indices, test_indices

# For 2-D
data = extract_data(data_dir)
x = data[:, 1:]
y = data[:, 0]
train_indices, test_indices = train_test_split(x)
x_train = x[train_indices]
y_train = y[train_indices]
x_test = x[test_indices]
y_test = y[test_indices]
# print(x_test.shape)
# print(x_test)
# print(y_test)
# iris = datasets.load_iris()
# ix = iris.data[:, :2]
# iy = iris.target

#adjust these parameters to see what is best
# c : how much to avoid misclassifying.
#           low - smooth decision surface. look for larger-margin hyperplane. it may misclassify some points. Very small will misclassify.
#           high - smaller-margin hyperplane, if it gets all points classified correctly
# gamma : how far the influence of a single training example reaches. inverse of the radius of influence
#           low - 'far'
#           high - 'close'
# SVM
c = 100
gamma = 0.001
svc = svm.SVC(kernel='rbf',
              C=c,
              gamma=gamma,
              decision_function_shape='ovr',
              degree=3,
              coef0=0.0,
              probability=False,
              shrinking=True,
              verbose=False)
svc = svc.fit(x_train, y_train)
# END SVM

# PREDICT
prediction = svc.predict(x_test)
print("\nNonlinear SVM: {0:f}\n".format(accuracy_score(y_test, prediction)))
# END PREDICT

# GRAPHING
# if(graphing):
#   x1_min, x1_max = x[:, 0].min() - 1, x[:, 0].max() + 1
#   x2_min, x2_max = x[:, 1].min() - 1, x[:, 1].max() + 1
#
#   xx1, xx2 = np.meshgrid(np.arange(x1_min, x1_max, 0.1), np.arange(x2_min, x2_max, 0.05))
#   x_plot = np.c_[xx1.ravel(), xx2.ravel()]
#   # create 2-D grid of predictions, for coloring different sections. From min to max, at step of whatever is set in meshgrid (ex. 0.1)
#   z = svc.predict(x_plot)
#   z = z.reshape(xx1.shape)
#
#   #plt.subplot(122)
#   plt.contourf(xx1, xx2, z, cmap=plt.cm.tab10, alpha=0.3)
#   plt.scatter(x[:, 0], x[:, 1], c=y, cmap=plt.cm.Set1)
#   plt.xlabel('Feat1')
#   plt.ylabel('Feat2')
#   #plt.xlim(xx1.min(), xx1.max())
#   plt.title('SVC with RBF kernel')
#   plt.show()
# # GRAPHING END