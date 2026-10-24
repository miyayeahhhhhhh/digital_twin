
from pathlib import Path
import csv
import matplotlib.pyplot as plt

DATA_DIR = Path(__file__).parent / "data" / "mitdb"
ECG_FILE = DATA_DIR / "100.csv"
ANNOTATION_FILE = DATA_DIR / "100annotations.txt"

# Load ECG signal
samples = []
mlii = []

with open(ECG_FILE, "r", newline="", encoding="utf-8-sig") as f:
    reader = csv.reader(f)
    next(reader)  # Skip header

    for row in reader:
        if len(row) >= 2:
            try:
                samples.append(int(row[0].strip().strip("'")))
                mlii.append(float(row[1].strip().strip("'")))
            except ValueError:
                continue

# Load annotations
annotations = []

with open(ANNOTATION_FILE, "r", encoding="utf-8-sig") as f:
    for line in f:
        parts = line.split()
        if len(parts) < 3:
            continue

        try:
            sample_index = int(parts[1])
            label = parts[2]

            if 0 <= sample_index < len(mlii):
                annotations.append((sample_index, label))
        except ValueError:
            continue

# Plot the first 10 seconds.
# 360 Hz is the expected MIT-BIH rate; verify the dataset source
# before relying on timing in later calculations.
start = 0
end = min(3600, len(mlii))
x = samples[start:end]
y = mlii[start:end]

plt.figure(figsize=(14, 5))
plt.plot(x, y, linewidth=0.8, label="MLII ECG")

# Mark annotated beats within the displayed range
for sample_index, label in annotations:
    if start <= sample_index < end and label not in {"+", "~"}:
        plt.scatter(
            samples[sample_index],
            mlii[sample_index],
            s=25,
            label=f"Annotation: {label}"
        )

plt.title("HEART//TWIN — ECG Signal with Dataset Annotations")
plt.xlabel("Sample number")
plt.ylabel("Signal amplitude (raw CSV units)")
plt.grid(True, alpha=0.25)

# Avoid repeating the same legend label hundreds of times
handles, labels = plt.gca().get_legend_handles_labels()
unique = dict(zip(labels, handles))
plt.legend(unique.values(), unique.keys(), loc="upper right")

output_file = DATA_DIR / "ecg_waveform.png"
plt.tight_layout()
plt.savefig(output_file, dpi=160)
print("Saved ECG plot to:", output_file)

plt.show()
