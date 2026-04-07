# Yêu cầu chạy dưới quyền Administrator nếu để ở thư mục C:\
$ErrorActionPreference = "Stop"

Write-Host "Đang kiểm tra phiên bản VS Code mới nhất..." -ForegroundColor Cyan
$apiUrl = "https://update.code.visualstudio.com/api/update/win32-x64-archive/stable"
$latestData = Invoke-RestMethod -Uri $apiUrl
$latestVersion = $latestData.productVersion
$downloadUrl = $latestData.url

Write-Host "Phiên bản mới nhất là: $latestVersion" -ForegroundColor Green
$choice = Read-Host "Bạn có muốn cập nhật không? (Y/N)"

if ($choice -match "^[yY]$") {
    $vscodeProcess = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcess) {
        Write-Host "Vui lòng ĐÓNG VS Code trước khi cập nhật!" -ForegroundColor Red
        Pause
        exit
    }

    $currentDir = Get-Location
    $tempZip = "$env:TEMP\vscode-update.zip"
    $tempExtract = "$env:TEMP\vscode-extracted"

    Write-Host "Đang tải VS Code v$latestVersion..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip

    Write-Host "Đang giải nén..." -ForegroundColor Cyan
    if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    Write-Host "Đang sao lưu thư mục data..." -ForegroundColor Cyan
    $dataDir = Join-Path $currentDir "data"
    if (Test-Path $dataDir) {
        Copy-Item -Path $dataDir -Destination $tempExtract -Recurse -Force
    }

    Write-Host "Đang ghi đè bản mới..." -ForegroundColor Cyan
    # Xóa các file cũ (ngoại trừ thư mục data và chính file update.ps1 này)
    Get-ChildItem -Path $currentDir | Where-Object { $_.Name -ne "data" -and $_.Name -ne "update.ps1" } | Remove-Item -Recurse -Force
    
    # Copy file mới sang
    Get-ChildItem -Path $tempExtract | Copy-Item -Destination $currentDir -Recurse -Force

    # Dọn dẹp
    Remove-Item $tempZip
    Remove-Item -Recurse -Force $tempExtract

    Write-Host "Cập nhật thành công lên $latestVersion!" -ForegroundColor Green
    Pause
} else {
    Write-Host "Đã hủy cập nhật." -ForegroundColor Yellow
    Pause
}
