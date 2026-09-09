$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Write-Host "SIH26038 Web Portal + RETINAL_AI_PROJECT MATLAB Backend"
python -m pip install -r requirements.txt
Start-Process "http://127.0.0.1:5000"
python app.py
