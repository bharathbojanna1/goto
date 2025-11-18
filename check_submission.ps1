# Pre-Submission Preparation Script
# Run this before creating your final submission zip

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GoTo Assignment - Pre-Submission Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$errors = @()
$warnings = @()

# 1. Check .git folder exists
Write-Host "[1/8] Checking .git folder..." -ForegroundColor Yellow
if (Test-Path ".git") {
    Write-Host "  ✓ .git folder found" -ForegroundColor Green
} else {
    $errors += ".git folder not found - Git history required!"
}

# 2. Check submission folder and files
Write-Host "[2/8] Checking submission files..." -ForegroundColor Yellow
if (Test-Path "submission/results.csv") {
    Write-Host "  ✓ results.csv found" -ForegroundColor Green
    # Validate CSV structure
    $csv = Import-Csv "submission/results.csv"
    $headers = ($csv | Get-Member -MemberType NoteProperty).Name
    if ($headers -contains "order_id" -and $headers -contains "driver_id") {
        Write-Host "    ✓ Correct columns: order_id, driver_id" -ForegroundColor Green
    } else {
        $errors += "results.csv has wrong columns. Expected: order_id, driver_id"
    }
    if ($csv.Count -eq 0) {
        $errors += "results.csv is empty!"
    } else {
        Write-Host "    ✓ Contains $($csv.Count) predictions" -ForegroundColor Green
    }
} else {
    $errors += "submission/results.csv not found - Run pipeline first!"
}

if (Test-Path "submission/metrics.json") {
    Write-Host "  ✓ metrics.json found" -ForegroundColor Green
    # Validate JSON
    try {
        $metrics = Get-Content "submission/metrics.json" | ConvertFrom-Json
        $metricCount = ($metrics | Get-Member -MemberType NoteProperty).Count
        Write-Host "    ✓ Contains $metricCount metrics" -ForegroundColor Green
    } catch {
        $errors += "metrics.json is not valid JSON!"
    }
} else {
    $errors += "submission/metrics.json not found - Run pipeline first!"
}

# 3. Check for SOLUTION.pdf
Write-Host "[3/8] Checking solution writeup..." -ForegroundColor Yellow
if (Test-Path "SOLUTION.pdf") {
    Write-Host "  ✓ SOLUTION.pdf found" -ForegroundColor Green
} else {
    $warnings += "SOLUTION.pdf not found - Convert SOLUTION.md to PDF (1 page max)"
}

# 4. Check essential code files
Write-Host "[4/8] Checking essential files..." -ForegroundColor Yellow
$requiredFiles = @("Makefile", "config.toml", "requirements.txt")
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file found" -ForegroundColor Green
    } else {
        $errors += "$file not found!"
    }
}

# 5. Check for unwanted files
Write-Host "[5/8] Checking for unwanted files..." -ForegroundColor Yellow
$pycFiles = Get-ChildItem -Recurse -Filter "*.pyc" -ErrorAction SilentlyContinue
$pycacheDir = Get-ChildItem -Recurse -Directory -Filter "__pycache__" -ErrorAction SilentlyContinue

if ($pycFiles.Count -gt 0) {
    $warnings += "Found $($pycFiles.Count) .pyc files - should be cleaned"
}
if ($pycacheDir.Count -gt 0) {
    $warnings += "Found $($pycacheDir.Count) __pycache__ directories - should be cleaned"
}
if ($pycFiles.Count -eq 0 -and $pycacheDir.Count -eq 0) {
    Write-Host "  ✓ No .pyc or __pycache__ files" -ForegroundColor Green
}

# 6. Check git commits
Write-Host "[6/8] Checking git commit history..." -ForegroundColor Yellow
$commitCount = (git rev-list --count HEAD 2>$null)
if ($commitCount -gt 1) {
    Write-Host "  ✓ Found $commitCount commits" -ForegroundColor Green
    Write-Host "`n  Recent commits:" -ForegroundColor Cyan
    git log --oneline -5 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    $errors += "Not enough git commits - need multiple meaningful commits!"
}

# 7. Check model file
Write-Host "`n[7/8] Checking model artifacts..." -ForegroundColor Yellow
if (Test-Path "models/saved_model.pkl") {
    Write-Host "  ✓ Model file found" -ForegroundColor Green
} else {
    $warnings += "models/saved_model.pkl not found - Pipeline may not have completed"
}

# 8. Calculate directory size
Write-Host "[8/8] Calculating submission size..." -ForegroundColor Yellow
$size = (Get-ChildItem -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "  Total size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
if ($size -gt 100) {
    $warnings += "Submission size > 100MB - may be including large data files unnecessarily"
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`n✓ ALL CHECKS PASSED!" -ForegroundColor Green
    Write-Host "`nReady to create submission zip!`n" -ForegroundColor Green
} else {
    if ($errors.Count -gt 0) {
        Write-Host "`n❌ ERRORS FOUND ($($errors.Count)):" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    }
    if ($warnings.Count -gt 0) {
        Write-Host "`n⚠ WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
    }
    Write-Host "`nFix errors before submission!`n" -ForegroundColor Yellow
}

Write-Host "========================================`n" -ForegroundColor Cyan
