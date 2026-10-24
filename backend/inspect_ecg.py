
from pathlib import Path
import csv

DATA_DIR = Path(__file__).parent / "data" / "mitdb"
ecg_file = DATA_DIR / "100.csv"
annotation_file = DATA_DIR / "100annotations.txt"

print("\n--- ECG CSV INSPECTION ---")
with open(ecg_file, "r", encoding="utf-8-sig", errors="replace", newline="") as f:
    for i, row in enumerate(csv.reader(f)):
        print(row[:10])
        if i >= 5:
            break

print("\n--- ANNOTATION FILE INSPECTION ---")
with open(annotation_file, "r", encoding="utf-8-sig", errors="replace") as f:
    for i, line in enumerate(f):
        print(line.rstrip()[:200])
        if i >= 9:
            break

print("\n--- FILE SIZES ---")
for path in [ecg_file, annotation_file, DATA_DIR / "100.hea"]:
    print(f"{path.name}: {path.stat().st_size:,} bytes")
