<# :
@echo off
setlocal
echo Dang khoi dong trinh cap nhat...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))" %*
exit /b %errorlevel%
#>

$ErrorActionPreference = "Stop"
Write-Host "--- TRINH CAP NHAT VS CODE PORTABLE ---" -ForegroundColor Cyan

# 1. Tim file thuc thi cua VS Code (Code.exe hoac bin\code.cmd)
$currentDir = Get-Location
$exePaths = @(".\bin\code.cmd", "..\bin\code.cmd", ".\Code.exe", "..\Code.exe")
$validExe = $null

foreach ($p in $exePaths) {
    if (Test-Path $p) {
        $validExe = $p
        break
    }
}

$currentVersion = "Khong xac dinh"
if ($validExe) {
    try {
        # Goi truc tiep lenh code --version va lay dong dau tien
        $versionOutput = & $validExe --version
        $currentVersion = $versionOutput[0].Trim()
        
        # Dat lai thu muc goc cho chuan xac
        $fullPath = Resolve-Path $validExe
        if ($fullPath -match "bin\\code.cmd$") {
            $currentDir = Split-Path (Split-Path $fullPath)
        } else {
            $currentDir = Split-Path $fullPath
        }
    } catch {
        Write-Host "Khong the lay phien ban tu file thuc thi!" -ForegroundColor Red
    }
}

Write-Host "Phien ban hien tai: $currentVersion" -ForegroundColor Yellow

# 2. Lay phien ban moi nhat tu GitHub API
$apiUrl = "https://api.github.com/repos/hoangxg4/vscode-portable/releases/latest"
try {
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
} catch {
    Write-Host "Khong the ket noi den GitHub API!" -ForegroundColor Red
    Pause; exit
}

$choice = Read-Host "Ban co muon tiep tuc cap nhat / cai lai khong? (Y/N)"
if ($choice -match "^[yY]$") {
    $vscodeProcess = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcess) {
        Write-Host "LOI: Vui long DONG VS Code truoc khi cap nhat!" -ForegroundColor Red
        Pause; exit
    }

    $tempZip = "$env:TEMP\$fileName"
    $tempExtract = "$env:TEMP\vscode-extracted"

    Write-Host "Dang tai ban moi..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip

    Write-Host "Dang giai nen..." -ForegroundColor Cyan
    if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    Write-Host "Dang sao luu thu muc data..." -ForegroundColor Cyan
    $dataDir = Join-Path $currentDir "data"
    if (Test-Path $dataDir) { 
        Copy-Item -Path $dataDir -Destination $tempExtract -Recurse -Force 
    }

    Write-Host "Dang ghi de phien ban moi..." -ForegroundColor Cyan
    Get-ChildItem -Path $currentDir | Where-Object { $_.Name -ne "data" -and $_.Name -notmatch "update.cmd" } | Remove-Item -Recurse -Force
    Get-ChildItem -Path $tempExtract | Copy-Item -Destination $currentDir -Recurse -Force

    Remove-Item $tempZip
    Remove-Item -Recurse -Force $tempExtract

    Write-Host "CAP NHAT THANH CONG!" -ForegroundColor Green
    Pause
}
