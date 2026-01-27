@echo off
set "PATH=C:\Users\1672\Downloads\Aplikasi\flutter\bin;%PATH%"
cd /d "%~dp0"

echo Running flutter pub upgrade --major-versions...
call flutter pub upgrade --major-versions

echo Running flutter pub get...
call flutter pub get

pause
