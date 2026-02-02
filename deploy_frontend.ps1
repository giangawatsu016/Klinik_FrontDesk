$ErrorActionPreference = "Stop"

$repoUrl = "https://gitlab.com/frappe-klinik/app-clinic-frontdesk.git"
$branch = "main"  # Remote 'develop' not found, defaulting to 'main'
$sourceDir = "frontend"
$tempCloneDir = "temp_frontend_clone"

Write-Host "Deploying Frontend to $repoUrl (Branch: $branch)..."

# 1. Clean previous clone
if (Test-Path $tempCloneDir) {
    Write-Host "Cleaning previous clone..."
    Remove-Item -Path $tempCloneDir -Recurse -Force
}

# 2. Clone Repository
Write-Host "Cloning repository..."
git clone -b $branch $repoUrl $tempCloneDir

if (-not (Test-Path $tempCloneDir)) {
    Write-Error "Clone failed."
    exit 1
}

# 3. Copy Frontend Files
# Copy all content from local 'frontend' to root of cloned repo
Write-Host "Copying frontend files to repo..."
# Exclude .git folder to prevent overwriting the cloned repo's git config
Get-ChildItem -Path $sourceDir -Exclude ".git" | Copy-Item -Destination $tempCloneDir -Recurse -Force

# 4. Git Operations
Push-Location $tempCloneDir

try {
    git add .
    
    # Check if there are changes
    $status = git status --porcelain
    if ($status) {
        git commit -m "Update Frontend V3.0 (Fix Login Web & Dependencies)"
        
        Write-Host "Pushing to $branch..."
        git push origin $branch
        Write-Host "Frontend Deployment Success!"
    }
    else {
        Write-Host "No changes to deploy."
    }
}
catch {
    Write-Host "Error during git operations: $_"
    exit 1
}
finally {
    Pop-Location
    # Remove-Item -Path $tempCloneDir -Recurse -Force
}
