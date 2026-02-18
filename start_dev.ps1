# start_dev.ps1
# Automates starting both backend and frontend in background.
# Logs are saved to backend.log and frontend.log in the project root.

$ProjectRoot = Get-Location
$FlutterPath = "C:\flutter-sdk\bin\flutter.bat"

# 1. Start Frappe Backend
$BackendJob = Get-Job -Name "KlinikBackend" -ErrorAction SilentlyContinue
if ($BackendJob) {
    Stop-Job -Name "KlinikBackend"
    Remove-Job -Name "KlinikBackend"
}

Write-Host "Starting Backend (Frappe/Bench)..." -ForegroundColor Cyan
Start-Job -Name "KlinikBackend" -ScriptBlock {
    param($root)
    # Using WSL to run bench
    try {
        wsl.exe -d Ubuntu-22.04 -u frappe -- bash -c "cd /home/frappe/frappe-bench && bench start" > "$root\backend.log" 2>&1
    }
    catch {
        $_ | Out-File "$root\backend.log" -Append
    }
} -ArgumentList $ProjectRoot

# 2. Start Flutter Frontend
$FrontendJob = Get-Job -Name "KlinikFrontend" -ErrorAction SilentlyContinue
if ($FrontendJob) {
    Stop-Job -Name "KlinikFrontend"
    Remove-Job -Name "KlinikFrontend"
}

Write-Host "Starting Frontend (Flutter)..." -ForegroundColor Cyan
Start-Job -Name "KlinikFrontend" -ScriptBlock {
    param($root, $flutter)
    Set-Location -Path "$root\app"
    try {
        & $flutter run -d chrome --web-renderer html --no-web-resources-cdn > "$root\frontend.log" 2>&1
    }
    catch {
        $_ | Out-File "$root\frontend.log" -Append
    }
} -ArgumentList $ProjectRoot, $FlutterPath

Write-Host "`nEnvironment is starting in background jobs." -ForegroundColor Green
Write-Host "Logs: backend.log, frontend.log" -ForegroundColor Gray
Write-Host "Check status: Get-Job"
Write-Host "Stop all:     Get-Job | Stop-Job"
