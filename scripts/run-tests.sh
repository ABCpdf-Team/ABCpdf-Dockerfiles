#!/bin/bash

set -e # Exit immediately if any command fail

DIR="$(cd "$(dirname "$0")" && pwd)"
SECRETS_FILE="${DIR}/../.secrets"
if [ -f "$SECRETS_FILE" ]; then
    export $(grep -v '^#' "$SECRETS_FILE" | xargs)
else
    echo "Error: $SECRETS_FILE file not found!"
    exit 1
fi

if [ -z "${ABCPDF_LICENSE_KEY}" ]; then
    echo "Error: ABCPDF_LICENSE_KEY is not set in $SECRETS_FILE."
    exit 1
fi

# .NET support dates
# .NET6   EOL: 2024/11/12
# .NET7   EOL: 2024/05/14
# .NET8   EOL: 2026/11/10 - currently in "Maintenance" only phase
# .NET10  EOL 2028/11/14

# OS Support
# bookworm-slim: Out of official support 2026/06/10 but some updates to 2028/06/30
# Jammy-22.04: official support until: 2027/05
# Noble-24.04: official support until: 2029/04
# Resolute-26.04: official support until: 2031/05

# Deprecated images
# ${DIR}/build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-bookworm-slim.Dockerfile 6 13
# ${DIR}/build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-bookworm-slim.Dockerfile 7 13
# ${DIR}/build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-bookworm-slim.Dockerfile 8 13
# ${DIR}/build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-noble.Dockerfile 8 13
# ${DIR}/build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-noble.Dockerfile 10 13
# ${DIR}/build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-jammy.Dockerfile 6 13
# ${DIR}/build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-jammy.Dockerfile 7 13
# ${DIR}/build-and-test-distro.sh dockerfiles/deprecated/mcr-aspnet-jammy.Dockerfile 8 13

# Currently Supported
${DIR}/build-and-test-distro.sh dockerfiles/abcpdf14.Dockerfile 10 14
${DIR}/build-and-test-distro.sh dockerfiles/abcpdf14-chiseled.Dockerfile 10 14
