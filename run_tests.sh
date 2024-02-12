#!/bin/sh

set -e

# Delete the old bin if it exists
rm -f ./compressor/bin/*

# Compile ./encoder/main.go to ./build/main
cd ./compressor && make build-cli && cd ..

# Run the foundry tests passing all arguments
forge test "$@"
