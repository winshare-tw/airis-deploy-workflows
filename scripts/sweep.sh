#!/usr/bin/env bash
# scripts/sweep.sh
# Removes sibling sandbox manifests in $GITOPS_DIR/sandboxes/$APP/ whose
# `airis.winshare.tw/expires-at` annotation is in the past. The manifest
# matching the current INSTANCE is always preserved (it was just rendered
# with a fresh expires-at). Caller is responsible for committing the deletes.
#
# Inputs (env):
#   APP        (required)  e.g. airis-webapp
#   INSTANCE   (required)  the sandbox just rendered; never swept
#   GITOPS_DIR (required)  path to a checked-out airis-gitops worktree
#   NOW        (optional)  RFC3339 UTC timestamp for comparison; defaults
#                          to current wall-clock UTC. Set explicitly in
#                          tests to avoid time-dependent flake.
#
# Outputs:
#   stdout — "sweeping expired: <path> (expires=<ts>)" for each removal
#   GITHUB_OUTPUT — `swept=<N>` (only when GITHUB_OUTPUT is set)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

for v in APP INSTANCE GITOPS_DIR; do
  require_env "$v"
done

now="${NOW:-$(date -u +%FT%TZ)}"
dir="$GITOPS_DIR/sandboxes/$APP"

swept=0
shopt -s nullglob
for f in "$dir"/*.yaml; do
  base=$(basename "$f" .yaml)
  # Never touch the manifest we just rendered.
  [ "$base" = "$INSTANCE" ] && continue
  expires=$(yq eval-all \
    'select(.kind == "Deployment") | .metadata.annotations["airis.winshare.tw/expires-at"] // ""' \
    "$f" | head -n1)
  # Empty / "null" → no expires-at on this manifest; leave it alone.
  [ -n "$expires" ] && [ "$expires" != "null" ] || continue
  # ISO 8601 UTC sort lexicographically; safe for string `<`.
  if [[ "$expires" < "$now" ]]; then
    echo "sweeping expired: $f (expires=$expires)"
    rm -f "$f"
    swept=$((swept + 1))
  fi
done

log "swept $swept expired manifests"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "swept=$swept" >> "$GITHUB_OUTPUT"
fi
