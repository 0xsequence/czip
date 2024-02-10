#!/bin/sh

# Create build dir if it doesn't exist
mkdir -p build

# Compile ./encoder/main.go to ./build/main
cd ./encoder && go build -o ../build/main ./main.go && cd ../

# Run the foundry tests passing all arguments
forge test "$@"
