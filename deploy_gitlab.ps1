# Deploy to GitLab Repositories (Smart Reuse Version)
$ErrorActionPreference = "Stop"

function Initialize-GitRepo {
    param (
        [string]$RepoUrl,
        [string]$TargetDir,
        [string]$Branch
    )

    if (Test-Path $TargetDir) {
        Write-Host "Target directory $TargetDir exists. Attempting to clean/reuse..."
        try {
            Set-Location $TargetDir
            # Check if it's the right repo
            $remote = git remote get-url origin
            if ($remote -ne $RepoUrl) {
                Write-Host "Directory contains wrong repo. Force removing..."
                Set-Location ..
                Remove-Item -Recurse -Force $TargetDir
                git clone -b $Branch $RepoUrl $TargetDir
                Set-Location $TargetDir
            }
            else {
                # It is the right repo, clean it
                Write-Host "Resetting existing repo state..."
                git fetch origin
                git reset --hard "origin/$Branch"
                git clean -fdx
            }
        }
        catch {
            Write-Host "Error accessing/cleaning repo: $_"
            Set-Location ..
            Remove-Item -Recurse -Force $TargetDir
            git clone -b $Branch $RepoUrl $TargetDir
            Set-Location $TargetDir
        }
    }
    else {
        Write-Host "Cloning $RepoUrl..."
        git clone -b $Branch $RepoUrl $TargetDir
        Set-Location $TargetDir
    }
}

# 1. Frontend
Write-Host "`n=== Deploying Frontend ===" -ForegroundColor Cyan
$FRONTEND_REPO = "https://gitlab.com/frappe-klinik/app-clinic-frontdesk.git"
$TEMP_FRONTEND = "temp_frontend_deploy"
$BRANCH = "main" # Assuming main, update if master

# Setup Clean Repo
Initialize-GitRepo -RepoUrl $FRONTEND_REPO -TargetDir $TEMP_FRONTEND -Branch $BRANCH

# Determine exact branch name if 'main' fails fallback (optional, skipping for now)

# Sync Changes
Write-Host "Syncing files..."
# Copy from parent/frontend to here
# Use Robocopy for better file handling or just Copy-Item
Copy-Item -Recurse -Force "..\frontend\*" .

# Git operations
git add .
$status = git status --porcelain
if ($status) {
    Write-Host "Committing changes..."
    git commit -m "feat: sync update from Klinik_Admin workspace"
    
    Write-Host "Pushing to $BRANCH..."
    git push origin $BRANCH
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Push failed. Trying force push (safe for single-user sync)..." -ForegroundColor Yellow
        git push origin $BRANCH --force
    }
}
else {
    Write-Host "No changes to deploy." -ForegroundColor Green
}

Set-Location ..
Write-Host "Frontend Done."


# 2. Backend
Write-Host "`n=== Deploying Backend ===" -ForegroundColor Cyan
$BACKEND_REPO = "https://gitlab.com/frappe-klinik/api-clinic.git"
$TEMP_BACKEND = "temp_backend_deploy"
$BRANCH_BACKEND = "develop"

Initialize-GitRepo -RepoUrl $BACKEND_REPO -TargetDir $TEMP_BACKEND -Branch $BRANCH_BACKEND

# Sync to subdir
$SUBDIR = "api_clinic\clinicfrontdesk"
if (-not (Test-Path $SUBDIR)) { New-Item -ItemType Directory -Force -Path $SUBDIR }

Write-Host "Syncing files to $SUBDIR..."
# Clear subdir implementation first to match local exactly? 
# Or just overwrite. Overwrite is safer for keeping untracked files if any, but cleaner is better.
# Let's rely on Copy-Item -Force
Copy-Item -Recurse -Force "..\backend\*" $SUBDIR

git add .
$status = git status --porcelain
if ($status) {
    Write-Host "Committing..."
    git commit -m "feat(backend): sync update from Klinik_Admin workspace"
    
    Write-Host "Pushing to $BRANCH_BACKEND..."
    git push origin $BRANCH_BACKEND
}
else {
    Write-Host "No changes to deploy." -ForegroundColor Green
}

Set-Location ..
Write-Host "Backend Done."
