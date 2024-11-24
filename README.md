# README

## Clean Project

To clean the project and remove all build artifacts, run the following commands:

```bash
rm -rf .build
rm -rf *.xcodeproj
```

## Debug Build

For a debug build of the project, execute:

```bash
swift package clean
swift package resolve
swift build
```

## Build Command

To build the project in release configuration and copy the executable to `/usr/local/bin/`, use:

```bash
swift build -c release
sudo cp .build/release/ICommit /usr/local/bin/
```

## env path
export OLLAMA_HOST=192.168.0.213
export OLLAMA_PORT=11434
export OLLAMA_MODEL=llama2:3b
