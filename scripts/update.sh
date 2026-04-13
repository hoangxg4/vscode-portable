#!/bin/bash

# Nhận diện OS
OS_RAW=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_RAW=$(uname -m)

if [ "$OS_RAW" == "darwin" ]; then
    OS_NAME="macos"
    EXEC_PATHS=("./Visual Studio Code.app/Contents/Resources/app/bin/code" "../Visual Studio Code.app/Contents/Resources/app/bin/code")
    DATA_FOLDER="code-portable-data"
    EXT="zip"
else
    OS_NAME="linux"
    EXEC_PATHS=("./bin/code" "../bin/code")
    DATA_FOLDER="data"
    EXT="tar.gz"
fi

# 1. Lấy phiên bản
CURRENT_VERSION="Không xác định"
for p in "${EXEC_PATHS[@]}"; do
    if [ -x "$p" ]; then
        CURRENT_VERSION=$("$p" --version | head -n 1)
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

    CURRENT_DIR=$(pwd)
    TEMP_DIR=$(mktemp -d)
    
    echo "Đang tải và giải nén..."
    curl -# -L "https://github.com/hoangxg4/vscode-portable/releases/download/${LATEST_TAG}/VSCode-Portable-${OS_NAME}-*-${LATEST_VERSION}.${EXT}" -o "$TEMP_DIR/pkg.${EXT}"
    
    mkdir -p "$TEMP_DIR/extracted"
    if [ "$EXT" == "zip" ]; then
        unzip -q "$TEMP_DIR/pkg.${EXT}" -d "$TEMP_DIR/extracted"
    else
        tar -xzf "$TEMP_DIR/pkg.${EXT}" -C "$TEMP_DIR/extracted"
    fi

    # --- SỬA LỖI FOLDER Ở ĐÂY ---
    # Nếu là Linux, nội dung nằm trong folder 'vscode'
    # Nếu là macOS, nội dung nằm ngay tại 'extracted' (vì file zip macOS chứa .app trực tiếp)
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
        # Đối với macOS, chỉ cần ghi đè file .app
        rm -rf "$CURRENT_DIR/Visual Studio Code.app"
        cp -R "$SOURCE_PATH/Visual Studio Code.app" "$CURRENT_DIR/"
        # Copy lại script update nếu nó nằm ngoài
        cp "$SOURCE_PATH/update.sh" "$CURRENT_DIR/" 2>/dev/null || true
    fi

    rm -rf "$TEMP_DIR"
    echo -e "\033[0;32mXONG!\033[0m"
fi
