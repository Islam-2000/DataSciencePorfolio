import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import scipy
import sys
import os
import pickle
import librosa
import librosa.display
from IPython.display import Audio
from sklearn.metrics import mean_squared_error, accuracy_score
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.preprocessing import LabelEncoder, StandardScaler
from tensorflow.keras.models import Sequential
import tensorflow as tf

seed = 12
np.random.seed(seed)

# Reading in the Data + Feature Extraction already performed with MFCCs
data = pd.read_csv("E://University Courses//Fall 2022//MCS 4210//GTZAN//Data//features_30_sec.csv")

data = data.iloc[0:, 1:]

# Data Preparation
print("Columns with NA values are", list(data.columns[data.isnull().any()]))

# Encoding Genre Label
label_index = dict()
index_label = dict()
for i, x in enumerate(data.label.unique()):
    label_index[x] = i
    index_label[i] = x
print(label_index)
print(index_label)

data.label = [label_index[l] for l in data.label]

# Data Shuffling
data_shuffle = data.sample(frac=1, random_state=seed).reset_index(drop=True)

# Remove filename and length columns
data_shuffle.drop(['length'], axis=1, inplace=True)
y = data_shuffle.pop('label')
X = data_shuffle

# Data Splitting into train validation test
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2,
                                                    random_state=seed, stratify=y)
X_train, X_val, y_train, y_val = train_test_split(X_train, y_train, test_size=0.25, random_state=seed)

# Scaling Features

scaler = StandardScaler()
X_train = pd.DataFrame(scaler.fit_transform(X_train), columns=X_train.columns)
X_val = pd.DataFrame(scaler.fit_transform(X_val), columns=X_val.columns)
X_test = pd.DataFrame(scaler.fit_transform(X_test), columns=X_test.columns)


def trainModel(model, epochs, optimizer):
    batch_size = 128
    model.compile(optimizer=optimizer, loss="sparse_categorical_crossentropy", metrics='accuracy')
    return model.fit(X_train, y_train, validation_data=(X_val, y_val), epochs=epochs, batch_size=batch_size)


def plotValidate(history):
    print("Validation Accuracy", max(history.history["val_accuracy"]))
    pd.DataFrame(history.history).plot(figsize=(12, 6))
    plt.show()


print(X_train.shape[1], X_train.shape[2], X_train.shape[3])
# CNN Model

CNN = tf.keras.models.Sequential([
    tf.keras.layers.Dense(512, activation='relu', input_shape=(X_train.shape[1],)),
    tf.keras.layers.Dropout(0.2),

    tf.keras.layers.Dense(256, activation='relu'),
    tf.keras.layers.Dropout(0.2),

    tf.keras.layers.Dense(128, activation='relu', kernel_regularizer=tf.keras.regularizers.L1(0.01)),
    tf.keras.layers.Dropout(0.2),

    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dropout(0.2),

    tf.keras.layers.Dense(10, activation='softmax'),
])

print(CNN.summary())
# model_history = trainModel(CNN, 100, "adam")

# test_loss, test_acc = CNN.evaluate(X_test, y_test, batch_size=128)
# print("The test loss is ", test_loss)
# print("The best accuracy is: ", test_acc * 100)

# Using supervised classifier in Support Vector Machines and optimizing hyperparameters
# SVM Classifier

c_values =  [0.01, 0.1, 1, 10, 100]
gamma_values = ['scale', 'auto']
kernel_values = ['linear', 'poly', 'rbf', 'sigmoid']

for c in c_values:
    for g in gamma_values:
        for k in kernel_values:
            svm = SVC(C=c, gamma=g, kernel=k)
            svm.fit(X_train, y_train)
            val_predictions = svm.predict(X_val)
            print('C: {}, Gamma: {}, Kernel: {}, Accuracy: {}'.
                  format(c, g, k, accuracy_score(y_val, val_predictions)))

n_estimators =  [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 200, 250, 500, 750, 1000]
max_depth = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]
criterion = ['gini', 'entropy']

svm = SVC(C=0.1, kernel='linear', gamma='scale')
rf = RandomForestClassifier(n_estimators=250, criterion='gini', max_depth=55)

for n in n_estimators:
    for m in max_depth:
        for c in criterion:
            rf = RandomForestClassifier(n_estimators=n, max_depth=m, criterion=c)
            rf.fit(X_train, y_train)
            val_predictions = rf.predict(X_val)
            print('Estimators: {}, Depth: {}, Criterion: {}, Accuracy: {}'.
                  format(n, m, c, accuracy_score(y_val, val_predictions)))
