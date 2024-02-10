#!/bin/sh
# Navigate to the compressor/cmd/czip-compressor dir and execute the Go program with all passed parameters
cd "$(dirname "$0")/compressor/cmd/czip-compressor" && go run . "$@"
