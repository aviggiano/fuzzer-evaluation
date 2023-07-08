import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy.stats import mannwhitneyu

# Read data from CSV file
df = pd.read_csv("/tmp/final.csv")

# Convert 'mutant' to integers
df['mutant'] = df['mutant'].astype(int)

# Convert 'mutant' to two-digit, zero-padded strings
df['mutant'] = df['mutant'].apply(lambda x: f'{x:02}')

# Sort the DataFrame by 'mutant'
df = df.sort_values('mutant')

# Rename mutants
mutant_dict = {
    "03": "01",
    "05": "02",
    "06": "03",
    "07": "04",
    "08": "05",
    "09": "06",
    "10": "07",
    "11": "08",
    "12": "09",
    "13": "10",
    "14": "11",
    "15": "12"
}

# Use the dictionary to replace the values
df['mutant'] = df['mutant'].replace(mutant_dict)

# Remove instance_id column
df = df.drop(columns='instance_id')
# Drop duplicate rows
df = df.drop_duplicates(subset=['fuzzer', 'mutant', 'seed'])
df.sort_values(by=['seed', 'mutant']).to_csv('/tmp/final2.csv', index=False)

# Group by 'fuzzer', 'mutant', and 'seed', then count the number of rows for each group
grouped_df = df.groupby(['fuzzer', 'mutant']).size().reset_index(name='counts')

# Print the number of rows for each group
print(grouped_df)

# Create a boxplot
fig, ax = plt.subplots(figsize=(15,8))

mutants = df['mutant'].unique()

# Add alternating background colors
for i in range(len(mutants)):
    if i % 2 == 0:
        ax.axvspan(i-0.5, i+0.5, facecolor='lightgrey', zorder=0)

# Using seaborn to create boxplot as it supports creating multiple boxes for each category (fuzzers for each mutant) directly
sns.boxplot(data=df, x='mutant', y='time', hue='fuzzer', ax=ax, flierprops=dict(markerfacecolor='gray', markersize=5), zorder=2)

# Add stripplot to plot datapoints
sns.stripplot(data=df, x='mutant', y='time', hue='fuzzer', dodge=True, linewidth=0.5, palette='dark', ax=ax, zorder=1)

# Fetch legend handles and labels
handles, labels = ax.get_legend_handles_labels()

# Build a color dictionary for each fuzzer
fuzzer_colors = {label: handle.get_facecolor() for handle, label in zip(handles, labels) if label in df['fuzzer'].unique()}

# Set labels and title
ax.set_xlabel('Mutant')
ax.set_ylabel('Time to break invariants (seconds)')
ax.set_title('Time to break invariants per Mutant')

# Set y-axis to logarithmic scale
ax.set_yscale("log")

# Show legend
ax.legend()

# Find the lower limit for y
y_lower = df['time'].min() / 10  # Adjust this divisor to suit your needs

# Set the y-axis limit
ax.set_ylim(bottom=y_lower)

fuzzers = df['fuzzer'].unique()

# For each mutant and fuzzer, perform the Mann-Whitney U Test
for mutant in mutants:
    for i in range(len(fuzzers)):
        for j in range(i+1, len(fuzzers)):
            fuzzer1 = fuzzers[i]
            fuzzer2 = fuzzers[j]

            data1 = df[(df['fuzzer'] == fuzzer1) & (df['mutant'] == mutant)]['time']
            data2 = df[(df['fuzzer'] == fuzzer2) & (df['mutant'] == mutant)]['time']

            # Perform the test
            stat, p = mannwhitneyu(data1, data2)

            if p > 0.05:
                winner = 'N/A'
                color = 'gray'  # Choose a default color when there's no significant difference
            else:
                if data1.median() < data2.median():
                    winner = fuzzer1
                else:
                    winner = fuzzer2
                color = fuzzer_colors[winner]  # Get the color of the winning fuzzer
            print('Mutant', mutant, winner)
            # Format p-value to string rounded to 2 decimal places
            p_str = "{:.2f}".format(p)

            # Calculate the position for the annotation, position it in the center of each mutant group
            mutant_index = list(df['mutant'].unique()).index(mutant)
            # Annotate the p-value on the chart
            ax.text(mutant_index, 0.05, f'p={p:0.2f}',
                    ha='center',
                    va='top',
                    transform=ax.get_xaxis_transform(),
                    bbox=dict(facecolor=color, alpha=0.5, edgecolor='black', linewidth=1))




# Save the plot to a PNG file
plt.tight_layout()
plt.savefig("/tmp/final.png")
