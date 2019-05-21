# -*- coding: utf-8 -*-
"""
Created on Fri May 10 23:18:07 2019

@author: Dell
"""
#Importing the required modules to make a ML model 
import pandas as pd
import numpy as np
import seaborn as sns


#Loading the dataset 
df  = pd.read_csv("C:\\Users\\Dell\\Desktop\\WaterDataSet.csv")
df.head()
df.columns
X = df[['lum','hum','temp']]
Y = df[['target']]
X.head()
Y.head()
#Visualisation of the distribution of parameters of our dataset
sns.pairplot(X)
sns.distplot(Y)
X.corr()

#Spliting the training and the test part of the dataset
from sklearn.cross_validation import train_test_split
X_train, X_test, y_train, y_test = train_test_split(X, Y, test_size=0.4, random_state=101)

#Loading a linear regression model and fitting it with the training dataset
from sklearn.tree import DecisionTreeClassifier
lm = DecisionTreeClassifier(random_state=0)
lm.fit(X_train,y_train)

#making prediction on the test dataset 
predictions = lm.predict(X_test)
y_test
predictions
#Lets check with accuracy score of the model
from sklearn.metrics import accuracy_score
print("Accuracy score is ", accuracy_score(y_test,predictions))
#Here's a simple test
tt=pd.DataFrame([5000,45,50])
tt=tt.transpose()
a=lm.predict(tt)
print(a[0])



#Importing the required modules to interact with mesurements in Database
import mysql.connector
import time
#defining parameters of our database
USERNAME ="piste10"
PASSWORD = "piste10"
DBNAME = "PISTE10"
HOSTNAME = "ec2-108-128-15-84.eu-west-1.compute.amazonaws.com"  
 
#retrieving data, making prediction on it's mesurements and then storing the result in a table
while (1): 
    con =mysql.connector.connect(host = HOSTNAME ,user= USERNAME,passwd = PASSWORD ,db =  DBNAME, port = 3306)
    con.autocommit = True
    cursor = con.cursor()
    print ("Connected to your Database!")

    cursor.execute("SELECT COUNT(*) FROM Agro_Environmental_Parameters")
    rowscount = cursor.fetchall()
    rowscount=rowscount[0][0]
    print(rowscount)
    count=1
    while (count <= rowscount):
        cursor.execute("""SELECT * from Agro_Environmental_Parameters where Row_ID = %s""", (count, ))
        data=cursor.fetchall()
        lum=data[0][2]
        hum=data[0][3]
        temp=data[0][4]
        tt=pd.DataFrame([lum,hum,temp])
        tt=tt.transpose()
        res=lm.predict(tt)
        print(res[0])
        cursor.execute("INSERT INTO  resultat_Python() VALUES(%s,%s,%s,%s,%s,%s,%s,%s)" ,(data[0][0],data[0][1],data[0][2],data[0][3],data[0][4],data[0][5],data[0][6],int(res[0])))
        time.sleep(5)
        count=count+1

cursor.close()
con.close()
