import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

df = pd.read_csv ('/tmp/final.csv')

# x = np.array(df['seed'])
# y = np.array(df['time'].median())

# plt.bar(x, y, linestyle='None')

df.median().plot(kind='bar')

# plt.savefig('figure.png', dpi=400, transparent=True)
plt.show()
