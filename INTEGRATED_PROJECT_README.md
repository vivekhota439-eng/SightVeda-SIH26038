# SIH26038 Website + RETINAL_AI_PROJECT MATLAB Backend

## What this combined project does

- **Website/UI:** kept from the SIH26038 Diabetic Retinopathy Web Portal.
- **Dashboard:** same SIH26038 dashboard, screening page, results viewer, validation page, simulation page, model-spec page, doctor-feedback dashboard, language/audio features, webcam/upload flow and routes.
- **AI/diagnostic backend:** the Python website does **not** use the old SIH Python heuristic diagnosis. Each diagnosis is sent to the MATLAB `RETINAL_AI_PROJECT/main_pipeline.m` pipeline.
- **MATLAB project location:** the website and MATLAB project now live in the **same root folder**.
- **Model:** `models/model_weights.mat` is copied into the CLEAN project because `RETINAL_AI_PROJECT/part2_model/grade_image.m` requires it.
- **Validation:** `models/validation_results.mat` and JSON are also available for the dashboard.

## Flow

Browser → Flask SIH26038 UI → `pipeline.py` → MATLAB batch bridge → `main_pipeline.m` →
`process_image.m` → `grade_image.m` → lesion analysis → explainability → clinical report →
back to website.

## Run on Windows

1. Install MATLAB with the toolboxes required by the CLEAN MATLAB pipeline.
2. Install Python 3.9–3.12.
3. Double-click `run_website.bat`.
4. Open `http://127.0.0.1:5000` if it does not open automatically.

### If MATLAB is not in PATH

Set the environment variable `MATLAB_EXE` to the full path of `matlab.exe`, for example:

`C:\Program Files\MATLAB\R2025b\bin\matlab.exe`

Then run `run_website.bat` again.

## Run from MATLAB

From the project root in MATLAB:

```matlab
run_web_portal_from_matlab
```

This starts the Flask website. The website's diagnosis requests call the same CLEAN MATLAB pipeline.

## Important

The website UI/features are preserved, but diagnostic results now depend on the CLEAN MATLAB code and its model file. This is an integration/demo system, not a medical device or substitute for clinician review.
