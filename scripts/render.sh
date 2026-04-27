#!/usr/bin/env bash
# scripts/render.sh
# Renders the airis-sandbox chart for one sandbox and writes the manifest into
# a checked-out airis-gitops working tree. Caller is responsible for committing.
#
# Inputs (env):
#   APP, INSTANCE, HOST, PORT, HEALTH_PATH, ALIAS, PROMOTE, TTL, IMAGE_TAG,
#   IMAGE_REGISTRY, RES_CPU, RES_MEM, GITOPS_DIR
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

for v in APP INSTANCE HOST PORT IMAGE_TAG GITOPS_DIR; do
  require_env "$v"
done

CHART_DIR="$SCRIPT_DIR/../chart/airis-sandbox"
EXPIRES_AT="$(rfc3339_plus "${TTL:-7d}")"
OUT_DIR="$GITOPS_DIR/sandboxes/$APP"
OUT_FILE="$OUT_DIR/$INSTANCE.yaml"

mkdir -p "$OUT_DIR"

helm template "$CHART_DIR" \
  --set "app=$APP" \
  --set "instance=$INSTANCE" \
  --set "host=$HOST" \
  --set "port=$PORT" \
  --set "healthPath=${HEALTH_PATH:-/}" \
  --set "alias=${ALIAS:-}" \
  --set "promote=${PROMOTE:-true}" \
  --set "expiresAt=$EXPIRES_AT" \
  --set "image.registry=${IMAGE_REGISTRY:-ghcr.io/winshare-tw}" \
  --set "image.tag=$IMAGE_TAG" \
  --set "resources.cpu=${RES_CPU:-500m}" \
  --set "resources.memory=${RES_MEM:-512Mi}" \
  > "$OUT_FILE"

log "rendered: $OUT_FILE"
log "expires-at: $EXPIRES_AT"
log "host: $HOST"
