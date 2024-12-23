#!/bin/bash

# Variables
NAMESPACE="zitadel"
SECRET_NAME="zitadel-admin-sa"
OUTPUT_REL_PATH="terraform/zitadel-credentials.json"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "kubectl is not installed. Please install it to proceed."
  exit 1
fi

# Get the root directory of the current Git repository
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
  echo "This script must be run inside a Git repository."
  exit 1
fi

# Construct the output file path
OUTPUT_FILE="$GIT_ROOT/$OUTPUT_REL_PATH"

# Create the output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Extract the secret and write to the output file
kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.zitadel-admin-sa\.json}' | base64 --decode > "$OUTPUT_FILE"

# Verify if the file was created
if [ -f "$OUTPUT_FILE" ]; then
  echo "Credentials have been successfully written to $OUTPUT_FILE"
else
  echo "Failed to write credentials to $OUTPUT_FILE"
  exit 1
fi
