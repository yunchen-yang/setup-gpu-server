param (
    [Parameter(Mandatory=$false)]
    [string]$ServerAddress,
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$RemoteDirectory = "~/gpu_server"
)

# Prompt for missing credentials
if ([string]::IsNullOrWhiteSpace($ServerAddress)) {
    $ServerAddress = Read-Host "Enter Server Address (e.g. 192.168.1.100)"
}

if ([string]::IsNullOrWhiteSpace($Username)) {
    $Username = Read-Host "Enter Server Username (e.g. ubuntu)"
}

$ConnectionString = "$Username@$ServerAddress"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " Setup GPU Server - Remote Deploy & Test      " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Deploying to: $ConnectionString"
Write-Host "Remote Dir:   $RemoteDirectory"
Write-Host ""

# 1. Determine local server directory path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LocalServerDir = Join-Path -Path (Split-Path -Parent $ScriptDir) -ChildPath "server"

if (-Not (Test-Path $LocalServerDir)) {
    Write-Host "ERROR: Local server directory not found at: $LocalServerDir" -ForegroundColor Red
    Exit 1
}

# 2. Make sure remote directory exists
Write-Host "[1/4] Ensuring remote directory exists..." -ForegroundColor Yellow
ssh $ConnectionString "mkdir -p $RemoteDirectory"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to connect or create directory via SSH." -ForegroundColor Red
    Exit 1
}

# 3. Secure Copy (scp) the server files
Write-Host "[2/4] Copying server files to remote host..." -ForegroundColor Yellow
$ScpSource = "$LocalServerDir\*"
scp -r $ScpSource "${ConnectionString}:${RemoteDirectory}/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to copy files via SCP." -ForegroundColor Red
    Exit 1
}

# 4. Run `make setup` and QA scripts on the remote host
Write-Host "[3/4] Running setup and QA tests on remote host..." -ForegroundColor Yellow
$RemoteCommands = @"
    cd $RemoteDirectory
    echo '--- Running make setup ---'
    make setup
    
    if [ $? -eq 0 ]; then
        echo '--- Running QA Setup Tests ---'
        .venv/bin/python qa_setup.py
        
        echo '--- Running QA Inference Tests ---'
        .venv/bin/python qa_inference.py
    else
        echo 'Make setup failed, skipping QA tests'
        exit 1
    fi
"@

ssh $ConnectionString $RemoteCommands
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "QA Tests or Setup encountered an issue on the server. Please check the logs above." -ForegroundColor Red
    Exit 1
}

Write-Host ""
Write-Host "[4/4] Deployment and QA tests completed successfully!" -ForegroundColor Green
Write-Host "To start the API, you can SSH into the server and run:"
Write-Host "  cd $RemoteDirectory && make start"
Write-Host ""
