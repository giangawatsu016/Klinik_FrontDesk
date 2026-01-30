$ErrorActionPreference = "Stop"

$repoUrl = "https://gitlab.com/frappe-klinik/app-clinic-frontdesk.git"
$localDir = "frontend"
$tempDir = "temp_git_frontend"

Write-Host "Deploying Frontend to $repoUrl..."

# 1. Prepare temp git dir
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir

# 2. Copy source files to temp dir (excluding .git and build artifacts if any)
Write-Host "Copying files..."
Copy-Item -Path "$localDir\*" -Destination $tempDir -Recurse

# 3. Git Operations
Push-Location $tempDir

try {
    Write-Host "Initializing Git..."
    git init -b main
    git remote add origin $repoUrl
    
    Write-Host "Fetching remote history..."
    git fetch origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Remote history found. Syncing history..."
        # 1. Point HEAD to remote main, but keep Working Directory (V3.0 files)
        git reset --soft origin/main
    }
    else {
        Write-Host "No remote history found (or fetch failed). Proceeding as new repo."
        $global:LASTEXITCODE = 0
    }

    Write-Host "Staging files..."
    git add .
    
    # Check if there are changes to commit
    $status = git status --porcelain
    if ($status) {
        git commit -m "Update Frontend V3.0 (Strict Role & Sync Cleanup)"
        
        Write-Host "Pushing to main..."
        git push -u origin main
        
        Write-Host "Frontend Deployment Success!"
    }
    else {
        Write-Host "No changes detected (Repo is already up to date)."
    }
}
catch {
    Write-Host "Error during deployment: $_"
    exit 1
}
finally {
    Pop-Location
    # Cleanup temp dir? Maybe keep for inspection if failed.
    # Remove-Item -Path $tempDir -Recurse -Force
}
