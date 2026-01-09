@echo off
cd /d "%~dp0"
cd ..
echo Starting Klinik Admin Backend...
python -m uvicorn backend.main:app --reload --host 0.0.0.0
pause
