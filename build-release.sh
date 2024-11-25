#!/bin/bash

VERSION="1.0.0"
PLATFORMS=("x86_64-apple-macosx" "arm64-apple-macosx")

# Create release directory
rm -rf release && mkdir -p release

for platform in "${PLATFORMS[@]}"; do
    echo "Building for $platform..."
    
    # Build binary
    swift build -c release --triple $platform
    
    # Create release package
    PACKAGE_NAME="i-commit-${VERSION}-${platform}"
    mkdir -p "release/${PACKAGE_NAME}"
    
    # Copy binary
    cp ".build/${platform}/release/ICommit" "release/${PACKAGE_NAME}/i-commit"
    
    # Create checksum
    cd "release/${PACKAGE_NAME}"
    shasum -a 256 i-commit > checksum.sha256
    
    # Create zip
    zip "../${PACKAGE_NAME}.zip" i-commit checksum.sha256
    cd ../..
    
    # Cleanup
    rm -rf "release/${PACKAGE_NAME}"
done

echo "Release packages created in release/"
