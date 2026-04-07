#!/bin/bash

echo -e "\033[0;36mĐang kiểm tra phiên bản mới nhất từ repo hoangxg4/vscode-portable...\033[0m"

# Lấy tag release mới nhất từ GitHub API
API_URL="https://api.github.com/repos/hoangxg4/vscode-portable/releases/latest"
LATEST_TAG=$(curl -sL $API_URL | grep '"tag_name":' | head -n 1 | awk -F '"' '{print $4}')

if [ -z "$LATEST_TAG" ]; then
    echo -e "\033[0;31mKhông thể lấy thông tin phiên bản từ GitHub. Thoát...\033[0m"
    exit 1
fi

# Loại bỏ chữ 'v' ở đầu (ví dụ v1.86.0 -> 1.86.0)
LATEST_VERSION=${LATEST_TAG#v}

# Nhận diện Hệ điều hành và Kiến trúc
OS_RAW=$(uname -s | tr '[:upper:]' '[:lower:]')

if [ "$OS_RAW" == "darwin" ]; then
    OS_NAME="macos"
    EXT="zip"
    DATA_FOLDER="code-portable-data"
    ARCH="universal" # Ép luôn dùng bản universal cho macOS
else
    OS_NAME="linux"
    EXT="tar.gz"
    DATA_FOLDER="data"
    
    # Chỉ check kiến trúc nếu là Linux
    ARCH_RAW=$(uname -m)
    if [[ "$ARCH_RAW" == "aarch64" || "$ARCH_RAW" == "arm64" ]]; then
        ARCH="arm64"
    elif [[ "$ARCH_RAW" == "armv7l" || "$ARCH_RAW" == "armhf" ]]; then
        ARCH="armhf"
    else
        ARCH="x64"
    fi
fi

FILE_NAME="VSCode-Portable-${OS_NAME}-${ARCH}-${LATEST_VERSION}.${EXT}"
DOWNLOAD_URL="https://github.com/hoangxg4/vscode-portable/releases/download/${LATEST_TAG}/${FILE_NAME}"

echo -e "\033[0;32mPhiên bản mới nhất trên GitHub là: $LATEST_VERSION\033[0m"
read -p "Bạn có muốn cập nhật không? (Y/n): " choice
choice=${choice:-Y}

if [[ "$choice" =~ ^[Yy]$ ]]; then
    if pgrep -x "code" > /dev/null; then
        echo -e "\033[0;31mVui lòng ĐÓNG VS Code trước khi cập nhật!\033[0m"
        exit 1
    fi

    CURRENT_DIR=$(pwd)
    TEMP_DIR=$(mktemp -d)
    ARCHIVE_FILE="$TEMP_DIR/$FILE_NAME"

    echo -e "\033[0;36mĐang tải $FILE_NAME...\033[0m"
    curl -# -L "$DOWNLOAD_URL" -o "$ARCHIVE_FILE"

    echo -e "\033[0;36mĐang giải nén...\033[0m"
    mkdir -p "$TEMP_DIR/extracted"
    if [ "$EXT" == "zip" ]; then
        unzip -q "$ARCHIVE_FILE" -d "$TEMP_DIR/extracted"
    else
        tar -xzf "$ARCHIVE_FILE" -C "$TEMP_DIR/extracted"
    fi

    echo -e "\033[0;36mĐang sao lưu dữ liệu ($DATA_FOLDER)...\033[0m"
    if [ -d "$CURRENT_DIR/$DATA_FOLDER" ]; then
        cp -R "$CURRENT_DIR/$DATA_FOLDER" "$TEMP_DIR/extracted/"
    fi

    echo -e "\033[0;36mĐang ghi đè bản mới...\033[0m"
    if [ "$OS_NAME" != "macos" ]; then
        find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 ! -name "$DATA_FOLDER" ! -name "update.sh" -exec rm -rf {} +
        cp -R "$TEMP_DIR/extracted/"* "$CURRENT_DIR/"
    else
        rm -rf "$CURRENT_DIR/Visual Studio Code.app"
        cp -R "$TEMP_DIR/extracted/Visual Studio Code.app" "$CURRENT_DIR/"
    fi

    rm -rf "$TEMP_DIR"
    echo -e "\033[0;32mCập nhật thành công lên $LATEST_VERSION!\033[0m"
else
    echo "Đã hủy cập nhật."
fi
