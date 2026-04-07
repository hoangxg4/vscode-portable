#!/bin/bash

# Xác định OS (Linux hay macOS)
OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_NAME=$(uname -m)

if [ "$OS_NAME" == "darwin" ]; then
    API_URL="https://update.code.visualstudio.com/api/update/darwin/stable"
    DATA_FOLDER="code-portable-data"
    EXT="zip"
else
    API_URL="https://update.code.visualstudio.com/api/update/linux-x64/stable"
    DATA_FOLDER="data"
    EXT="tar.gz"
fi

echo -e "\033[0;36mĐang kiểm tra phiên bản VS Code mới nhất...\033[0m"
LATEST_VERSION=$(curl -sL $API_URL | grep -o '"productVersion":"[^"]*' | cut -d'"' -f4)
DOWNLOAD_URL=$(curl -sL $API_URL | grep -o '"url":"[^"]*' | cut -d'"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    echo "Không thể kiểm tra phiên bản. Thoát..."
    exit 1
fi

echo -e "\033[0;32mPhiên bản mới nhất là: $LATEST_VERSION\033[0m"
read -p "Bạn có muốn cập nhật không? (Y/n): " choice
choice=${choice:-Y}

if [[ "$choice" =~ ^[Yy]$ ]]; then
    if pgrep -x "code" > /dev/null; then
        echo -e "\033[0;31mVui lòng ĐÓNG VS Code trước khi cập nhật!\033[0m"
        exit 1
    fi

    CURRENT_DIR=$(pwd)
    TEMP_DIR=$(mktemp -d)
    ARCHIVE_FILE="$TEMP_DIR/vscode.$EXT"

    echo -e "\033[0;36mĐang tải VS Code v$LATEST_VERSION...\033[0m"
    curl -# -L $DOWNLOAD_URL -o "$ARCHIVE_FILE"

    echo -e "\033[0;36mĐang giải nén...\033[0m"
    mkdir -p "$TEMP_DIR/extracted"
    if [ "$EXT" == "zip" ]; then
        unzip -q "$ARCHIVE_FILE" -d "$TEMP_DIR/extracted"
    else
        tar -xzf "$ARCHIVE_FILE" -C "$TEMP_DIR/extracted" --strip-components=1
    fi

    echo -e "\033[0;36mĐang sao lưu dữ liệu...\033[0m"
    if [ -d "$CURRENT_DIR/$DATA_FOLDER" ]; then
        cp -R "$CURRENT_DIR/$DATA_FOLDER" "$TEMP_DIR/extracted/"
    fi

    echo -e "\033[0;36mĐang ghi đè bản mới...\033[0m"
    # Dành cho Linux (Xóa hết trừ data và script)
    if [ "$OS_NAME" != "darwin" ]; then
        find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 ! -name "$DATA_FOLDER" ! -name "update.sh" -exec rm -rf {} +
        cp -R "$TEMP_DIR/extracted/"* "$CURRENT_DIR/"
    else
        # Dành cho macOS (Thay thế thư mục .app)
        rm -rf "$CURRENT_DIR/Visual Studio Code.app"
        cp -R "$TEMP_DIR/extracted/Visual Studio Code.app" "$CURRENT_DIR/"
    fi

    rm -rf "$TEMP_DIR"
    echo -e "\033[0;32mCập nhật thành công lên $LATEST_VERSION!\033[0m"
else
    echo "Đã hủy cập nhật."
fi
