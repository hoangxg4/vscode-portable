<# :
@echo off
setlocal
echo Dang khoi dong trinh cap nhat...
:: Chạy lõi PowerShell ẩn bên trong file cmd này
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))" %*
exit /b %errorlevel%
#>

$ErrorActionPreference = "Stop"
Write-Host "Dang kiem tra phien ban moi nhat tu hoangxg4/vscode-portable..." -ForegroundColor Cyan

# Gọi API GitHub
$apiUrl = "https://api.github.com/repos/hoangxg4/vscode-portable/releases/latest"
$releaseInfo = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
$latestTag = $releaseInfo.tag_name
$latestVersion = $latestTag -replace "^v", ""

$arch = if ($env:PROCESSOR_ARCHITECTURE -match "ARM") { "arm64" } else { "x64" }
$fileName = "VSCode-Portable-windows-$arch-$latestVersion.zip"
$downloadUrl = "https://github.com/hoangxg4/vscode-portable/releases/download/$latestTag/$fileName"

Write-Host "Phien ban moi nhat tren GitHub la: $latestVersion" -ForegroundColor Green

# Hỗ trợ cờ --force cho CI Test
$isCiTest = $args -contains "--force"

if ($isCiTest) {
    Write-Host "[CI MODE] Tu dong xac nhan cap nhat." -ForegroundColor Yellow
    $choice = "Y"
} else {
    $choice = Read-Host "Ban co muon cap nhat khong? (Y/N)"
}

if ($choice -match "^[yY]$") {
    $vscodeProcess = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcess) {
        Write-Host "Vui long DONG VS Code truoc khi cap nhat!" -ForegroundColor Red
        if (-not $isCiTest) { Pause }
        exit 1
    }

    $currentDir = Get-Location
    $tempZip = "$env:TEMP\$fileName"
    $tempExtract = "$env:TEMP\vscode-extracted"

    Write-Host "Dang tai $fileName..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip

    Write-Host "Dang giai nen..." -ForegroundColor Cyan
    if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    Write-Host "Dang sao luu thu muc data..." -ForegroundColor Cyan
    $dataDir = Join-Path $currentDir "data"
    if (Test-Path $dataDir) { Copy-Item -Path $dataDir -Destination $tempExtract -Recurse -Force }

    Write-Host "Dang ghi de ban moi..." -ForegroundColor Cyan
    Get-ChildItem -Path $currentDir | Where-Object { $_.Name -ne "data" -and $_.Name -notmatch "update.cmd" } | Remove-Item -Recurse -Force
    Get-ChildItem -Path $tempExtract | Copy-Item -Destination $currentDir -Recurse -Force

    Remove-Item $tempZip
    Remove-Item -Recurse -Force $tempExtract

    Write-Host "Cap nhat thanh cong!" -ForegroundColor Green
    if (-not $isCiTest) { Pause }
} else {
    Write-Host "Da huy cap nhat." -ForegroundColor Yellow
    if (-not $isCiTest) { Pause }
}
