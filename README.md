# ICommit 🤖

Let AI write your git commit messages! ICommit analyzes your changes and generates meaningful commits right in your terminal.

![ICommit Demo](demo.gif)

## 🚀 Quick Install

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/shawon1fb/ICommit/main/install.sh | bash
```

## 💫 How to Use

1. Stage your files:
```bash
git add .
```

2. Let AI generate a commit message:
```bash
ICommit
```

3. Choose what to do:
   - ✅ Accept the message
   - 🔄 Generate a new one
   - ✍️ Edit it yourself

## ✨ What You Get

- 🤖 AI-powered commit messages
- 🔄 Interactive message editor
- 🌳 Branch management
- 🚀 One-click commit & push
- 📝 Conventional commit format

## 📋 Requirements

- macOS 14.0+
- Ollama running locally

## ⚙️ Configuration

Configure Ollama by setting these environment variables:

```bash
# Ollama Connection Settings
export OLLAMA_HOST=your_server_ip     # Default: localhost
export OLLAMA_PORT=11434              # Default: 11434
export OLLAMA_SCHEME=http             # Default: http
export OLLAMA_MODEL=your_model        # Default: llama2
```

### Connection Examples

```bash
# Local setup (default)
export OLLAMA_HOST=localhost
export OLLAMA_SCHEME=http

# Remote server with HTTPS
export OLLAMA_HOST=ai.example.com
export OLLAMA_SCHEME=https
```

## 🤔 Common Issues

1. **Nothing happens?**
   - Check if Ollama is running
   - Make sure you staged files (`git add`)
   - Verify your connection settings (HOST/PORT/SCHEME)

2. **Connection failed?**
   - Check if OLLAMA_SCHEME matches your server (http/https)
   - Ensure OLLAMA_HOST is correctly set
   - Verify the port is accessible

Need more help? [Open an issue](https://github.com/shawon1fb/ICommit/issues)

## 💻 Supported Systems
- Works on all Macs (M1/M2/Intel)
