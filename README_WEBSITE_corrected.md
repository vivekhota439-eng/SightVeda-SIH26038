# SightVeda — Diabetic Retinopathy AI Web Portal (SIH26038)
### AI-Assisted Research & Screening Prototype

An end-to-end, AI-assisted clinical screening web prototype for **Diabetic Retinopathy Screening & Severity Grading**, integrating:
1. **Real Trained Model Weights:** `models/model_weights.mat` (EfficientNet-B0 CNN, 30 Epochs GPU trained)
2. **Prototype Validation:** `models/validation_results.mat` (4,293 validation samples represented by the supplied confusion matrix, 5x5 Confusion Matrix, QWK: 0.8479)
3. **Task 1: Quality Gate & Enhancement:** Focus variance & illumination check (<30% score rejection gate), Homomorphic normalization & green-channel CLAHE
4. **Task 2: Sub-Pixel Biomarkers (±0.15 px):** Closed-form 2D Gaussian fit microaneurysms, hemorrhages, exudates DD area, Optic Disc & Fovea CSME risk, 4 quadrants (ST, SN, IT, IN)
5. **Task 3: Grad-CAM Explainability & Multilingual CDS:** 65/35% blended retinal overlay, 7 Indian languages (en, hi, mr, ta, te, bn, tcy), spoken Hindi audio player
6. **Task 4: District Telemedicine Simulation:** 100,000+ patients/year discrete-event queueing model across 35 PHCs with 2G/3G/4G bandwidth

---

## 🚀 Quick Start Guide (One-Click Launch)

### Option A: Double-Click Launcher (Windows Desktop)
Simply double-click the launcher file:
- **`run_website.bat`** (or the shortcut on your Desktop: `Launch_Diabetic_Retinopathy_Website.bat`)
- This starts the Flask AI Web Server and automatically opens your web browser at:
  **http://127.0.0.1:5000**

### Option B: Terminal / Command Prompt
```bash
cd "C:\SIH2026\build_integrated"
pip install -r requirements.txt
python app.py
```
Open browser at: `http://127.0.0.1:5000`

---

## 📁 Project Directory Structure

```text
SIH26038_Diabetic_Retinopathy_Web_Portal/
│
├── app.py                             # Main Flask Web Application Server & API Routes
├── pipeline.py                        # End-to-End Clinical Diagnostic Orchestrator
├── biomarkers_engine.py               # Sub-Pixel Microaneurysms (±0.15px), Exudates, Hemorrhages
├── matlab_bridge.py                   # Integration bridge for model_weights.mat & validation_results.mat
├── quality.py                         # 4-Stage Retinal Image Quality Assessment Gate
├── explainability.py                  # Grad-CAM Attention Heatmap & Blended Overlay
├── translation.py                     # Multilingual Translation Engine (7 Languages)
├── audio_generator.py                 # Natural Spoken Hindi Voice Narration Generator (gTTS)
├── generate_preset_samples.py         # Synthetic Clinical Fundus Presets (Grades 0-4 + Ungradable)
│
├── models/
│   ├── model_weights.mat              # Trained EfficientNet-B0 weights checkpoint (31.6 MB)
│   ├── validation_results.mat         # Prototype validation data (4,293 validation samples represented by the supplied confusion matrix, QWK: 0.8479)
│   └── validation_results.json        # Extracted validation JSON metrics
│
├── templates/
│   ├── base.html                      # Modern responsive navbar & layout
│   ├── index.html                     # Executive Dashboard with population stats & model banner
│   ├── screen.html                    # Clinical Screening, Webcam, 4-Axes Viewer, 7 Languages
│   ├── validation.html                # 5x5 Confusion Matrix, Class Weights, Training Specs
│   ├── simulation.html                # Interactive 100,000+ Patients/Year District Telemedicine Scenario Simulator
│   ├── model_spec.html                # Full Mathematical Architecture & Compliance Specifications
│   └── feedback_dashboard.html        # Clinician-in-the-Loop Active Learning Logger
│
├── static/
│   ├── css/
│   │   └── style.css                  # Modern clinical medical styling
│   └── images/
│       ├── user_fundus_sample.png     # User's uploaded synthetic retinal fundus
│       ├── preset_grade_0_normal.png  # Normal healthy retina preset
│       ├── preset_grade_1_mild.png    # Mild NPDR preset
│       ├── preset_grade_2_moderate.png# Moderate NPDR preset
│       ├── preset_grade_3_severe.png  # Severe NPDR preset
│       ├── preset_grade_4_pdr.png     # Proliferative DR preset
│       └── preset_ungradable_blurry.png # Blurry ungradable quality gate test sample
│
├── outputs/                           # Generated enhanced fundus, annotated maps, audio MP3s
├── requirements.txt                   # Python package dependencies
├── run_website.bat                    # Windows 1-Click Launch Script
├── run_website.ps1                    # PowerShell Launch Script
└── README_WEBSITE.md                  # This Documentation File
```

---

## 🔍 Key Website URLs

| URL Route | Page Title | Description |
|---|---|---|
| `/` | **Executive Dashboard** | Real-time population screening counts, live model weights status, recent screenings |
| `/screen` | **Clinical Screening** | Live webcam, file upload, presets, 4-axes image viewer, 7 languages, Hindi voice |
| `/validation` | **Model Validation** | Interactive 5x5 Confusion Matrix, QWK 0.8479, class weights, download .mat |
| `/simulation` | **100k Tele-Sim** | Interactive district telemedicine simulation with 2G/3G/4G bandwidth & staffing |
| `/model-spec` | **Model Specs** | Mathematical equations (LoG centroid, weighted cross-entropy, temperature scaling) |
| `/feedback-dashboard` | **Doctor Feedback** | Active learning feedback logging for ophthalmologists |

---

## 📊 Integrated Model Performance

The supplied validation artifact contains a confusion matrix representing **4,293 samples**.

| Metric | Result | SIH Target | Status |
|---|---:|---:|---|
| Best observed prototype accuracy | **78.0%** | — | Team-observed |
| Supplied validation-artifact accuracy | **74.38%** | — | Measured |
| Quadratic Weighted Kappa | **0.8479** | — | Measured |
| Referable DR sensitivity | **81.46%** | >90% | Target not yet met |
| Specificity | **92.09%** | >85% | Target met |

The 78% value is the best observed prototype accuracy reported by the team; it is not a substitute for the supplied validation artifact. The SIH acceptance target is specifically focused on sensitivity and specificity for referable DR. External clinical validation remains necessary.
