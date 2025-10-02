#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/frontend"

npm install
npm run build
aws s3 sync dist/ s3://${FRONTEND_BUCKET}/ --delete
