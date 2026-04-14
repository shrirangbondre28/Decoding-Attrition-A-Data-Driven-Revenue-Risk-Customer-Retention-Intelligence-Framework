#!/usr/bin/env python
# coding: utf-8

# In[2]:


import pandas as pd
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port="5433",   # FIXED
    database="e-commerce_analysis",
    user="postgres",
    password="Shri@2004"
)

df = pd.read_sql("SELECT * FROM customer_360", conn)
df.to_csv("customer_360.csv", index=False)

conn.close()


# In[3]:


print(df.head())
print(df.shape)


# In[4]:


#feature engineering
import pandas as pd
import numpy as np

df = pd.read_csv("customer_360.csv")

# Handle nulls ffrom 0 order cust
df['total_orders'] = df['total_orders'].fillna(0)
df['total_revenue'] = df['total_revenue'].fillna(0)
df['avg_order_value'] = df['avg_order_value'].fillna(0)
df['discount_usage_rate'] = df['discount_usage_rate'].fillna(0)
df['total_returns'] = df['total_returns'].fillna(0)

# Encode categoricals
df = pd.get_dummies(df, columns=['gender', 'city', 'acquisition_channel'], drop_first=True)

# Features to use
features = [
    'age', 'total_orders', 'total_revenue', 'avg_order_value',
    'discount_usage_rate', 'total_returns', 'total_cancellations',
    'last_login_days', 'session_count', 'last_purchase_days', 'email_click_rate'
] + [c for c in df.columns if c.startswith(('gender_', 'city_', 'acquisition_channel_'))]

X = df[features]
y = df['churn_flag']


# In[5]:


#training logistics regrn 
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, roc_auc_score

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# Scale
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Train
model = LogisticRegression(max_iter=1000, class_weight='balanced', random_state=42)
model.fit(X_train_scaled, y_train)

# Evaluate
y_pred = model.predict(X_test_scaled)
y_prob = model.predict_proba(X_test_scaled)[:, 1]

print(classification_report(y_test, y_pred))
print(f"ROC-AUC Score: {roc_auc_score(y_test, y_prob):.4f}")


# In[6]:


#feature imp
import matplotlib.pyplot as plt

coef_df = pd.DataFrame({
    'feature': features,
    'coefficient': model.coef_[0]
}).sort_values('coefficient', ascending=False)

print("Top Churn Drivers:")
print(coef_df.head(10))

# Plot
coef_df.set_index('feature')['coefficient'].plot(kind='bar', figsize=(14,5))
plt.title("Logistic Regression Coefficients — Churn Drivers")
plt.tight_layout()
plt.savefig("feature_importance.png")


# In[9]:


# Add predictions to dataframe
df_predictions = df[['customer_id']].copy()
df_predictions['churn_probability'] = model.predict_proba(scaler.transform(X))[:, 1]
df_predictions['predicted_churn'] = (df_predictions['churn_probability'] > 0.5).astype(int)

# Save to CSV for Power BI import
df_predictions.to_csv("churn_predictions.csv", index=False)

# Or write back to PostgreSQL
from sqlalchemy import create_engine

engine = create_engine("postgresql://postgres:Shri%402004@localhost:5433/e-commerce_analysis")

df_predictions.to_sql("churn_predictions", engine, if_exists='replace', index=False)


# In[ ]:




