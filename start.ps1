$BASE = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Zest & Savory - Starting All Apps  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Free port 3000
$conn = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($conn) {
    Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
}

# 1) Backend
Write-Host "[1/5] Starting Backend..." -ForegroundColor Yellow
Start-Process "powershell" -ArgumentList "-NoExit", "-Command", `
    "cd '$BASE\backend'; Write-Host 'BACKEND' -ForegroundColor Cyan; node server.js"

Start-Sleep -Seconds 3

# 2) Web Admin (Next.js)
Write-Host "[2/5] Starting Web Admin (Next.js)..." -ForegroundColor Yellow
Start-Process "powershell" -ArgumentList "-NoExit", "-Command", `
    "cd '$BASE\myweb\my-project'; Write-Host 'WEB ADMIN' -ForegroundColor Magenta; pnpm run dev"

Start-Sleep -Seconds 2

# 3) Merchant App
Write-Host "[3/5] Starting Merchant App..." -ForegroundColor Yellow
Start-Process "powershell" -ArgumentList "-NoExit", "-Command", `
    "cd '$BASE\merchantapp'; Write-Host 'MERCHANT APP' -ForegroundColor Green; flutter run -d chrome --web-port 8080"

Start-Sleep -Seconds 5

# 4) Customer App
Write-Host "[4/5] Starting Customer App..." -ForegroundColor Yellow
Start-Process "powershell" -ArgumentList "-NoExit", "-Command", `
    "cd '$BASE\customerapp'; Write-Host 'CUSTOMER APP' -ForegroundColor Green; flutter run -d chrome --web-port 8081"

Start-Sleep -Seconds 5

# 5) Rider App
Write-Host "[5/5] Starting Rider App..." -ForegroundColor Yellow
Start-Process "powershell" -ArgumentList "-NoExit", "-Command", `
    "cd '$BASE\riderapp'; Write-Host 'RIDER APP' -ForegroundColor Green; flutter run -d chrome --web-port 8082"

Write-Host ""
Write-Host "All services started:" -ForegroundColor Green
Write-Host "  Backend:      http://localhost:3000"
Write-Host "  Web Admin:    http://localhost:3001"
Write-Host "  Merchant App: http://localhost:8080"
Write-Host "  Customer App: http://localhost:8081"
Write-Host "  Rider App:    http://localhost:8082"
Write-Host ""
Write-Host "ปิด terminal แต่ละหน้าต่างเพื่อหยุด app นั้น" -ForegroundColor Gray
