<# :
@echo off
setlocal
echo Dang khoi dong trinh cap nhat...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression $([System.IO.File]::ReadAllText('%~f0'))" %*
exit /b %errorlevel%
#>

$ErrorActionPreference = "Stop"
Write-Host "--- TRINH CAP NHAT VS CODE PORTABLE ---" -ForegroundColor Cyan

# 1. Tim file thuc thi de xac dinh thu muc goc
$currentDir = Get-Location
$exePaths = @(".\bin\code.cmd", "..\bin\code.cmd", ".\Code.exe", "..\Code.exe")
$validExe = $null

foreach ($p in $exePaths) {
    if (Test-Path $p) { $validExe = $p; break }
}

$currentVersion = "Khong xac dinh"
if ($validExe) {
    try {
        $versionOutput = & $validExe --version
        $currentVersion = $versionOutput[0].Trim()
        $fullPath = Resolve-Path $validExe
        $currentDir = if ($fullPath -match "bin\\code.cmd$") { Split-Path (Split-Path $fullPath) } else { Split-Path $fullPath }
    } catch { }
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

    # --- CHINH SUA QUAN TRONG O DAY ---
    # Neu trong file zip co folder 'vscode', ta se copy noi dung ben TRONG do
    $sourcePath = $tempExtract
    if (Test-Path (Join-Path $tempExtract "vscode")) {
        $sourcePath = Join-Path $tempExtract "vscode"
    }

    Write-Host "Dang sao luu du lieu 'data'..." -ForegroundColor Cyan
    $dataDir = Join-Path $currentDir "data"
    if (Test-Path $dataDir) { 
        # Copy data vao folder tam truoc
        if (!(Test-Path (Join-Path $sourcePath "data"))) {
            Copy-Item -Path $dataDir -Destination $sourcePath -Recurse -Force 
        }
    }

    Write-Host "Dang ghi de phien ban moi..." -ForegroundColor Cyan
    # Xoa moi thu o thu muc hien tai (tru data va update script)
    Get-ChildItem -Path $currentDir | Where-Object { $_.Name -ne "data" -and $_.Name -notmatch "update.cmd" } | Remove-Item -Recurse -Force
    
    # Copy noi dung da "phang" tu sourcePath vao currentDir
    Get-ChildItem -Path $sourcePath | Copy-Item -Destination $currentDir -Recurse -Force

    Remove-Item $tempZip
    Remove-Item -Recurse -Force $tempExtract

    Write-Host "CAP NHAT THANH CONG!" -ForegroundColor Green
    Pause
}
