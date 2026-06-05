#!/bin/bash

SECRETS_FILE=".secrets"
if [ -f "$SECRETS_FILE" ]; then
    export $(grep -v '^#' "$SECRETS_FILE" | xargs)
else
    echo "Error: $SECRETS_FILE file not found!"
    exit 1
fi

./build-and-test-distro.sh bookworm-slim 8.0 13 123 ${ABCPDF13_LICENSE_KEY}
#./build-and-test-distro.sh 22.04-jammy 8.0 13 123 ${ABCPDF13_LICENSE_KEY}
#./build-and-test-distro.sh 24.04-noble 10.0 13 123 ${ABCPDF13_LICENSE_KEY}
#./build-and-test-distro.sh 26.04-resolute 10.0 14 123 ${ABCPDF14_LICENSE_KEY}
#./build-and-test-distro.sh 26.04-resolute 10.0 14 123 ${ABCPDF14_LICENSE_KEY}
exit $?
