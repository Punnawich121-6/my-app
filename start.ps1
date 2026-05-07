$BASE = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Zest & Savory - Food Delivery App  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Free port 3000
$conn = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($conn) {
    Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
}

# Start Backend
Write-Host "Starting Backend on http://localhost:3000 ..."
$logOut = "$BASE\backend.log"
$logErr = "$BASE\backend.err.log"
$backend = Start-Process -FilePath "node" `
    -ArgumentList "server.js" `
    -WorkingDirectory "$BASE\backend" `
    -RedirectStandardOutput $logOut `
    -RedirectStandardError $logErr `
    -NoNewWindow -PassThru

Start-Sleep -Seconds 2

$ok = $false
try {
    Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 3 | Out-Null
    $ok = $true
} catch {
    $ok = $false
}

if ($ok) {
    Write-Host "  OK - Backend running (PID $($backend.Id))" -ForegroundColor Green
} else {
    Write-Host "  FAILED - check backend.log" -ForegroundColor Red
    Get-Content $logOut -ErrorAction SilentlyContinue
    Get-Content $logErr -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ""
Write-Host "Select app to run:"
Write-Host "  1) Merchant App  -> http://localhost:8080"
Write-Host "  2) Customer App  -> http://localhost:8081"
Write-Host "  3) Rider App     -> http://localhost:8082"
Write-Host "  4) All Apps"
Write-Host ""
$choice = Read-Host "Choose [1]"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

function Start-Flutter {
    param($dir, $port)
    return Start-Process -FilePath "flutter" `
        -ArgumentList "run", "-d", "chrome", "--web-renderer", "html", "--web-port", "$port" `
        -WorkingDirectory $dir `
        -NoNewWindow -PassThru
}

switch ($choice) {
    "1" {
        Write-Host "`nMerchant App -> http://localhost:8080" -ForegroundColor Cyan
        $p = Start-Flutter "$BASE\merchantapp" 8080
        $p.WaitForExit()
    }
    "2" {
        Write-Host "`nCustomer App -> http://localhost:8081" -ForegroundColor Cyan
        $p = Start-Flutter "$BASE\customerapp" 8081
        $p.WaitForExit()
    }
    "3" {
        Write-Host "`nRider App -> http://localhost:8082" -ForegroundColor Cyan
        $p = Start-Flutter "$BASE\riderapp" 8082
        $p.WaitForExit()
    }
    "4" {
        Write-Host "`nStarting all apps..." -ForegroundColor Cyan
        $p1 = Start-Flutter "$BASE\merchantapp" 8080
        Start-Sleep 5
        $p2 = Start-Flutter "$BASE\customerapp" 8081
        Start-Sleep 5
        $p3 = Start-Flutter "$BASE\riderapp" 8082
        Write-Host ""
        Write-Host "All services running:" -ForegroundColor Green
        Write-Host "  Backend:      http://localhost:3000"
        Write-Host "  Merchant App: http://localhost:8080"
        Write-Host "  Customer App: http://localhost:8081"
        Write-Host "  Rider App:    http://localhost:8082"
        Write-Host "Press Ctrl+C to stop all."
        try { $p1.WaitForExit(); $p2.WaitForExit(); $p3.WaitForExit() }
        finally { $p1, $p2, $p3 | ForEach-Object { if (-not $_.HasExited) { $_.Kill() } } }
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
    }
}

if (-not $backend.HasExited) { $backend.Kill() }
