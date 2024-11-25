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

## ⚙️ Custom Setup (Optional)

```bash
# Configure Ollama
export OLLAMA_HOST=your_server_ip    # Default: localhost
export OLLAMA_PORT=11434             # Default: 11434
export OLLAMA_MODEL=your_model       # Default: llama2
```

## 🤔 Common Issues

1. **Nothing happens?**
   - Check if Ollama is running
   - Make sure you staged files (`git add`)

2. **Custom server?**
   - Update OLLAMA_HOST in Custom Setup

Need more help? [Open an issue](https://github.com/shawon1fb/ICommit/issues)

## 💻 Supported Systems
- Works on all Macs (M1/M2/Intel)
