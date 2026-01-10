# start.ps1

# 1. Define paths
$BackendPath = Join-Path $PSScriptRoot "backend"
$FrontendPath = Join-Path $PSScriptRoot "frontend"

Write-Host "🚀 Starting Backend (FastAPI)..." -ForegroundColor Green
# Start uvicorn in a new window/process. 
$BackendProcess = Start-Process -FilePath "$BackendPath\.venv\Scripts\python.exe" `
    -ArgumentList "-m uvicorn run:app --reload --port 8000" `
    -WorkingDirectory $BackendPath `
    -PassThru `
    -NoNewWindow

Write-Host "⚛️ Starting Frontend (Vite)..." -ForegroundColor Cyan
# Start npm in a new process
$FrontendProcess = Start-Process -FilePath "npm.cmd" `
    -ArgumentList "run dev" `
    -WorkingDirectory $FrontendPath `
    -PassThru `
    -NoNewWindow

Write-Host "✅ Both services running. Press Ctrl+C to stop." -ForegroundColor Yellow

try {
    # Keep script running to listen for Ctrl+C
    while ($true) {
        Start-Sleep -Seconds 1
        
        # Optional: Check if processes died unexpectedly
        if ($BackendProcess.HasExited -or $FrontendProcess.HasExited) {
            Write-Warning "One of the services stopped unexpectedly."
            break
        }
    }
}
finally {
    # This block runs when you hit Ctrl+C or the script exits
    Write-Host "`n🛑 Stopping services..." -ForegroundColor Red
    
    if (-not $BackendProcess.HasExited) { Stop-Process -Id $BackendProcess.Id -Force }
    if (-not $FrontendProcess.HasExited) { Stop-Process -Id $FrontendProcess.Id -Force }
    
    Write-Host "Services stopped."
}
