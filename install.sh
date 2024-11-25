#!/bin/bash

VERSION="1.0.0"
GITHUB_USER="shawon1fb"
REPO="ICommit"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        PLATFORM="x86_64-apple-macosx"
        ;;
    arm64)
        PLATFORM="arm64-apple-macosx"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Create temp directory
TMP_DIR=$(mktemp -d)
cd $TMP_DIR

PACKAGE_NAME="i-commit-${VERSION}-${PLATFORM}"
DOWNLOAD_URL="https://github.com/${GITHUB_USER}/${REPO}/releases/download/v${VERSION}/${PACKAGE_NAME}.zip"

echo "Downloading from: $DOWNLOAD_URL"

# Download package
if ! curl -L -o "${PACKAGE_NAME}.zip" "$DOWNLOAD_URL"; then
    echo "Download failed"
    exit 1
fi

# Extract package
if ! unzip "${PACKAGE_NAME}.zip"; then
    echo "Extraction failed"
    exit 1
fi

# Verify checksum
if ! shasum -a 256 -c checksum.sha256; then
    echo "Checksum verification failed"
    exit 1
fi

# Install
sudo mkdir -p /usr/local/bin
sudo mv i-commit /usr/local/bin/
sudo chmod +x /usr/local/bin/i-commit

# Cleanup
cd - > /dev/null
rm -rf "$TMP_DIR"

echo "i-commit installed successfully!"
echo "Run 'i-commit' to get started"
