#!/bin/bash
set -e

if [ -z "$FRONTEND_BUCKET" ]; then
  echo "Error: FRONTEND_BUCKET environment variable is required"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/frontend"

export VITE_APP_API_ENDPOINT="${VITE_APP_API_ENDPOINT}"
export VITE_APP_WS_ENDPOINT="${VITE_APP_WS_ENDPOINT:-}"
export VITE_APP_USER_POOL_ID="${VITE_APP_USER_POOL_ID}"
export VITE_APP_USER_POOL_CLIENT_ID="${VITE_APP_USER_POOL_CLIENT_ID}"
export VITE_APP_REGION="${VITE_APP_REGION}"
export VITE_APP_USE_STREAMING="${VITE_APP_USE_STREAMING:-false}"

npm install
npm run build
aws s3 sync dist/ s3://${FRONTEND_BUCKET}/ --delete

echo "Frontend deployed successfully to s3://${FRONTEND_BUCKET}/"
