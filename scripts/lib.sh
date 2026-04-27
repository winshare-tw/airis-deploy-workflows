#!/usr/bin/env bash
# scripts/lib.sh — sourced by other scripts. Do not run directly.
set -euo pipefail

log()  { printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*" >&2; }
die()  { log "FATAL: $*"; exit 1; }

require_env() {
  local name=$1
  if [[ -z "${!name:-}" ]]; then
    die "env var $name is required but not set"
  fi
}

# clone_gitops <dest_dir>
# Clones airis-gitops into the dest dir using GITOPS_TOKEN.
clone_gitops() {
  require_env GITOPS_TOKEN
  local dest=$1
  rm -rf "$dest"
  git clone --depth 1 \
    "https://x-access-token:${GITOPS_TOKEN}@github.com/winshare-tw/airis-gitops.git" \
    "$dest"
  git -C "$dest" config user.email "deploy-bot@winshare.tw"
  git -C "$dest" config user.name  "airis-deploy-bot"
}

# rfc3339_plus <ttl>
# Outputs (UTC) now + ttl in RFC3339. ttl is e.g. 7d, 24h, 90m.
rfc3339_plus() {
  local ttl=$1
  local secs
  case "$ttl" in
    *d) secs=$(( ${ttl%d} * 86400 ));;
    *h) secs=$(( ${ttl%h} * 3600  ));;
    *m) secs=$(( ${ttl%m} * 60    ));;
    *s) secs=${ttl%s};;
    *)  die "ttl must end in s/m/h/d (got: $ttl)";;
  esac
  date -u -d "+${secs} seconds" +%FT%TZ
}
