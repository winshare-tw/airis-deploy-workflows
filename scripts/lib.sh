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
# Clones airis-gitops into the dest dir using GITOPS_SSH_KEY (write deploy key).
clone_gitops() {
  require_env GITOPS_SSH_KEY
  local dest=$1
  rm -rf "$dest"

  # Stash the SSH key in a 0600 file outside any git tree.
  local key_file
  key_file=$(mktemp)
  chmod 600 "$key_file"
  printf '%s\n' "$GITOPS_SSH_KEY" > "$key_file"

  # Use ssh.github.com:443 — works in environments where outbound :22 is blocked
  # (common in corporate / on-prem clusters). github.com itself works on 22, but
  # the 443 endpoint is the safer default.
  mkdir -p "$HOME/.ssh"
  ssh-keyscan -p 443 ssh.github.com 2>/dev/null >> "$HOME/.ssh/known_hosts" || true

  local SSH_CMD="ssh -i $key_file -o IdentitiesOnly=yes -o UserKnownHostsFile=$HOME/.ssh/known_hosts -o StrictHostKeyChecking=accept-new -p 443"

  GIT_SSH_COMMAND="$SSH_CMD" \
    git clone --depth 1 \
      "git@ssh.github.com:winshare-tw/airis-gitops.git" \
      "$dest"

  # Embed the same SSH command in the cloned repo's local config so subsequent
  # git push/fetch in this dir picks the deploy key without env propagation.
  git -C "$dest" config core.sshCommand "$SSH_CMD"
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
