@echo off
set "PATH=C:\Users\1672\Downloads\Aplikasi\flutter\bin;%PATH%"
cd /d "%~dp0"

echo Launching App...
call flutter run -d chrome
pause
