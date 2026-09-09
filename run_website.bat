@echo off
setlocal
cd /d "%~dp0"
echo ============================================================
echo SIH26038 Web Portal + RETINAL_AI_PROJECT MATLAB Backend
echo ============================================================
where python >nul 2>nul
if errorlevel 1 (
  echo Python is not installed or not in PATH.
  echo Install Python 3.9-3.12 and enable "Add Python to PATH".
  pause
  exit /b 1
)
where matlab >nul 2>nul
if errorlevel 1 (
  echo.
  echo WARNING: MATLAB was not found in PATH.
  echo The website can open, but diagnosis requires MATLAB.
  echo You can set MATLAB_EXE to your matlab.exe path.
  echo.
)
python -m pip install -r requirements.txt
start "" http://127.0.0.1:5000
python app.py
endlocal
