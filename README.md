# HEART//TWIN: Cardiovascular Digital Twin Platform

*STATUS NOTE: This project is a research and demonstration platform describing an intended final system. It does not claim clinical validation.*

---

## 📋 Submission Details (Mandatory Information)

### Project Title
**HEART//TWIN**

### Team Details
*   **Team Name:** de-bugged
*   **Team Leader:** Samiya Sonawane
*   **Team Members:**
    *   Atharva Shimpi 
    *   Varun Dalimkar 
    *   Suhani Thakur  

### College/Incubator Information
*   **Institution/College:** MIT Academy Of Engineering, Pune
*   

### Links & Assets 
*(Note: All linked files are publicly accessible without additional permissions)*
*   🎥 **15-20 Minute Demo Video (Unlisted YouTube):** [
*   🏗️ **Architecture Diagram (PDF/PPT):** 
*   📊 **Project Presentation (PDF/PPT):** 

---

## 🚨 Problem Statement
Current cardiovascular monitoring systems often fragment patient data. Clinicians frequently have to switch between static historical records (medical history, previous ECGs, demographics) and dynamic physiological signals (live ECG waveforms, wearables). There is a critical need for a system that moves beyond just displaying static health metrics to providing a continuously updated, dynamic, and interpretable representation of an individual patient’s evolving cardiovascular state.

## 🏥 Healthcare Use Case
**HEART//TWIN** acts as an advanced clinical decision support and visualization tool. 
*   **For Cardiologists & Clinical Teams:** Provides a consolidated, unified view of ECG signals, historical patient context, and explainable AI model outputs for reviewing cardiac trends.
*   **For Personalized Monitoring:** Represents changes in a specific patient's cardiac state over time (a digital twin), rather than a generic heart model.
*   **For Remote Patient Monitoring (Future):** With appropriate validation, the platform is designed to support longitudinal monitoring between clinic visits by fusing wearable device streams with historical EHR data.

---

## 💻 Technical Stack

### Frontend
*   **Flutter & Dart:** Clinician dashboard, mobile application UI, patient metrics display, ECG visualizer, and twin settings.

### Backend & API
*   **Python & FastAPI:** REST API for data loading, preprocessing, feature extraction, and prediction delivery. Served via Uvicorn.

### Signal Processing & Analytics
*   **NumPy & Pandas:** Numerical processing and dataset integration.
*   **WFDB (Waveform Database):** Reading and processing supported ECG records and annotations.

### 3D Visualization (Planned)
*   **NVIDIA Omniverse:** Intended for rich 3D digital-twin heart visualization and synchronized state representation.

### Environment & Tools
*   VS Code, Git/GitHub, Android Emulator, Python Virtual Environments.

---

## 🤖 AI/ML Model and Framework Details

The analytics engine of HEART//TWIN focuses on multimodal data fusion and explainable risk assessment:

1.  **Data Ingestion & Dataset:** Currently utilizes the **MIT-BIH Arrhythmia Database** (via Kaggle) for ECG recordings and heartbeat annotations.
2.  **Signal Processing Framework:** Uses **WFDB** and standard signal-processing techniques to validate inputs, handle missing data, check for noise, and align timestamps.
3.  **Feature Extraction:** Derives measurable characteristics (e.g., heart rate, beat-to-beat intervals) directly from the raw ECG waveforms.
4.  **Multimodal Data Fusion:** Combines these ECG-derived features with historical clinical variables (EHR data) at compatible time points, preserving data provenance.
5.  **Predictive Analytics:** Employs a transparent baseline model using justified ECG features to estimate risk and identify concerning patterns. The system is designed to provide *interpretable evidence* (showing waveforms, contributing features, and uncertainty) rather than just an unexplained, fabricated risk score. 

---

## 🏗️ System Architecture

Our end-to-end architecture is divided into five core layers:

*   **LAYER 1 — DATA ACQUISITION:** Historical EHR / patient records • ECG dataset (MIT-BIH) • Future wearable streams.
*   **LAYER 2 — DATA PREPROCESSING:** Signal validation • Missing-data handling • Noise checks • Timestamp alignment • Feature extraction.
*   **LAYER 3 — MULTIMODAL DATA FUSION:** Combine ECG-derived features with historical clinical variables and track data provenance.
*   **LAYER 4 — ANALYTICS AND PREDICTION:** Signal analysis • Risk estimation • Model confidence • Interpretable evidence.
*   **LAYER 5A — FLUTTER APP:** ECG explorer • Patient dashboard • Alerts • Insights.
*   **LAYER 5B — NVIDIA OMNIVERSE:** Planned 3D heart / digital twin visualization.

---

## ⚙️ End-to-End Workflow

1.  **Acquire Data:** Load historical patient context and an ECG recording.
2.  **Validate Inputs:** Confirm file readability, units, sampling rate, and check for missing/corrupted samples.
3.  **Process ECG:** Derive signal features and preserve the original waveform for inspection.
4.  **Prepare Patient Context:** Organize historical clinical variables and their timestamps.
5.  **Fuse Data:** Associate ECG-derived features with relevant patient information. Label real, synthetic, and derived values.
6.  **Estimate Risk:** Run the defined model and return its result with supporting explainable evidence.
7.  **Visualize the Twin:** Update the Flutter dashboard and (optionally) synchronize state with the Omniverse visualization.
8.  **Review Output:** Present findings for clinician review (not for autonomous diagnosis).

---

## 📄 Open-Source License Details

This project is licensed under the **MIT License**.

```text
MIT License

Copyright (c) 2026 [Insert Team Name/Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
