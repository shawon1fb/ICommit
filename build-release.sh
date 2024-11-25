#!/bin/bash

VERSION="1.0.0"
PLATFORMS=("x86_64-apple-macosx" "arm64-apple-macosx")
OUTPUT_DIR="releases"

mkdir -p $OUTPUT_DIR

for platform in "${PLATFORMS[@]}"; do
    echo "Building for $platform..."
    swift build -c release --triple $platform
    
    BINARY_NAME="i-commit-$VERSION-$platform"
    cp .build/$platform/release/ICommit "$OUTPUT_DIR/$BINARY_NAME"
    
    # Create checksum
    shasum -a 256 "$OUTPUT_DIR/$BINARY_NAME" > "$OUTPUT_DIR/$BINARY_NAME.sha256"
done

# Create zip archives
cd $OUTPUT_DIR
for file in i-commit-*; do
    if [[ ! $file == *.sha256 ]]; then
        zip "$file.zip" "$file"
        rm "$file"
    fi
done
