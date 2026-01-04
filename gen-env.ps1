# Kiểm tra .env.example có tồn tại không
if (-Not (Test-Path ".env.example")) {
    Write-Error ".env.example not found. Please create it first."
    exit 1
}

# Kiểm tra quyền ghi file
try {
    $testFile = ".env.test"
    "test" | Set-Content $testFile -ErrorAction Stop
    Remove-Item $testFile -ErrorAction SilentlyContinue
}
catch {
    Write-Error "Cannot write to current directory. Check permissions."
    exit 1
}

$envExample = Get-Content ".env.example"

# Lấy tên folder hiện tại làm DB_NAME
$projectName = Split-Path (Get-Location) -Leaf

# Chuẩn hoá DB_NAME (mysql-safe)
$dbName = $projectName.ToLower() -replace '[^a-z0-9_]', '_'

# Validate DB_NAME không rỗng
if ([string]::IsNullOrWhiteSpace($dbName)) {
    Write-Error "Invalid project name for DB_NAME"
    exit 1
}

# Sinh DB_USER và DB_PASS ngẫu nhiên
$dbUser = -join ((97..122) | Get-Random -Count 10 | ForEach-Object { [char]$_ })
$dbPass = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })

# Replace các biến trong .env.example
$env = $envExample `
    -replace "^DB_NAME=.*$", "DB_NAME=$dbName" `
    -replace "^DB_USER=.*$", "DB_USER=$dbUser" `
    -replace "^DB_PASS=.*$", "DB_PASS=$dbPass"

# Ghi ra file .env
try {
    $env | Set-Content ".env" -ErrorAction Stop
    Write-Host ".env created successfully:" -ForegroundColor Green
    Write-Host "DB_NAME=$dbName" -ForegroundColor Cyan
    Write-Host "DB_USER=$dbUser" -ForegroundColor Cyan
    Write-Host "DB_PASS=$dbPass" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to write .env file: $_"
    exit 1
}