<# :
@echo off
setlocal
echo Dang khoi dong trinh cap nhat...
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:SCRIPT_DIR='%SCRIPT_DIR%'; Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))" %*
exit /b %errorlevel%
#>

$ErrorActionPreference = "Stop"
Write-Host "--- TRINH CAP NHAT VS CODE PORTABLE ---" -ForegroundColor Cyan

$scriptDir = $env:SCRIPT_DIR.TrimEnd('\')
$currentDir = $scriptDir

# 1. Doc version.txt
$versionPaths = @(
    Join-Path $scriptDir "version.txt",
    Join-Path $scriptDir "..\version.txt"
)

$currentVersion = "Khong xac dinh"
foreach ($p in $versionPaths) {
    if (Test-Path $p) {
        $currentVersion = (Get-Content -Path $p | Select-Object -First 1).Trim()
        $currentDir = Split-Path $p # Dat thu muc goc theo vi tri cua version.txt
        break
    }
}

Write-Host "Phien ban hien tai: $currentVersion" -ForegroundColor Yellow

# 2. Lay phien ban moi nhat tu GitHub
$apiUrl = "https://api.github.com/repos/hoangxg4/vscode-portable/releases/latest"
$releaseInfo = Invoke-RestMethod -Uri $apiUrl
$latestTag = $releaseInfo.tag_name
$latestVersion = $latestTag -replace "^v", ""
$arch = if ($env:PROCESSOR_ARCHITECTURE -match "ARM") { "arm64" } else { "x64" }
$fileName = "VSCode-Portable-windows-$arch-$latestVersion.zip"
$downloadUrl = "https://github.com/hoangxg4/vscode-portable/releases/download/$latestTag/$fileName"

Write-Host "Phien ban moi nhat : $latestVersion" -ForegroundColor Green

if ($currentVersion -eq $latestVersion) {
    Write-Host "=> Ban dang su dung ban moi nhat!" -ForegroundColor Cyan
}

$choice = Read-Host "Ban co muon tiep tuc cap nhat / cai lai khong? (Y/N)"
if ($choice -match "^[yY]$") {
    if (Get-Process -Name "Code" -ErrorAction SilentlyContinue) {
        Write-Host "LOI: Vui long DONG VS Code truoc khi tiep tuc!" -ForegroundColor Red
        Pause; exit
    }

    $tempZip = "$env:TEMP\$fileName"
    $tempExtract = "$env:TEMP\vscode-extracted"

    Write-Host "Dang tai ban moi..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip

    Write-Host "Dang giai nen..." -ForegroundColor Cyan
    if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    $sourcePath = $tempExtract
    if (Test-Path (Join-Path $tempExtract "vscode")) {
        $sourcePath = Join-Path $tempExtract "vscode"
    }

    Write-Host "Dang sao luu du lieu 'data'..." -ForegroundColor Cyan
    $dataDir = Join-Path $currentDir "data"
    if (Test-Path $dataDir) { 
        if (!(Test-Path (Join-Path $sourcePath "data"))) {
            Copy-Item -Path $dataDir -Destination $sourcePath -Recurse -Force 
        }
    }

    Write-Host "Dang ghi de phien ban moi..." -ForegroundColor Cyan
    Get-ChildItem -Path $currentDir | Where-Object { $_.Name -ne "data" -and $_.Name -notmatch "update.cmd" } | Remove-Item -Recurse -Force
    Get-ChildItem -Path $sourcePath | Copy-Item -Destination $currentDir -Recurse -Force

    Remove-Item $tempZip
    Remove-Item -Recurse -Force $tempExtract

    Write-Host "CAP NHAT THANH CONG!" -ForegroundColor Green
    Pause
}
