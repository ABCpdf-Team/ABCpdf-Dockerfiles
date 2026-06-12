#!/bin/bash
# Exit immediately if any command fails
set -e
# 
SECRETS_FILE=".secrets"
if [ -f "$SECRETS_FILE" ]; then
    export $(grep -v '^#' "$SECRETS_FILE" | xargs)
else
    echo "Error: $SECRETS_FILE file not found!"
    exit 1
fi

# Deprecated images 
./build-and-test-distro.sh bookworm-slim 6.0 13 abcpdf13:6.0-bookworm-slim
./build-and-test-distro.sh bookworm-slim 7.0 13 abcpdf13:7.0-bookworm-slim
./build-and-test-distro.sh bookworm-slim 8.0 13 abcpdf13:8.0-bookworm-slim

./build-and-test-distro.sh jammy 6.0 13 abcpdf13:6.0-jammy
./build-and-test-distro.sh jammy 7.0 13 abcpdf13:7.0-jammy
./build-and-test-distro.sh jammy 8.0 13 abcpdf13:8.0-jammy

./build-and-test-distro.sh noble 8.0 13 abcpdf13:8.0-noble
./build-and-test-distro.sh noble 10.0 13 abcpdf13:10.0-noble

#./build-and-test-distro.sh resolute 10.0 14 abcpdf-14:10.0-resolute
