#!/bin/bash

set -e # Exit immediately if any command fail

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
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-bookworm-slim.Dockerfile 6.0 13
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-bookworm-slim.Dockerfile 7.0 13
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-bookworm-slim.Dockerfile 8.0 13
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-jammy.Dockerfile 6.0 13
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-jammy.Dockerfile 7.0 13

# Deprecated repo
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-jammy.Dockerfile 8.0 13
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-noble.Dockerfile 8.0 13
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-noble.Dockerfile 10.0 13
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-jammy.Dockerfile 8.0 14
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-noble.Dockerfile 8.0 14
# ./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-noble.Dockerfile 10.0 14
./build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-bookworm-slim.Dockerfile 8.0 14

# Currently Supported
./build-and-test-distro.sh dockerfiles/abcpdf14.Dockerfile 10.0
./build-and-test-distro.sh dockerfiles/abcpdf14-chiseled.Dockerfile 10.0
