# ── Setup Local Python venv & Jupyter Kernel ──────────────────────────────────
# Run from the repository root:  .\local\setup_kernel.ps1
# Re-running is safe — it skips the venv creation if .venv already exists.

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot   # assumes script lives in local/

Write-Host "=============================================="
Write-Host " Setup GPU Server - Local Kernel Setup"
Write-Host "=============================================="

# 1. Create venv if it doesn't exist
$VenvDir = Join-Path $RepoRoot ".venv"
if (Test-Path $VenvDir) {
    Write-Host "[OK] Virtual environment already exists at $VenvDir"
} else {
    Write-Host "[..] Creating virtual environment at $VenvDir ..."
    python -m venv $VenvDir
    Write-Host "[OK] Virtual environment created."
}

# 2. Install / upgrade dependencies
$Pip = Join-Path $VenvDir "Scripts\pip.exe"
Write-Host "[..] Installing dependencies ..."
& $Pip install --upgrade pip | Out-Null
& $Pip install ipykernel requests
Write-Host "[OK] Dependencies installed."

# 3. Register the Jupyter kernel
$Python = Join-Path $VenvDir "Scripts\python.exe"
Write-Host "[..] Registering Jupyter kernel 'trellis' ..."
& $Python -m ipykernel install --user --name trellis --display-name "Trellis"
Write-Host "[OK] Kernel 'trellis' registered."

Write-Host ""
Write-Host "Done! Open a notebook and select the 'Trellis' kernel."
