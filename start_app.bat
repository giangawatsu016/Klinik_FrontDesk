@echo off
set "FLUTTER_BIN=C:\Users\1672\Downloads\Aplikasi\flutter\bin"
set "PATH=%FLUTTER_BIN%;%PATH%"

cd /d "%~dp0"

echo Checking Flutter installation...
call flutter --version
if %ERRORLEVEL% NEQ 0 (
    echo Flutter not found at %FLUTTER_BIN%
    pause
    exit /b
)

echo Initializing Flutter Project...
call flutter create .

echo Adding HTTP dependency...
call flutter pub add http

echo Running App in Chrome...
call flutter run -d chrome
pause
