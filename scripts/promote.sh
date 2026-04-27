#!/usr/bin/env bash
# scripts/promote.sh
# Flips latest=true label across rendered manifests of one app.
#
# Inputs (env):
#   APP             (required)
#   TARGET_INSTANCE (required)  the instance to promote (= file basename without .yaml)
#   ALIAS           (required)  e.g. app, api  — also written as `alias=` label
#   GITOPS_DIR      (required)  checked-out airis-gitops worktree
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

for v in APP TARGET_INSTANCE ALIAS GITOPS_DIR; do
  require_env "$v"
done

target_file="$GITOPS_DIR/sandboxes/$APP/$TARGET_INSTANCE.yaml"
[[ -f "$target_file" ]] || die "target manifest does not exist: $target_file"

shopt -s nullglob
for f in "$GITOPS_DIR/sandboxes/$APP/"*.yaml; do
  yq -i '(. | select(.kind == "Deployment").metadata.labels) |= with_entries(select(.key != "latest" and .key != "alias"))' "$f"
  yq -i '(. | select(.kind == "Deployment").spec.template.metadata.labels) |= with_entries(select(.key != "latest" and .key != "alias"))' "$f"
done

yq -i "(. | select(.kind == \"Deployment\").metadata.labels.latest) = \"true\"" "$target_file"
yq -i "(. | select(.kind == \"Deployment\").metadata.labels.alias)  = \"$ALIAS\"" "$target_file"
yq -i "(. | select(.kind == \"Deployment\").spec.template.metadata.labels.latest) = \"true\"" "$target_file"
yq -i "(. | select(.kind == \"Deployment\").spec.template.metadata.labels.alias)  = \"$ALIAS\"" "$target_file"

log "promoted: $APP/$TARGET_INSTANCE (alias=$ALIAS)"
