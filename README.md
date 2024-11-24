
## CLEAN PROJECT
    rm -rf .build
    rm -rf *.xcodeproj

##DEBUG BUILD
    swift package clean
    swift package resolve
    swift build

## BUILD CMD
    swift build -c release
    sudo cp .build/release/ICommit /usr/local/bin/
