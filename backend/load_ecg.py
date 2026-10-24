
from pathlib import Path
import csv
import json

DATA_DIR = Path(__file__).parent / "data" / "mitdb"
ECG_FILE = DATA_DIR / "100.csv"
ANNOTATION_FILE = DATA_DIR / "100annotations.txt"

def clean(value):
    return value.strip().strip("'").strip('"').strip()

# Load ECG signal
sample_numbers = []
mlii = []
v5 = []

with open(ECG_FILE, "r", newline="", encoding="utf-8-sig") as file:
    reader = csv.reader(file)
    headers = [clean(h) for h in next(reader)]

    print("CSV columns:", headers)

    for row in reader:
        if len(row) < 3:
            continue

        try:
            sample_numbers.append(int(clean(row[0])))
            mlii.append(float(clean(row[1])))
            v5.append(float(clean(row[2])))
        except ValueError:
            continue

print("\nECG loaded successfully!")
print("Total samples:", len(sample_numbers))
print("MLII samples:", len(mlii))
print("V5 samples:", len(v5))
print("First 10 MLII values:", mlii[:10])
print("First 10 V5 values:", v5[:10])

# Load beat annotations
annotations = []

with open(ANNOTATION_FILE, "r", encoding="utf-8-sig") as file:
    for line in file:
        parts = line.split()

        # Expected columns: Time, Sample #, Type, Sub, Chan, Num, Aux
        if len(parts) < 3:
            continue

        try:
            sample_index = int(parts[1])
        except ValueError:
            continue  # Skip header

        annotations.append({
            "time": parts[0],
            "sample": sample_index,
            "type": parts[2]
        })

print("\nAnnotations loaded successfully!")
print("Total annotations:", len(annotations))
print("First 10 annotations:", annotations[:10])

# Save a small preview for the next step
preview = {
    "sample_rate_hz": 360,
    "lead_names": ["MLII", "V5"],
    "samples": [
        {
            "sample": sample_numbers[i],
            "MLII": mlii[i],
            "V5": v5[i]
        }
        for i in range(min(100, len(sample_numbers)))
    ],
    "annotations": annotations[:20]
}

preview_file = DATA_DIR / "ecg_preview.json"
with open(preview_file, "w", encoding="utf-8") as file:
    json.dump(preview, file, indent=2)

print("\nPreview saved to:", preview_file)
print("DONE — ECG and annotations are ready for the next step.")
