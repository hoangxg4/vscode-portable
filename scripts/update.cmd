<# :
@echo off
setlocal
echo Dang khoi dong trinh cap nhat...
:: Chạy PowerShell ẩn bên trong
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))" %*
exit /b %errorlevel%
#>

$ErrorActionPreference = "Stop"
Write-Host "Dang kiem tra phien ban VS Code..." -ForegroundColor Cyan

# 1. Đọc phiên bản hiện tại từ lõi VS Code
$currentDir = Get-Location
$packageJson = Join-Path $currentDir "resources\app\package.json"
$currentVersion = "Khong xac dinh"

if (Test-Path $packageJson) {
    try {
        $json = Get-Content -Raw -Path $packageJson | ConvertFrom-Json
        $currentVersion = $json.version
    } catch {}
}

Write-Host "Phien ban hien tai: $currentVersion" -ForegroundColor Yellow

# 2. Lấy phiên bản mới nhất từ GitHub
$apiUrl = "https://api.github.com/repos/hoangxg4/vscode-portable/releases/latest"
$releaseInfo = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
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
    $vscodeProcess = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcess) {
        Write-Host "Vui long DONG VS Code truoc khi cap nhat!" -ForegroundColor Red
        Pause
        exit
    }

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

    Write-Host "Hoan tat!" -ForegroundColor Green
    Pause
} else {
    Write-Host "Da huy cap nhat." -ForegroundColor Yellow
    Pause
}
