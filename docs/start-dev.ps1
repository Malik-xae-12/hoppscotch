# Determine Repository Root (supports running from repo root or docs folder)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path (Join-Path $ScriptDir "..\package.json")) {
    $RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
} else {
    $RepoRoot = (Resolve-Path ".").Path
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Starting Hoppscotch Local Services     " -ForegroundColor Cyan
Write-Host "   Working Directory: $RepoRoot           " -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Start Database Container
Write-Host "`n[1/3] Starting PostgreSQL container (port 5433)..." -ForegroundColor Yellow
Set-Location $RepoRoot
docker compose up hoppscotch-db -d

# Wait briefly for database healthcheck
Start-Sleep -Seconds 2

# 2. Launch Backend in a new terminal window
Write-Host "[2/3] Launching Hoppscotch Backend on http://localhost:3170..." -ForegroundColor Yellow
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "Set-Location '$RepoRoot'; pnpm --filter hoppscotch-backend start:dev"

# 3. Launch Web App Frontend in a new terminal window
Write-Host "[3/3] Launching Hoppscotch Web App on http://localhost:3000..." -ForegroundColor Yellow
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "Set-Location '$RepoRoot'; pnpm --filter @hoppscotch/selfhost-web dev"

Write-Host "`nAll services have been launched!" -ForegroundColor Green
Write-Host "  - Web App:      http://localhost:3000" -ForegroundColor Green
Write-Host "  - Backend API:  http://localhost:3170" -ForegroundColor Green
Write-Host "  - GraphQL API:  http://localhost:3170/graphql" -ForegroundColor Green
Write-Host "  - PostgreSQL:   localhost:5433" -ForegroundColor Green
