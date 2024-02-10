#!/bin/sh

# Create build dir if it doesn't exist
mkdir -p build

# Compile ./encoder/main.go to ./build/main
cd ./compressor && make build-cli && cd ..

# Run the foundry tests passing all arguments
forge test "$@"
