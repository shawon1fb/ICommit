# ICommit 🤖

Generate meaningful git commit messages using AI without leaving your terminal.

## Key Features

- **AI-Powered Messages**: Uses Ollama to analyze your staged changes and generate semantic commit messages
- **Interactive Mode**: Review, regenerate, or edit suggested commit messages
- **Git Integration**: One-step commit and push after message approval
- **Branch Management**: View and select target branches for pushing changes
- **Conventional Commits**: Follows standard commit message format (type, scope, description)

## Quick Start

```bash
# Install
swift build -c release
sudo cp .build/release/ICommit /usr/local/bin/

# Run
ICommit
```

## Requirements

- macOS 14.0+
- Swift installed
- Ollama server running

## Configuration

Set Ollama environment variables:
```bash
export OLLAMA_HOST=your_server_ip    # Default: localhost
export OLLAMA_PORT=11434             # Default: 11434
export OLLAMA_MODEL=your_model       # Default: llama2
```

## Usage Example

```bash
# Stage your changes
git add .

# Generate commit message
i-commit

# Review options:
# 1. Accept generated message
# 2. Generate new message
# 3. Edit message manually
# - Edit commit type
# - Modify scope
# - Update description

# Confirm and push
```

## Development

```bash
# Build
swift build

# Run locally
swift run ICommit

# Clean
swift package clean
```

## Need Help?

- Check Ollama server is running
- Verify environment variables
- Ensure files are staged before running
