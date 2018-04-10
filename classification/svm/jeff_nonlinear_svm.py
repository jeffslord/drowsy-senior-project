import numpy as np
from sklearn import svm, datasets
from sklearn.metrics import accuracy_score
import matplotlib.pyplot as plt
from sklearn.externals import joblib
import pandas as pd
import math

data_dir = "output_fft.csv"

graphing = False
userId = "675"


def extract_data(data_dir):
    print("[INFO] Extracting data...")

    #! abs(complex) might work
    df = pd.read_csv(data_dir, na_values=0.0)
    df = df.fillna(0.0)
    _data = df.as_matrix()
    print(_data[0])

    _data_filtered = []

    # _data_filtered = _data

    unique = []
    for x in _data:
        if(str(x[0]) == userId):
            _data_filtered.append(x)
        if(x[0] not in unique):
            unique.append(x[0])

    print(unique)
    x = []
    y = []
    x2 = []
    x3 = []
    for row in _data_filtered:
        x.append(row[3:])
        y.append(row[1])
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

    x2 = np.array(x2)
    print(x2.shape)
    # x2 = x2[:, :51]
    x3 = np.array(x3)
    x3 = x3[:, :51]
    y = np.array(y)

    # _data_filtered = np.array(x, dtype=np.complex_)
    return x2, y


def train_test_split(data, percent=0.8):
    num_tuples = len(data)
    print(num_tuples)
    train_indices = np.random.choice(num_tuples,
                                     round(num_tuples * 0.8),
                                     replace=False)
    test_indices = np.array(list(set(range(num_tuples)) - set(train_indices)))
    return train_indices, test_indices


# For 2-D
x, y = extract_data(data_dir)
y = y.astype(dtype=np.int)
print(x[0])
print(y[0])
train_indices, test_indices = train_test_split(x)
x_train = x[train_indices]
y_train = y[train_indices]
x_test = x[test_indices]
y_test = y[test_indices]
print(x_train.shape)
print(y_train.shape)

# adjust these parameters to see what is best
# c : how much to avoid misclassifying.
#           low - smooth decision surface. look for larger-margin hyperplane. it may misclassify some points. Very small will misclassify.
#           high - smaller-margin hyperplane, if it gets all points classified correctly
# gamma : how far the influence of a single training example reaches. inverse of the radius of influence
#           low - 'far'
#           high - 'close'
# SVM
c = 0.1
# gamma = 0.001
svc = svm.SVC(kernel='rbf',
              C=c,
              gamma='auto',
              decision_function_shape='ovr',
              degree=3,
              coef0=0.0,
              probability=True,
              shrinking=True,
              verbose=True)
svc = svc.fit(x_train, y_train)
# END SVM

# EXPORT
joblib.dump(svc, './models/nonlinear_svc_01.pkl')
# END EXPORT

# PREDICT
prediction = svc.predict(x_test)
print("\nNonlinear SVM: {0:f}\n".format(accuracy_score(y_test, prediction)))
# load model in 'server' or app with...
# from sklearn.externals import joblib
# model = joblib.load('path_to_model.pkl')
# model.predict()
# END PREDICT

# GRAPHING
if(graphing):
    x1_min, x1_max = x[:, 0].min() - 1, x[:, 0].max() + 1
    x2_min, x2_max = x[:, 1].min() - 1, x[:, 1].max() + 1

    xx1, xx2 = np.meshgrid(np.arange(x1_min, x1_max, 0.1),
                           np.arange(x2_min, x2_max, 0.05))
    x_plot = np.c_[xx1.ravel(), xx2.ravel()]
    # create 2-D grid of predictions, for coloring different sections. From min to max, at step of whatever is set in meshgrid (ex. 0.1)
    z = svc.predict(x_plot)
    z = z.reshape(xx1.shape)

    # plt.subplot(122)
    plt.contourf(xx1, xx2, z, cmap=plt.cm.tab10, alpha=0.3)
    plt.scatter(x[:, 0], x[:, 1], c=y, cmap=plt.cm.Set1)
    plt.xlabel('Feat1')
    plt.ylabel('Feat2')
    #plt.xlim(xx1.min(), xx1.max())
    plt.title('SVC with RBF kernel')
    plt.show()
# GRAPHING END
