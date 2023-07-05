import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

# Read data from CSV file
df = pd.read_csv("/tmp/final.csv")

# Convert 'mutant' to integers
df['mutant'] = df['mutant'].astype(int)

# Sort the DataFrame by 'mutant'
df = df.sort_values('mutant')

# Calculate the median time for each fuzzer for each mutant
medians = df.groupby(['mutant', 'fuzzer'])['time'].median().unstack()

# Calculate the standard deviation
std_devs = df.groupby(['mutant', 'fuzzer'])['time'].std().unstack()

# Create a bar plot
plt.figure(figsize=(15,8))
bar_width = 0.35
opacity = 0.8

for i, (colname, values) in enumerate(medians.items()):
    plt.bar(np.arange(len(medians.index)) + (i-0.5)*bar_width, values, width=bar_width, yerr=std_devs[colname],
            alpha=opacity, color=sns.color_palette('viridis')[i], label=colname)

# Set labels and title
plt.xlabel('Mutant')
plt.ylabel('Median Time (Log Scale)')
plt.title('Median Time of Different Fuzzers per Mutant')

# Format mutant values as two-digit, zero-padded strings for x-ticks
formatted_mutants = [f'{x:02}' for x in medians.index]

# Set x-ticks
plt.xticks(np.arange(len(medians.index)), formatted_mutants, rotation=90) 

# Set y-axis to logarithmic scale
plt.yscale("log")

# Show legend
plt.legend()

# Save the plot to a PNG file
plt.tight_layout()
plt.savefig("/tmp/final.png")
