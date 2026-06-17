#!/bin/bash

set -e # Exit immediately if any command fails

SECRETS_FILE=".secrets"
if [ -f "$SECRETS_FILE" ]; then
    export $(grep -v '^#' "$SECRETS_FILE" | xargs)
else
    echo "Error: $SECRETS_FILE file not found!"
    exit 1
fi

# .NET support dates
# .NET6.0  EOL: 2024/11/12
# .NET7.0  EOL: 2024/05/14
# .NET8.0  EOL: 2026/11/10 - currently in "Maintenance" only phase
# .NET10.0 EOL 2028/11/14 

# OS Support 
# bookworm-slim: Out of official support 2026/06/10 but some updates to 2028/06/30
# Jammy-22.04: official support until: 2027/05
# Noble-24.04: official support until: 2029/04
# Resolute-26.04: official support until: 2031/05


# Out of support - either .NET version or OS
# ./build-and-test-distro.sh bookworm-slim 6.0 13 abcpdf13:6.0-bookworm-slim 
# ./build-and-test-distro.sh bookworm-slim 7.0 13 abcpdf13:7.0-bookworm-slim 
# ./build-and-test-distro.sh bookworm-slim 8.0 13 abcpdf13:8.0-bookworm-slim 
# ./build-and-test-distro.sh jammy 6.0 13 abcpdf13:6.0-jammy
# ./build-and-test-distro.sh jammy 7.0 13 abcpdf13:7.0-jammy

# Currently in support
./build-and-test-distro.sh jammy 8.0 13 abcpdf13:8.0-jammy 
./build-and-test-distro.sh noble 8.0 13 abcpdf13:8.0-noble
./build-and-test-distro.sh noble 10.0 13 abcpdf13:10.0-noble
./build-and-test-distro.sh resolute 10.0 14 abcpdf-14:10.0-resolute
