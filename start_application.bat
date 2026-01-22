@echo off
cd /d "%~dp0"

echo ==========================================
echo   Starting Klinik Admin Application
echo ==========================================

echo [1/3] Checking and Launching Kafka...
if exist "C:\kafka\bin\windows\kafka-server-start.bat" (
    echo    Found Kafka in C:\kafka. Starting service...
    start "Klinik Kafka Server" cmd /k "cd /d C:\kafka && bin\windows\kafka-server-start.bat config\server.properties"
    echo    Waiting for Kafka to warm up [8 seconds]...
    timeout /t 8 /nobreak >nul
) else (
    echo    [INFO] Kafka not found in C:\kafka. 
    echo    Skipping Kafka auto-start. Please run it manually if needed.
)

echo [2/3] Launching Backend Server...
start "Klinik Backend Server" cmd /k "backend\start_server.bat"

echo Waiting for backend to initialize (5 seconds)...
timeout /t 5 /nobreak >nul

echo [2/2] Launching Frontend Application...
cd frontend
call run.bat
