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
fig, ax = plt.subplots(figsize=(15,8))

# Add alternating background colors
for i in range(len(df['mutant'].unique())):
    if i % 2 == 0:
        ax.axvspan(i-0.5, i+0.5, facecolor='lightgrey', zorder=0)

# Using seaborn to create boxplot as it supports creating multiple boxes for each category (fuzzers for each mutant) directly
sns.boxplot(data=df, x='mutant', y='time', hue='fuzzer', ax=ax, zorder=1)

# Set labels and title
ax.set_xlabel('Mutant')
ax.set_ylabel('Time (Log Scale)')
ax.set_title('Time Distribution of Different Fuzzers per Mutant')

# Set y-axis to logarithmic scale
ax.set_yscale("log")

# Show legend
ax.legend()

# Save the plot to a PNG file
plt.tight_layout()
plt.savefig("/tmp/final.png")
