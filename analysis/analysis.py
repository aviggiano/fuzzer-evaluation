import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

# Read data from CSV file
df = pd.read_csv("/tmp/final.csv")

# Convert 'mutant' to integers
df['mutant'] = df['mutant'].astype(int)

# Convert 'mutant' to two-digit, zero-padded strings
df['mutant'] = df['mutant'].apply(lambda x: f'{x:02}')

# Sort the DataFrame by 'mutant'
df = df.sort_values('mutant')

# Create a boxplot
plt.figure(figsize=(15,8))

# Using seaborn to create boxplot as it supports creating multiple boxes for each category (fuzzers for each mutant) directly
sns.boxplot(data=df, x='mutant', y='time', hue='fuzzer')

# Set labels and title
plt.xlabel('Mutant')
plt.ylabel('Time (Log Scale)')
plt.title('Time Distribution of Different Fuzzers per Mutant')

# Set y-axis to logarithmic scale
plt.yscale("log")

# Show legend
plt.legend()

# Save the plot to a PNG file
plt.tight_layout()
plt.savefig("/tmp/final.png")
