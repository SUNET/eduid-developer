#!/usr/bin/env bash
set -euo pipefail

TOKEN_LABEL=eduid-hasher
PIN=1234

# Check if token already exists
if softhsm2-util --show-slots 2>/dev/null | grep -q "${TOKEN_LABEL}"; then
    echo "Token '${TOKEN_LABEL}' already exists"
    exit 0
fi

echo "Initializing token '${TOKEN_LABEL}'..."
softhsm2-util --init-token --free --label "${TOKEN_LABEL}" --so-pin "${PIN}" --pin "${PIN}"
echo "Token initialized successfully"

echo "Generating HMAC keys..."
/opt/eduid/fastapi/bin/python3 /opt/eduid/python scripts/generate_hmac_keys.py
