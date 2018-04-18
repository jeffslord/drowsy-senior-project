import numpy as np
import pandas as pd
import math


def normalize(arr, min_val=None, max_val=None):
    print("[INFO] Normalizing array...")
    if(min_val == None):
        min_val = np.amin(arr)
    if(max_val == None):
        max_val = np.amax(arr)
    sub = np.subtract(arr, min_val)
    div = np.divide(sub, max_val)
    return div, min_val, max_val


def extract_data(data_dir, user_id=""):
    print("[INFO] Extracting data...")
    df = pd.read_csv(data_dir, na_values=0.0)
    df = df.fillna(0)
    df_matrix = df.as_matrix()

    data_filtered = []
    if(user_id != ""):
        for x in df_matrix:
            if(str(int(x[0])) == user_id):
                data_filtered.append(x)
        print("[INFO] " + user_id + " contains: " +
              str(len(data_filtered)) + " records.")
    else:
        data_filtered = df_matrix
        print("[INFO] Total Records: " + str(len(df_matrix)) + ".")
    return np.array(data_filtered)


def separate_data(data, y_col=1, x_start_col=3, x_features=50):
    print("[INFO] Separating X and Y data...")
    x = []
    y = []
    for row in data:
        x.append(row[x_start_col:x_features+x_start_col])
        y.append(row[y_col])
    return np.array(x), np.array(y)


def process_fft_data(x_data):
    print("[INFO] Processing fft data... ")
    x_data_rt = []
    x_data_real_imag = []
    for row in x_data:
        rt_row = []
        real_image_row = []
        for cell in row:
            cp = complex(cell)
            sq = pow(cp.real, 2) + pow(cp.imag, 2)
            rt = math.sqrt(sq)
            if(cell == '0j'):
                rt = 0.0
            rt_row.append(rt)
            real_image_row.append(cp.real)
            real_image_row.append(cp.imag)
        x_data_rt.append(rt_row)
        x_data_real_imag.append(real_image_row)
    return np.array(x_data_rt), np.array(x_data_real_imag)
