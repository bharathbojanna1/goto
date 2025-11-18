# Create Submission Zip
# Run this after all checks pass

param(
    [string]$OutputName = "goto_assignment_bharath_bojanna.zip"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Creating Submission Package" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Clean unwanted files
Write-Host "[1/4] Cleaning unwanted files..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Filter "*.pyc" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -Recurse -Directory -Filter "__pycache__" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
Write-Host "  ✓ Cleaned .pyc and __pycache__ files`n" -ForegroundColor Green

# Step 2: Create list of files to include
Write-Host "[2/4] Preparing file list..." -ForegroundColor Yellow
$excludePatterns = @(
    "*.zip",
    "*.pyc",
    "__pycache__",
    "*.log",
    ".DS_Store",
    "Thumbs.db"
)

Write-Host "  Files to include:" -ForegroundColor Cyan
Write-Host "    - All source code (.py, .toml, .yaml)" -ForegroundColor Gray
Write-Host "    - .git folder (commit history)" -ForegroundColor Gray
Write-Host "    - submission/ folder (results.csv, metrics.json)" -ForegroundColor Gray
Write-Host "    - Documentation (if SOLUTION.pdf exists)" -ForegroundColor Gray
Write-Host "    - Makefile, requirements.txt, config files`n" -ForegroundColor Gray

# Step 3: Create the zip
Write-Host "[3/4] Creating zip archive..." -ForegroundColor Yellow

# Move to parent directory
$currentDir = Get-Location
$parentDir = Split-Path -Parent $currentDir
$folderName = Split-Path -Leaf $currentDir

Set-Location $parentDir

# Use Compress-Archive (PowerShell 5.0+)
$zipPath = Join-Path $parentDir $OutputName

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Create zip including hidden .git folder
Compress-Archive -Path "$folderName\*" -DestinationPath $zipPath -Force

# Also explicitly add .git folder
$gitPath = Join-Path $folderName ".git"
if (Test-Path $gitPath) {
    # PowerShell's Compress-Archive doesn't handle hidden folders well
    # Need to use 7-Zip or similar, or warn user
    Write-Host "  ⚠ Note: PowerShell may not include hidden .git folder properly" -ForegroundColor Yellow
    Write-Host "    Please verify .git folder is in zip, or use 7-Zip/WinRAR" -ForegroundColor Yellow
}

Set-Location $currentDir

if (Test-Path $zipPath) {
    Write-Host "  ✓ Created: $zipPath`n" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to create zip!`n" -ForegroundColor Red
    exit 1
}

# Step 4: Verify zip contents
Write-Host "[4/4] Verifying zip contents..." -ForegroundColor Yellow

# Note: PowerShell can't easily list zip contents without extracting
# Recommend manual verification
Write-Host "  ⚠ Please manually verify zip contains:" -ForegroundColor Yellow
Write-Host "    □ .git/ folder" -ForegroundColor Gray
Write-Host "    □ submission/results.csv" -ForegroundColor Gray
Write-Host "    □ submission/metrics.json" -ForegroundColor Gray
Write-Host "    □ SOLUTION.pdf (if created)" -ForegroundColor Gray
Write-Host "    □ All .py files" -ForegroundColor Gray
Write-Host "    □ Makefile, config.toml, requirements.txt`n" -ForegroundColor Gray

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Zip created successfully!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Output: $zipPath`n" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Extract zip to a new folder to test" -ForegroundColor Gray
Write-Host "  2. Verify .git folder is included" -ForegroundColor Gray
Write-Host "  3. Run 'make run' in extracted folder" -ForegroundColor Gray
Write-Host "  4. Submit via specified channel`n" -ForegroundColor Gray

Write-Host "⚠ IMPORTANT: Use 7-Zip or WinRAR to ensure .git folder is included!" -ForegroundColor Yellow
Write-Host "   Right-click project folder → 7-Zip → Add to archive...`n" -ForegroundColor Yellow
