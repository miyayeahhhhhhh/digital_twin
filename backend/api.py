
from pathlib import Path
import csv

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="HEART//TWIN ECG API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DATA_DIR = Path(__file__).parent / "data" / "mitdb"
ECG_FILE = DATA_DIR / "100.csv"
ANNOTATION_FILE = DATA_DIR / "100annotations.txt"


def load_ecg():
    samples, mlii, v5 = [], [], []

    with open(ECG_FILE, newline="", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        next(reader, None)

        for row in reader:
            if len(row) < 3:
                continue
            try:
                samples.append(int(row[0].strip().strip("'")))
                mlii.append(float(row[1].strip().strip("'")))
                v5.append(float(row[2].strip().strip("'")))
            except ValueError:
                continue

    return samples, mlii, v5


def load_annotations():
    annotations = []

    with open(ANNOTATION_FILE, encoding="utf-8-sig") as f:
        for line in f:
            parts = line.split()
            if len(parts) < 3:
                continue
            try:
                annotations.append({
                    "sample": int(parts[1]),
                    "type": parts[2]
                })
            except ValueError:
                continue

    return annotations


@app.get("/")
def home():
    return {"status": "running", "project": "HEART//TWIN"}


@app.get("/api/ecg")
def get_ecg(start: int = 0, count: int = 1000, lead: str = "MLII"):
    if start < 0 or count < 1 or count > 5000:
        raise HTTPException(400, "Use start >= 0 and count between 1 and 5000")

    samples, mlii, v5 = load_ecg()

    if start >= len(samples):
        raise HTTPException(404, "Start sample is outside the recording")

    if lead not in ("MLII", "V5"):
        raise HTTPException(400, "Lead must be MLII or V5")

    signal = mlii if lead == "MLII" else v5
    end = min(start + count, len(samples))

    annotations = [
        item for item in load_annotations()
        if start <= item["sample"] < end
    ]

    return {
        "record": "MIT-BIH record 100",
        "lead": lead,
        "start": start,
        "count": end - start,
        "samples": samples[start:end],
        "values": signal[start:end],
        "annotations": annotations
    }
