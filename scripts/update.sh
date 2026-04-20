#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT_DIR="$SCRIPT_DIR"

OS_RAW=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_RAW=$(uname -m)

if [ "$OS_RAW" == "darwin" ]; then
    OS_NAME="macos"
    DATA_FOLDER="code-portable-data"
    EXT="zip"
else
    OS_NAME="linux"
    DATA_FOLDER="data"
    EXT="tar.gz"
fi

# 1. Đọc version.txt cực kỳ đơn giản
CURRENT_VERSION="Không xác định"
VERSION_PATHS=("$SCRIPT_DIR/version.txt" "$SCRIPT_DIR/../version.txt")

for p in "${VERSION_PATHS[@]}"; do
    if [ -f "$p" ]; then
        CURRENT_VERSION=$(head -n 1 "$p" | tr -d '[:space:]')
        CURRENT_DIR=$(dirname "$p") # Gốc cài đặt là nơi chứa version.txt
        break
    fi
done

echo -e "\033[0;33mPhiên bản hiện tại: $CURRENT_VERSION\033[0m"

# 2. Lấy từ GitHub
API_URL="https://api.github.com/repos/hoangxg4/vscode-portable/releases/latest"
LATEST_TAG=$(curl -sL $API_URL | grep '"tag_name":' | head -n 1 | awk -F '"' '{print $4}')
LATEST_VERSION=${LATEST_TAG#v}

echo -e "\033[0;32mPhiên bản mới nhất: $LATEST_VERSION\033[0m"

read -p "Bạn có muốn tiếp tục cập nhật? (Y/n): " choice
choice=${choice:-Y}

if [[ "$choice" =~ ^[Yy]$ ]]; then
    if pgrep -x "code" > /dev/null; then
        echo -e "\033[0;31mVui lòng đóng VS Code!\033[0m"
        exit 1
    fi

    TEMP_DIR=$(mktemp -d)
    
    echo "Đang tải và giải nén..."
    curl -# -L "https://github.com/hoangxg4/vscode-portable/releases/download/${LATEST_TAG}/VSCode-Portable-${OS_NAME}-*-${LATEST_VERSION}.${EXT}" -o "$TEMP_DIR/pkg.${EXT}"
    
    mkdir -p "$TEMP_DIR/extracted"
    if [ "$EXT" == "zip" ]; then
        unzip -q "$TEMP_DIR/pkg.${EXT}" -d "$TEMP_DIR/extracted"
    else
        tar -xzf "$TEMP_DIR/pkg.${EXT}" -C "$TEMP_DIR/extracted"
    fi

    SOURCE_PATH="$TEMP_DIR/extracted"
    if [ -d "$TEMP_DIR/extracted/vscode" ]; then
        SOURCE_PATH="$TEMP_DIR/extracted/vscode"
    fi

    echo "Đang xử lý dữ liệu..."
    if [ -d "$CURRENT_DIR/$DATA_FOLDER" ]; then
        cp -R "$CURRENT_DIR/$DATA_FOLDER" "$SOURCE_PATH/"
    fi

    echo "Đang ghi đè..."
    if [ "$OS_NAME" == "linux" ]; then
        find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 ! -name "$DATA_FOLDER" ! -name "update.sh" -exec rm -rf {} +
        cp -R "$SOURCE_PATH/"* "$CURRENT_DIR/"
    else
        rm -rf "$CURRENT_DIR/Visual Studio Code.app"
        cp -R "$SOURCE_PATH/Visual Studio Code.app" "$CURRENT_DIR/"
        cp "$SOURCE_PATH/update.sh" "$CURRENT_DIR/" 2>/dev/null || true
        cp "$SOURCE_PATH/version.txt" "$CURRENT_DIR/" 2>/dev/null || true
    fi

    rm -rf "$TEMP_DIR"
    echo -e "\033[0;32mXONG!\033[0m"
fi
