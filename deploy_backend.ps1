$ErrorActionPreference = "Stop"

$repoUrl = "https://gitlab.com/frappe-klinik/api-clinic.git"
$branch = "develop"
$targetPath = "api_clinic/clinicfrontdesk"
$sourceDir = "backend"
$tempCloneDir = "temp_backend_clone"

Write-Host "Deploying Backend to $repoUrl (Branch: $branch, Path: $targetPath)..."

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

# 3. Prepare Target Directory
$fullDestPath = Join-Path $tempCloneDir $targetPath
if (-not (Test-Path $fullDestPath)) {
    Write-Host "Creating target directory: $fullDestPath"
    New-Item -ItemType Directory -Path $fullDestPath -Force
}

# 4. Copy Backend Files
# We need to copy `backend/*` contents into `$fullDestPath`
# Be careful not to wipe other things in api_clinic if they exist, but overwrite matches.
Write-Host "Copying backend files to repo..."
Copy-Item -Path "$sourceDir\*" -Destination $fullDestPath -Recurse -Force

# 5. Git Operations
Push-Location $tempCloneDir

try {
    git add .
    
    # Check if there are changes
    $status = git status --porcelain
    if ($status) {
        git commit -m "Update Backend V3.0 (Remove SuperAdmin, Strict Roles)"
        
        Write-Host "Pushing to $branch..."
        git push origin $branch
        Write-Host "Backend Deployment Success!"
    } else {
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
