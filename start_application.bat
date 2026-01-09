@echo off
cd /d "%~dp0"

echo ==========================================
echo   Starting Klinik Admin Application
echo ==========================================

echo [1/2] Launching Backend Server...
start "Klinik Backend Server" cmd /k "backend\start_server.bat"

echo Waiting for backend to initialize (5 seconds)...
timeout /t 5 /nobreak >nul

echo [2/2] Launching Frontend Application...
cd frontend
call run.bat
