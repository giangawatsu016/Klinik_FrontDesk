@echo off
set "PATH=C:\Users\1672\Downloads\Aplikasi\flutter\bin;%PATH%"
cd /d "%~dp0"

echo Running flutter create...
call flutter create .

echo Adding http dependency...
call flutter pub add http

echo Setup complete.
