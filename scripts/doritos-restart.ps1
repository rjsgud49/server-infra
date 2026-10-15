# doritos-timeline Next.js (:3013)
param(
    [switch]$StopOnly,
    [string]$Root = 'C:\deploy\doritos-timeline'
)

$ErrorActionPreference = 'Stop'
$node = 'C:\Program Files\nodejs\node.exe'
$logDir = Join-Path $Root 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Stop-Port([int]$Port) {
    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -eq $Port } |
        ForEach-Object {
            Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
        }
}

Stop-Port 3013
Start-Sleep -Seconds 2

if ($StopOnly) {
    Write-Host 'stopped doritos port 3013'
    exit 0
}

$outLog = Join-Path $logDir 'next.out.log'
$errLog = Join-Path $logDir 'next.err.log'
Start-Process -FilePath $node `
    -ArgumentList 'node_modules\next\dist\bin\next','start','-H','127.0.0.1','-p','3013' `
    -WorkingDirectory $Root `
    -WindowStyle Hidden `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog

$web = $false
foreach ($i in 1..20) {
    Start-Sleep -Seconds 1
    try {
        $h = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:3013/login' -TimeoutSec 3
        if ($h.StatusCode -eq 200) { $web = $true; break }
    } catch {}
}
if (-not $web) { throw 'Web check failed on :3013' }

Write-Host 'doritos web :3013 is up'
