#!/bin/bash

# Nhận diện OS
OS_RAW=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_RAW=$(uname -m)

if [ "$OS_RAW" == "darwin" ]; then
    OS_NAME="macos"
    EXEC_PATHS=("./Visual Studio Code.app/Contents/Resources/app/bin/code" "../Visual Studio Code.app/Contents/Resources/app/bin/code")
    DATA_FOLDER="code-portable-data"
    EXT="zip"
    ARCH="universal"
else
    OS_NAME="linux"
    EXEC_PATHS=("./bin/code" "../bin/code")
    DATA_FOLDER="data"
    EXT="tar.gz"
    
    if [[ "$ARCH_RAW" == "aarch64" || "$ARCH_RAW" == "arm64" ]]; then
        ARCH="arm64"
    elif [[ "$ARCH_RAW" == "armv7l" || "$ARCH_RAW" == "armhf" ]]; then
        ARCH="armhf"
    else
        ARCH="x64"
    fi
fi

# 1. Lấy phiên bản trực tiếp từ lệnh CLI của VS Code
CURRENT_VERSION="Không xác định"
for p in "${EXEC_PATHS[@]}"; do
    if [ -x "$p" ]; then
        # Gọi CLI và lấy dòng kết quả đầu tiên
        CURRENT_VERSION=$("$p" --version | head -n 1)
        break
    fi
done

echo -e "\033[0;33mPhiên bản hiện tại: $CURRENT_VERSION\033[0m"

# 2. Lấy từ GitHub
API_URL="https://api.github.com/repos/hoangxg4/vscode-portable/releases/latest"
LATEST_TAG=$(curl -sL $API_URL | grep '"tag_name":' | head -n 1 | awk -F '"' '{print $4}')

if [ -z "$LATEST_TAG" ]; then
    echo -e "\033[0;31mKhông thể kết nối GitHub API. Thoát...\033[0m"
    exit 1
fi

LATEST_VERSION=${LATEST_TAG#v}
FILE_NAME="VSCode-Portable-${OS_NAME}-${ARCH}-${LATEST_VERSION}.${EXT}"
DOWNLOAD_URL="https://github.com/hoangxg4/vscode-portable/releases/download/${LATEST_TAG}/${FILE_NAME}"

echo -e "\033[0;32mPhiên bản mới nhất: $LATEST_VERSION\033[0m"

if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
    echo -e "\033[0;36m=> Bạn đang sử dụng phiên bản mới nhất!\033[0m"
fi

read -p "Bạn có muốn tiếp tục cập nhật / cài lại không? (Y/n): " choice
choice=${choice:-Y}

if [[ "$choice" =~ ^[Yy]$ ]]; then
    if pgrep -x "code" > /dev/null; then
        echo -e "\033[0;31mVui lòng ĐÓNG VS Code trước khi cập nhật!\033[0m"
        exit 1
    fi

    CURRENT_DIR=$(pwd)
    TEMP_DIR=$(mktemp -d)
    ARCHIVE_FILE="$TEMP_DIR/$FILE_NAME"

    echo -e "\033[0;36mĐang tải bản mới...\033[0m"
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

    echo -e "\033[0;36mĐang ghi đè phiên bản mới...\033[0m"
    if [ "$OS_NAME" != "macos" ]; then
        find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 ! -name "$DATA_FOLDER" ! -name "update.sh" -exec rm -rf {} +
        cp -R "$TEMP_DIR/extracted/"* "$CURRENT_DIR/"
    else
        rm -rf "$CURRENT_DIR/Visual Studio Code.app"
        cp -R "$TEMP_DIR/extracted/Visual Studio Code.app" "$CURRENT_DIR/"
    fi

    rm -rf "$TEMP_DIR"
    echo -e "\033[0;32mHOÀN TẤT!\033[0m"
else
    echo "Đã hủy cập nhật."
fi
