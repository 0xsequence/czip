#!/bin/sh
# Navigate to the encoder/cmd directory and execute the Go program with all passed parameters
cd "$(dirname "$0")/encoder" && go run main.go "$@"
