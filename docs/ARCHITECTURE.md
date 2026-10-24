# HEART//TWIN — Architecture

```text
Synthetic EHR profile ──────┐
(age, history, labs, risk)   │
                             ├──> Feature alignment / quality checks
Wearable time-series ────────┘          │
(HR, HRV, sleep, steps)                 v
                                  Feature windowing
                                        │
                                        v
                              Baseline risk prediction
                              + explanation metadata
                                        │
                                        v
                           FastAPI prediction endpoint
                                        │
                                        v
                          Flutter clinician dashboard
                   patient twin / timeline / risk / insights
```

Current Flutter app contains simulated dashboard values and UI states. The prediction API and trained model are a next implementation phase, not claimed to exist in this scaffold.
