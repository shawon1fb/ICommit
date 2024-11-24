# Project Setup Guide

This guide will help you set up and build the project on your system.

## Prerequisites

Before you begin, make sure you have:
- Swift installed on your system
- Administrative (sudo) privileges
- Ollama set up on your network

## Environment Configuration

Set up the required environment variables for Ollama:

```bash
export OLLAMA_HOST=192.168.0.10    # Your Ollama server IP address
export OLLAMA_PORT=11434            # Ollama server port
export OLLAMA_MODEL=llama2:3b       # LLM model to use
```

💡 **Tip**: Add these environment variables to your `.bashrc` or `.zshrc` to make them permanent.

## Project Commands

### 1. Cleaning the Project

If you need to start fresh or clean up build artifacts:

```bash
# Remove all build artifacts and Xcode project files
rm -rf .build
rm -rf *.xcodeproj
```

### 2. Development Build

For developers working on the project:

```bash
# Clean and rebuild the project in debug mode
swift package clean
swift package resolve
swift build
```

### 3. Running the Project

To run the project directly:

```bash
# Run in development mode
swift run ICommit
```

This command builds (if necessary) and executes the project in a single step. It's perfect for testing your changes during development.

### 4. Production Installation

To install the project for production use:

```bash
# Build optimized release version
swift build -c release

# Install to system directory (requires sudo)
sudo cp .build/release/ICommit /usr/local/bin/
```

After installation, you can run `ICommit` directly from anywhere in your terminal.

## Troubleshooting

- If you encounter permission issues during installation, make sure you have the necessary sudo privileges
- Verify that the Ollama server is running at the specified host and port
- Check that the specified LLM model is available on your Ollama server

## Need Help?

If you encounter any issues or need assistance, please:
1. Check if all prerequisites are properly installed
2. Verify your environment variables are correctly set
3. Try cleaning and rebuilding the project
