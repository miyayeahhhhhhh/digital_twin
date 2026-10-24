# HEART//TWIN — Cardiovascular Digital Twin PoC

A Flutter proof-of-concept for the Happiest Health Digital Twin challenge. It demonstrates a polished clinician dashboard for a **synthetic cardiovascular-risk patient**, with a simulated EHR stream fused conceptually with wearable time-series signals.

> **Important:** This is a UI/prototype scaffold, not a clinically validated prediction system. All displayed values and insights are illustrative. Do not use it for diagnosis, triage, or treatment decisions.

## What's included

- Animated sign-in screen and demo workspace entry
- Responsive dashboard with sidebar on wide screens and bottom navigation on mobile
- Animated neon cardiac representation
- Optional interactive 3D model viewer slot
- Synthetic heart-rate timeline chart
- Simulated HR, HRV, sleep and activity metrics
- Risk-score presentation, model note, and explainable insight cards
- EHR + wearable data-fusion architecture panel
- Live-sync toggle, workspace navigation and sign-out

## Run it

1. Install Flutter SDK and Android Studio (or VS Code Flutter extension).
2. Extract this repository.
3. Open a terminal in the project folder.
4. Run:

```bash
flutter pub get
flutter run
```

To build an Android APK:

```bash
flutter build apk --release
```

## Add the supplied Heart.fbx model

Flutter's `model_viewer_plus` expects a web-compatible **GLB/ glTF** asset, not FBX directly. Convert the supplied `Heart.fbx` to `heart.glb`:

1. Install Blender.
2. Open Blender → `File > Import > FBX (.fbx)` and select `Heart.fbx`.
3. Inspect scale, orientation and materials; keep the model centered at the origin.
4. Choose `File > Export > glTF 2.0`.
5. Set format to **glTF Binary (.glb)** and export as `heart.glb`.
6. Place it at `assets/models/heart.glb`.
7. Run `flutter pub get` and relaunch the app.

The dashboard's **3D MODEL** control switches to the 3D viewer. Until `heart.glb` is added, the animated neon heart remains the reliable default. The source FBX can be stored in `assets/models/` for reference, but it cannot be rendered by the viewer directly.

## Prototype architecture

- **UI:** Flutter / Dart, Material 3, Google Fonts
- **Charts:** `fl_chart`
- **3D model:** `model_viewer_plus` (GLB/glTF)
- **Current data:** hard-coded synthetic demo values for UI demonstration
- **Recommended next step:** create a FastAPI service that joins synthetic EHR features and wearable time windows, runs a documented baseline model, and returns `risk_score`, `prediction_horizon`, `top_contributors`, and confidence/calibration metadata.

## Suggested ML implementation for the challenge

For a defensible PoC, separate the app from the prediction service:

1. Generate a synthetic EHR profile (age band, history, BP/lab markers) with Synthea or a clearly documented synthetic generator.
2. Use a public, licensed wearable time-series dataset or clearly labelled synthetic stream.
3. Aggregate sensor data into fixed windows (e.g., 5-minute and 1-hour summaries), handle missingness, and align it with the EHR profile.
4. Define one measurable endpoint before training. For example, a simulated abnormal heart-rate event within a two-hour horizon.
5. Start with logistic regression / gradient boosting as a transparent baseline; use patient-wise splits to avoid leakage. Report AUROC, AUPRC, sensitivity, specificity, calibration and false-alert rate.
6. Expose feature contributions and the time window behind every flag. Never imply a model trained on synthetic data is clinically validated.

## Suggested repository layout

```text
heart_twin/
├── lib/main.dart
├── assets/models/heart.glb       # add after converting Heart.fbx
├── docs/architecture.pdf         # add architecture export
├── docs/presentation.pdf         # add pitch deck export
└── README.md
```

## License

MIT License. See `LICENSE`.

## Team details

- Team: doomslayers
- Team leader: Samiya Sonawane
- Institution / incubator: MIT Academy Of Engineering
- Team members: Atharva Shimpi, Varun Dalimkar, Suhani Thakur
