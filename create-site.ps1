# create-site.ps1
Write-Host "=== WP Instant: Create Site ===" -ForegroundColor Cyan

# --------------------------------------------------
# Pre-flight checks
# --------------------------------------------------

# Check if Docker is running
try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker is not running. Please start Docker Desktop."
        exit 1
    }
}
catch {
    Write-Error "Docker is not installed or not running."
    exit 1
}

# Check Docker Compose version
try {
    docker compose version 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker Compose is not available."
        exit 1
    }
}
catch {
    Write-Error "Docker Compose is not installed."
    exit 1
}

# --------------------------------------------------
# Step 1: Generate .env
# --------------------------------------------------
if (-Not (Test-Path ".env")) {
    Write-Host "`nGenerating .env..." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -File .\gen-env.ps1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to generate .env"
        exit 1
    }
}
else {
    Write-Host "`n.env already exists, skipping gen-env" -ForegroundColor Gray
}

# Load .env to get WP_PORT
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# --------------------------------------------------
# Step 2: Docker Compose Up
# --------------------------------------------------
Write-Host "`nStarting Docker containers..." -ForegroundColor Yellow
docker compose up -d --build

if ($LASTEXITCODE -ne 0) {
    Write-Error "docker compose up failed"
    exit 1
}

# --------------------------------------------------
# Step 3: Find Git Bash
# --------------------------------------------------
$gitBashPaths = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
)

$gitBash = $null
foreach ($path in $gitBashPaths) {
    if (Test-Path $path) {
        $gitBash = $path
        break
    }
}

if (-Not $gitBash) {
    Write-Error "Git Bash not found. Please install Git for Windows from https://git-scm.com/"
    Write-Host "Searched paths:" -ForegroundColor Yellow
    $gitBashPaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    exit 1
}

Write-Host "`nFound Git Bash: $gitBash" -ForegroundColor Green

# --------------------------------------------------
# Step 4: Init WordPress (Git Bash - SAFE)
# --------------------------------------------------
Write-Host "`nInitializing WordPress..." -ForegroundColor Yellow

# Change to project directory and run init.sh
$scriptPath = "scripts/init.sh"
$bashCommand = "cd '$($PWD.Path -replace '\\', '/')' && export MSYS_NO_PATHCONV=1 && export MSYS2_ARG_CONV_EXCL='*' && bash $scriptPath"

try {
    & $gitBash -c $bashCommand
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "init.sh failed with exit code $LASTEXITCODE"
        Write-Host "Check logs with: docker compose logs" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Error "Failed to run init.sh: $_"
    exit 1
}

# --------------------------------------------------
# Success!
# --------------------------------------------------
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "[OK] WordPress site is ready!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Site URL: http://localhost:$($envVars['WP_PORT'])" -ForegroundColor Cyan
Write-Host "Dashboard URL: http://localhost:$($envVars['WP_PORT'])/wp-admin" -ForegroundColor Cyan
Write-Host "phpMyAdmin URL: http://localhost:8082" -ForegroundColor Cyan
Write-Host ""
Write-Host "Admin User: $($envVars['ADMIN_USER'])" -ForegroundColor Cyan
Write-Host "Admin Pass: $($envVars['ADMIN_PASS'])" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database Info:" -ForegroundColor Yellow
Write-Host "  DB Name: $($envVars['DB_NAME'])" -ForegroundColor Gray
Write-Host "  DB User: $($envVars['DB_USER'])" -ForegroundColor Gray
Write-Host "  DB Pass: $($envVars['DB_PASS'])" -ForegroundColor Gray
Write-Host "  Root Pass: root" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  docker compose logs -f    # View logs" -ForegroundColor Gray
Write-Host "  docker compose down       # Stop containers" -ForegroundColor Gray
Write-Host "  docker compose restart    # Restart containers" -ForegroundColor Gray
Write-Host ""
