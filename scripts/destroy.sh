#!/usr/bin/env bash
# scripts/destroy.sh
# Removes a sandbox manifest from gitops repo by FQDN host.
#
# Inputs (env):
#   HOST       (required)  bold-7f3e.winshare.tw
#   GITOPS_DIR (required)
#   FORCE      (optional)  set to "1" to allow destroying a latest=true sandbox
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

for v in HOST GITOPS_DIR; do
  require_env "$v"
done

instance="${HOST%%.*}"

match=""
shopt -s nullglob
for f in "$GITOPS_DIR/sandboxes/"*"/$instance.yaml"; do
  match="$f"
  break
done

[[ -n "$match" ]] || die "no manifest found for host: $HOST"

is_latest=$(yq eval-all 'select(.kind == "Deployment") | (.metadata.labels.latest // "")' "$match" | tr -d '"')
if [[ "$is_latest" == "true" && "${FORCE:-0}" != "1" ]]; then
  die "$instance is currently latest — refusing to destroy. Set FORCE=1 to override (and demote first)."
fi

rm -f "$match"
log "destroyed: $match"
