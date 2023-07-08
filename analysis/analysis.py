import matplotlib.pyplot as plt
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

# Set labels and title
ax.set_xlabel('Mutant')
ax.set_ylabel('Time to break invariants (seconds)')
ax.set_title('Time to break invariants per Mutant')

# Set y-axis to logarithmic scale
ax.set_yscale("log")

# Show legend
ax.legend()

# Save the plot to a PNG file
plt.tight_layout()
plt.savefig("/tmp/final.png")

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
                winner = 'same'
            else:
                if data1.median() < data2.median():
                    winner = fuzzer1
                else:
                    winner = fuzzer2
            print('Mutant', mutant, winner)