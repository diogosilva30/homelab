#!/bin/bash
set -euo pipefail

# Usage:
#   ./hack/edit-sealed-secret.sh [--cluster] [--private-key private.key] [--cert sealed-secrets.crt] <path-to-sealed-secret.yaml>
#
# Modes:
# 1) Default (offline mode): decrypts SealedSecret using private key, edits it, and re-seals using a cert
#    (or a temporary self-signed cert generated from the same private key).
# 2) Cluster mode (--cluster): reads live Secret from cluster, edits it, and re-seals via controller.

usage() {
  echo "Usage: $0 [--cluster] [--private-key private.key] [--cert sealed-secrets.crt] <path-to-sealed-secret.yaml>"
}

OFFLINE=true
PRIVATE_KEY="private.key"
CERT_FILE=""
SEALED_FILE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --offline)
      OFFLINE=true
      shift
      ;;
    --cluster)
      OFFLINE=false
      shift
      ;;
    --private-key)
      PRIVATE_KEY="${2:-}"
      shift 2
      ;;
    --cert)
      CERT_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      SEALED_FILE="$1"
      shift
      ;;
  esac
done

if [ -z "$SEALED_FILE" ]; then
  usage
  exit 1
fi

if [ ! -f "$SEALED_FILE" ]; then
  echo "Error: file '$SEALED_FILE' not found."
  exit 1
fi

# Ensure required tools are available
for cmd in kubeseal yq python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found in PATH."
    exit 1
  fi
done

if [ "$OFFLINE" = false ] && ! command -v kubectl &>/dev/null; then
  echo "Error: 'kubectl' is required in cluster mode. Use --offline if you don't have cluster access."
  exit 1
fi

if [ "$OFFLINE" = true ]; then
  if [ ! -f "$PRIVATE_KEY" ]; then
    echo "Error: private key '$PRIVATE_KEY' not found."
    exit 1
  fi
fi

CONTROLLER_NAME="sealed-secrets"
CONTROLLER_NS="sealed-secrets"

SECRET_NAME=$(yq '.metadata.name' "$SEALED_FILE")
SECRET_NS=$(yq '.metadata.namespace // "default"' "$SEALED_FILE")
CLUSTER_WIDE=$(yq '.metadata.annotations."sealedsecrets.bitnami.com/cluster-wide" // "false"' "$SEALED_FILE")

PLAIN_FILE=$(mktemp /tmp/secret-XXXXXX.yaml)
TMP_CERT=""
TMP_KEY_DIR=""
cleanup() {
  if [ -n "$PLAIN_FILE" ] && [ -f "$PLAIN_FILE" ]; then
    echo "" > "$PLAIN_FILE" 2>/dev/null || true
    command rm -f "$PLAIN_FILE" 2>/dev/null || true
  fi
  if [ -n "$TMP_CERT" ] && [ -f "$TMP_CERT" ]; then
    command rm -f "$TMP_CERT" 2>/dev/null || true
  fi
  if [ -n "$TMP_KEY_DIR" ] && [ -d "$TMP_KEY_DIR" ]; then
    command rm -rf "$TMP_KEY_DIR" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [ "$OFFLINE" = true ]; then
  echo "Decrypting SealedSecret offline using '$PRIVATE_KEY'..."
  if ! kubeseal --recovery-unseal --recovery-private-key "$PRIVATE_KEY" < "$SEALED_FILE" > "$PLAIN_FILE"; then
    echo "Primary key could not decrypt. Checking for rotated controller keys in cluster..."
    if command -v kubectl &>/dev/null; then
      TMP_KEY_DIR=$(mktemp -d /tmp/sealed-keys-XXXXXX)
      KEY_LIST="$PRIVATE_KEY"

      while IFS= read -r secret_name; do
        [ -z "$secret_name" ] && continue
        out_file="$TMP_KEY_DIR/$secret_name.key"
        if kubectl get secret "$secret_name" -n "$CONTROLLER_NS" -o jsonpath='{.data.tls\.key}' 2>/dev/null | base64 -d > "$out_file"; then
          KEY_LIST="$KEY_LIST,$out_file"
        fi
      done < <(kubectl get secrets -n "$CONTROLLER_NS" -o jsonpath='{range .items[?(@.type=="kubernetes.io/tls")]}{.metadata.name}{"\n"}{end}' 2>/dev/null)

      if ! kubeseal --recovery-unseal --recovery-private-key "$KEY_LIST" < "$SEALED_FILE" > "$PLAIN_FILE"; then
        echo "Error: no available key could decrypt this SealedSecret."
        echo "Try: $0 --cluster $SEALED_FILE"
        exit 1
      fi
    else
      echo "Error: no key could decrypt and kubectl is unavailable for rotated-key fallback."
      echo "Try with the matching private key or use --cluster."
      exit 1
    fi
  fi
else
  echo "Fetching live Secret '$SECRET_NAME' from namespace '$SECRET_NS'..."
  kubectl get secret "$SECRET_NAME" -n "$SECRET_NS" -o yaml \
    | yq 'del(.metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.managedFields, .metadata.ownerReferences, .metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"])' \
    > "$PLAIN_FILE"
fi

# Convert base64 .data to plaintext .stringData for easy editing
python3 -c "
import yaml, base64

with open('$PLAIN_FILE') as f:
    doc = yaml.safe_load(f)

data = doc.pop('data', {}) or {}
string_data = {}
for k, v in data.items():
    try:
        string_data[k] = base64.b64decode(v).decode()
    except Exception:
        string_data[k] = v

doc['stringData'] = string_data
doc.setdefault('metadata', {})
annotations = doc['metadata'].setdefault('annotations', {})
if '$CLUSTER_WIDE' == 'true':
    annotations['sealedsecrets.bitnami.com/cluster-wide'] = 'true'

with open('$PLAIN_FILE', 'w') as f:
    yaml.dump(doc, f, default_flow_style=False, sort_keys=False)
"

CHECKSUM_BEFORE=$(shasum "$PLAIN_FILE" | cut -d' ' -f1)

if [ -n "${EDITOR:-}" ]; then
  echo "Opening secret in $EDITOR..."
  "$EDITOR" "$PLAIN_FILE"
else
  echo "Opening secret in code --wait..."
  code --wait "$PLAIN_FILE"
fi

CHECKSUM_AFTER=$(shasum "$PLAIN_FILE" | cut -d' ' -f1)
if [ "$CHECKSUM_BEFORE" = "$CHECKSUM_AFTER" ]; then
  echo "No changes detected. Aborting."
  exit 0
fi

echo "Re-sealing secret..."
if [ -n "$CERT_FILE" ]; then
  kubeseal --cert "$CERT_FILE" --format yaml < "$PLAIN_FILE" > "$SEALED_FILE"
elif [ "$OFFLINE" = true ]; then
  if ! command -v openssl &>/dev/null; then
    echo "Error: 'openssl' is required for offline reseal without --cert."
    exit 1
  fi
  TMP_CERT=$(mktemp /tmp/sealed-secrets-cert-XXXXXX.pem)
  openssl req -x509 -key "$PRIVATE_KEY" -out "$TMP_CERT" -days 3650 -subj "/CN=sealed-secrets-recovery" >/dev/null 2>&1
  kubeseal --cert "$TMP_CERT" --format yaml < "$PLAIN_FILE" > "$SEALED_FILE"
else
  kubeseal \
    --controller-name "$CONTROLLER_NAME" \
    --controller-namespace "$CONTROLLER_NS" \
    --scope cluster-wide \
    --format yaml \
    < "$PLAIN_FILE" \
    > "$SEALED_FILE"
fi

echo "Done! Updated: $SEALED_FILE"
