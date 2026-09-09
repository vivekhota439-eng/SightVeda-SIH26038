# Diabetic Retinopathy AI Screening & Severity Grading System (SIH26038)
### MathWorks MedTech / HealthTech Compliance Suite

An end-to-end, AI-assisted diabetic retinopathy screening prototype integrating **image quality screening**, **homomorphic illumination normalization**, **bilateral denoising**, **sub-pixel microaneurysm localization (±0.15 px)**, **5-class deep CNN severity grading**, **weighted cross-entropy class imbalance resolution**, **Grad-CAM visual explainability**, **hybrid clinical rule engine (Referable DR Level 2+)**, **multilingual patient-centric reporting**, **district-scale telemedicine simulation (100,000+ patients/year)**, and an **interactive clinical GUI portal**.

---

## 1. Quick Start Guide (One-Click Execution)

### Step 1: Open MATLAB
Open MATLAB and navigate to the project directory:
```matlab
cd('C:\SIH2026\ready file');
```

### Step 2: Run the Application (ONE COMMAND)
```matlab
main_pipeline
```
*Alternatively:*
```matlab
run_pipeline
```

This launches the **One-Click Interactive Menu**:
```text
======================================================================
  DIABETIC RETINOPATHY AI SYSTEM — CLINICAL SCREENING PIPELINE
  MathWorks SIH26038 | MedTech Tele-Ophthalmology Suite
======================================================================
  [1] Analyze Retinal Image (Enter path or use default)
  [2] Select Image via Graphical File Dialog
  [3] Launch Interactive Desktop Tele-Ophthalmology Portal (GUI)
  [4] Train AI Severity Model (RTX 3050 GPU / CPU)
  [5] Run District Telemedicine Simulation (100,000+ Patients/Year)
  [6] Run Validation & Benchmark Framework (target: >90% Sens, >85% Spec)
  [7] Generate Programmatic Simulink Block Diagram (.slx)
  [8] Run Complete Automated System Verification Test Suite
  [9] Exit
======================================================================
```

### Direct Programmatic Screening Calls
```matlab
% English Report:
report = main_pipeline('input/test_image.png');

% Hindi Clinical Report (हिंदी):
report = main_pipeline('input/test_image.png', 'hi');

% Tamil Clinical Report (தமிழ்):
report = main_pipeline('input/test_image.png', 'ta');

% Telugu Clinical Report (తెలుగు):
report = main_pipeline('input/test_image.png', 'te');

% Marathi Clinical Report (मराठी):
report = main_pipeline('input/test_image.png', 'mr');

% Bengali Clinical Report (বাংলা):
report = main_pipeline('input/test_image.png', 'bn');

% Tulu Clinical Report (ತುಳು):
report = main_pipeline('input/test_image.png', 'tcy');
```

---

## 2. Training Workflow (Model Training vs Inference)

Training and prediction are decoupled. The model is trained once and saved to `models/model_weights.mat`, which is then reused during inference.

### How to Train the Retinal AI Model
```matlab
train_retinal_model
```
Or with custom hyperparameters:
```matlab
% train_retinal_model(datasetDir, epochs, batchSize, learningRate, backbone, useGpu)
train_retinal_model('dataset', 20, 16, 3e-4, 'efficientnet_b0', true);
```

### GPU Training on NVIDIA RTX 3050 6GB
- Training automatically checks for an active NVIDIA GPU via `gpuDevice()`.
- Uses `'ExecutionEnvironment', 'gpu'`.
- Default mini-batch size is set to `16` (optimized for 6GB VRAM to avoid out-of-memory errors).
- If no GPU is present or GPU memory is exhausted, the system automatically falls back to CPU training without crashing.

### Class Imbalance Resolution
- Inverse class frequency weights are computed:
  $$w_c = \frac{N_{total}}{C \cdot N_c}$$
- The weights are directly wired into a custom MATLAB loss layer (`part2_model/weightedClassificationLayer.m`), which computes weighted cross-entropy during backpropagation:
  $$\mathcal{L} = -\frac{1}{N} \sum_{i=1}^N \sum_{c=1}^C w_c \cdot T_{ic} \log(Y_{ic} + \epsilon)$$
- Class weights are actively applied during training.

### Model Existence Guard
If `models/model_weights.mat` has not been trained yet, the inference pipeline will **never** silently use random or fake weights. Instead, it displays:
```text
Trained model not found. Please train the model before running inference.
To train the model, run: train_retinal_model
```

---

## 3. End-to-End System Architecture

```text
USER INPUT RETINAL IMAGE
        ↓
IMAGE QUALITY ASSESSMENT (Focus, Brightness, Uniformity, FOV, Vessels)
        ↓
    Is Quality Acceptable?
    ├── NO (< 30% Score or Severe Defocus)
    │     ↓
    │   Display "Please capture/upload another retinal image"
    │     ↓
    │   STOP (Halts before deep learning model)
    │
    └── YES (>= 30% Score)
          ↓
    RETINAL PREPROCESSING & HOMOMORPHIC NORMALIZATION
          ↓
    EDGE-PRESERVING BILATERAL DENOISING & ADAPTIVE CLAHE
          ↓
    LOAD TRAINED MODEL (models/model_weights.mat)
          ↓
    5-CLASS SEVERITY PREDICTION (Softmax Probabilities)
          ↓
    TEMPERATURE SCALING & CONFIDENCE CALIBRATION (T = 1.25)
          ↓
    SUB-PIXEL MICROANEURYSM LOCALIZATION (2D Gaussian fit ±0.15 px)
          ↓
    EXUDATE SEGMENTATION (Disc Diameters Area) & HEMORRHAGE CLASSIFICATION
          ↓
    OPTIC DISC & FOVEA LOCALIZATION (CSME Macular Risk Check)
          ↓
    VISUAL EXPLAINABILITY & GRAD-CAM HEATMAP (<30s Rapid Doctor Review)
          ↓
    HYBRID CLINICAL RULE ENGINE (Referable DR Level 2+ Criteria & Overrides)
          ↓
    CLINICAL RECOMMENDATIONS (Etiology, Dietary Parhez, Lifting Restrictions)
          ↓
    MULTILINGUAL CLINICAL CDS REPORT (en, hi, ta, te, mr, bn, tcy)
          ↓
    SAVE OUTPUTS (output/enhanced, output/evidence, output/explainability, output/reports)
          ↓
    DISPLAY DIAGNOSTIC RESULT & INTERACTIVE GUI
```

---

## 4. Final Project Directory Structure

```text
c:/SIH2026/ready file/
│
├── main_pipeline.m                      # Master One-Click Application Entry Point
├── run_pipeline.m                       # Standardized Programmatic Execution Wrapper
├── train_retinal_model.m                # Standalone One-Click Training Entry Point
├── test_pipeline.m                      # 15-Point Automated Verification Suite
│
├── config/
│   └── config_params.m                  # Central System Configurations, Paths & Hyperparameters
│
├── part1_preprocessing/
│   ├── check_quality.m                  # 4-stage quality screening (focus, lighting, FOV, vessels)
│   ├── enhance_fundus_image.m           # Homomorphic normalization + Bilateral denoise + Adaptive CLAHE
│   ├── extract_retinal_mask.m           # Retinal FOV circular segmentation & geometric framing
│   └── process_image.m                  # Task 1 quality gate orchestrator
│
├── part2_model/
│   ├── build_network.m                  # CNN builder (EfficientNet-B0, ResNet-50, Deep Residual CNN)
│   ├── weightedClassificationLayer.m    # Custom weighted cross-entropy layer for class imbalance
│   ├── load_retinal_dataset.m           # Stratified loader with inverse class frequency weights
│   ├── train_model.m                    # Core training engine with GPU acceleration & QWK tracking
│   ├── grade_image.m                    # Diagnostic inference engine with model existence check
│   ├── compute_qwk.m                    # Quadratic Weighted Kappa metric computation
│   ├── detect_lesions_advanced.m        # Sub-pixel MAs, exudates DD, hemorrhages, CSME, OD/fovea
│   ├── subpixel_microaneurysms.m        # Closed-form 2D Gaussian surface centroid fitting (±0.15 px)
│   ├── detect_lesions.m                 # Classical morphological heuristic lesion detector
│   ├── extract_lesion_evidence.m        # 4-quadrant spatial lesion distribution
│   ├── calibrate_confidence.m           # Softmax calibration via temperature scaling & margin delta
│   ├── clinical_rule_engine.m           # Level 2+ Referable DR criteria & safety overrides
│   ├── get_clinical_recommendations.m   # Etiology, dietary parhez, and physical lifting precautions
│   ├── generate_gradcam.m               # Grad-CAM attention heatmap & peak quadrant identification
│   ├── generate_explainability.m        # Visual evidence overlays (<30s rapid doctor review metadata)
│   ├── validate_benchmarks.m            # Validation and published-benchmark context (not regulatory certification)
│   └── create_mock_dataset.m            # Synthetic 5-class fundus dataset generator
│
├── part3_report/
│   ├── generate_clinical_report.m       # Multilingual report generator (en, hi, ta, te, mr, bn, tcy)
│   └── translate_clinical_report.m      # Clinical translation dictionary & doctor sign-off
│
├── simulation/
│   ├── district_simulation.m            # 100,000+ patient/year discrete-event queueing simulation
│   ├── simulate_telemedicine_workflow.m # Monte Carlo 4-panel publication figure generator
│   ├── create_simulink_model.m          # Programmatic Simulink block diagram generator (.slx)
│   └── build_simulink_model.m           # Programmatic SimEvents district block diagram (.slx)
│
├── app/
│   └── teleophthalmology_app.m          # Interactive 4-axes MATLAB desktop GUI portal
│
├── dataset/
│   ├── images/                          # Retinal fundus training images
│   └── labels.csv                       # Ground truth labels (image_id, diagnosis)
│
├── models/
│   └── model_weights.mat                # Saved trained model checkpoint
│
├── input/
│   └── test_image.png                   # Sample test fundus image
│
├── output/
│   ├── enhanced/                        # Homomorphic & CLAHE enhanced retinal images
│   ├── evidence/                        # Annotated evidence images (OD, fovea, lesion markers)
│   ├── explainability/                  # Grad-CAM attention heatmaps
│   └── reports/                         # Formatted clinical reports (.txt and .json)
│
└── README.md                            # Comprehensive System Documentation
```

---

## 5. Feature Preservation & Mapping Checklist

| # | Feature Name | Original Source | Unified Implementation | Status |
|---|---|---|---|:---:|
| 1 | Continuous Image Quality Assessment | `matlab/preprocessing.m` | `part1_preprocessing/check_quality.m` | **Implemented — requires external validation** |
| 2 | Homomorphic Normalization & Bilateral Denoising | `matlab pipeline/part1_preprocessing/` | `part1_preprocessing/enhance_fundus_image.m` | **Implemented — requires external validation** |
| 3 | Dual-Channel Adaptive CLAHE (Luminance + Green) | `matlab pipeline/part1_preprocessing/` | `part1_preprocessing/enhance_fundus_image.m` | **Implemented — requires external validation** |
| 4 | Retinal Mask & Field of View Framing Checks | `matlab pipeline/part1_preprocessing/` | `part1_preprocessing/extract_retinal_mask.m` | **Implemented — requires external validation** |
| 5 | Quality Gate (<30% Rejection & Recapture Advice) | `matlab/preprocessing.m` | `part1_preprocessing/process_image.m` | **Implemented — requires external validation** |
| 6 | 5-Class CNN Builder (EfficientNet, ResNet, Custom) | `matlab pipeline/part2_model/` | `part2_model/build_network.m` | **Implemented — requires external validation** |
| 7 | Stratified Retinal Dataset Loader | `matlab pipeline/part2_model/` | `part2_model/load_retinal_dataset.m` | **Implemented — requires external validation** |
| 8 | Class Imbalance Handling via Weighted Loss Layer | *New Integration* | `part2_model/weightedClassificationLayer.m` | **Implemented & Active** |
| 9 | GPU Training Support (RTX 3050 6GB) & CPU Fallback | `matlab pipeline/part2_model/` | `part2_model/train_model.m` | **Implemented — requires external validation** |
| 10 | Standalone Model Training Entry Point | *New Requirement* | `train_retinal_model.m` | **Implemented & Active** |
| 11 | Quadratic Weighted Kappa (QWK) Metric | `matlab pipeline/part2_model/` | `part2_model/compute_qwk.m` | **Implemented — requires external validation** |
| 12 | Diagnostic Inference Engine with Model Check | `matlab pipeline/part2_model/` | `part2_model/grade_image.m` | **Implemented — requires external validation** |
| 13 | Classical Heuristic Lesion Detector | `matlab pipeline/part2_model/` | `part2_model/detect_lesions.m` | **Implemented — requires external validation** |
| 14 | Sub-Pixel Microaneurysm Localization (±0.15 px) | `matlab_simulink/` | `part2_model/subpixel_microaneurysms.m` | **Implemented — requires external validation** |
| 15 | Exudate Segmentation & Disc Diameters (DD) Area | `matlab pipeline/part2_model/` | `part2_model/detect_lesions_advanced.m` | **Implemented — requires external validation** |
| 16 | Hemorrhage Classification (Dot/Blot, Flame, Preretinal) | `matlab pipeline/part2_model/` | `part2_model/detect_lesions_advanced.m` | **Implemented — requires external validation** |
| 17 | Optic Disc & Fovea Localization / CSME Risk | `matlab pipeline/part2_model/` | `part2_model/detect_lesions_advanced.m` | **Implemented — requires external validation** |
| 18 | 4-Quadrant Spatial Lesion Distribution | `matlab_simulink/` | `part2_model/extract_lesion_evidence.m` | **Implemented — requires external validation** |
| 19 | Temperature Scaling Confidence Calibration | `matlab_simulink/` | `part2_model/calibrate_confidence.m` | **Implemented — requires external validation** |
| 20 | Hybrid Clinical Rule Engine (Level 2+ Referable DR) | `matlab pipeline/part2_model/` | `part2_model/clinical_rule_engine.m` | **Implemented — requires external validation** |
| 21 | Clinical Etiology, Dietary Parhez & Lifting Warnings | `matlab_simulink/` | `part2_model/get_clinical_recommendations.m` | **Implemented — requires external validation** |
| 22 | Grad-CAM Attention Heatmap & Peak Quadrant | `matlab_simulink/` | `part2_model/generate_gradcam.m` | **Implemented — requires external validation** |
| 23 | Visual Evidence Overlay Image (<30s Review Metadata) | `matlab pipeline/part2_model/` | `part2_model/generate_explainability.m` | **Implemented — requires external validation** |
| 24 | Multilingual Clinical CDS Reports (7 Languages) | `matlab pipeline/` & `matlab_simulink/` | `part3_report/generate_clinical_report.m` | **Implemented — requires external validation** |
| 25 | Interactive 4-Axes Desktop Tele-Ophthalmology GUI | `matlab_simulink/` | `app/teleophthalmology_app.m` | **Implemented — requires external validation** |
| 26 | District Telemedicine Queue Simulation (100k+ Patients) | `matlab pipeline/` & `matlab_simulink/` | `simulation/district_simulation.m` | **Implemented — requires external validation** |
| 27 | Programmatic Simulink Block Diagram Generation | `matlab pipeline/` & `matlab_simulink/` | `simulation/create_simulink_model.m` | **Implemented — requires external validation** |
| 28 | Validation & benchmark comparison framework | `matlab pipeline/` & `matlab_simulink/` | `part2_model/validate_benchmarks.m` | **Implemented — requires external validation** |
| 29 | Synthetic 5-Class Fundus Dataset Generator | `matlab pipeline/part2_model/` | `part2_model/create_mock_dataset.m` | **Implemented — requires external validation** |
| 30 | Centralized Configuration Parameters | `matlab pipeline/part2_model/` | `config/config_params.m` | **Implemented — requires external validation** |
| 31 | Automated 15-Point Verification Test Suite | `matlab pipeline/` | `test_pipeline.m` | **Implemented — requires external validation** |
| 32 | One-Click Master Pipeline Entry Point | *Unified Integration* | `main_pipeline.m` | **Implemented & Active** |

---

## 6. How to Run the Automated Verification Suite

To run the automated 15-point verification suite:
```matlab
test_pipeline
```
This validates all modules, quality checking, preprocessing, lesion quantification, clinical rule engine, report generation, and simulations.

---

## 7. Required MATLAB Toolboxes

1. **MATLAB Base** (R2022b or later recommended; verified on R2025a)
2. **Image Processing Toolbox** (`imtophat`, `imbothat`, `adapthisteq`, `rgb2lab`, `bwconncomp`, `regionprops`)
3. **Deep Learning Toolbox** (`trainNetwork`, `layerGraph`, `classificationLayer`, `convolution2dLayer`)
4. **Computer Vision Toolbox** (`imfindcircles`)
5. **Statistics and Machine Learning Toolbox** (`cvpartition`, `countcats`, `poissrnd`)
6. *Optional:* **Simulink** / **SimEvents** (for running `.slx` block diagram simulations)

*Note: The codebase includes resilient native MATLAB fallbacks for all image processing, filtering, and connected-component labeling operations if specific toolboxes are not available.*

---

## 8. Troubleshooting & Frequently Asked Questions

### Q1: "Trained model not found at 'models/model_weights.mat'..."
- **Cause**: Inference was attempted before running the training routine.
- **Solution**: Run `train_retinal_model` or select Option `[4]` from `main_pipeline` to train the model on your dataset.

### Q2: "Out of memory on GPU during training"
- **Cause**: MiniBatchSize is too large for the 6GB VRAM.
- **Solution**: In `config/config_params.m`, ensure `DEFAULT_BATCH_SIZE = 16` or reduce to `8`. You can also run:
  ```matlab
  train_retinal_model('dataset', 15, 8);
  ```

### Q3: "Image quality check failed: ungradable"
- **Cause**: The input retinal photograph has severe defocus blur, underexposure, overexposure, or obstructed FOV.
- **Solution**: As instructed by the clinical safety gate, recapture the retinal fundus image with proper illumination and focus.

### Q4: "How do I launch the interactive desktop GUI?"
- **Solution**: In MATLAB Command Window, simply run:
  ```matlab
  teleophthalmology_app
  ```
  Or select Option `[3]` from `main_pipeline`.
