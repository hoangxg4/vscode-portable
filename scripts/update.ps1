$ErrorActionPreference = "Stop"

Write-Host "Đang kiểm tra phiên bản mới nhất từ repo hoangxg4/vscode-portable..." -ForegroundColor Cyan

# Gọi GitHub API để lấy release mới nhất
$apiUrl = "https://api.github.com/repos/hoangxg4/vscode-portable/releases/latest"
$releaseInfo = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
$latestTag = $releaseInfo.tag_name
$latestVersion = $latestTag -replace "^v", ""

# Nhận diện kiến trúc CPU (x64 hoặc arm64)
$arch = if ($env:PROCESSOR_ARCHITECTURE -match "ARM") { "arm64" } else { "x64" }

# Tạo link tải file dựa trên tên file sinh ra từ GitHub Actions
$fileName = "VSCode-Portable-windows-$arch-$latestVersion.zip"
$downloadUrl = "https://github.com/hoangxg4/vscode-portable/releases/download/$latestTag/$fileName"

Write-Host "Phiên bản mới nhất trên GitHub là: $latestVersion" -ForegroundColor Green
$choice = Read-Host "Bạn có muốn cập nhật không? (Y/N)"

if ($choice -match "^[yY]$") {
    $vscodeProcess = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcess) {
        Write-Host "Vui lòng ĐÓNG VS Code trước khi cập nhật!" -ForegroundColor Red
        Pause
        exit
    }

    $currentDir = Get-Location
    $tempZip = "$env:TEMP\$fileName"
    $tempExtract = "$env:TEMP\vscode-extracted"

    Write-Host "Đang tải $fileName..." -ForegroundColor Cyan
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
    # Giữ lại thư mục data hiện tại để an toàn, xóa các file còn lại
    Get-ChildItem -Path $currentDir | Where-Object { $_.Name -ne "data" -and $_.Name -ne "update.ps1" } | Remove-Item -Recurse -Force
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
