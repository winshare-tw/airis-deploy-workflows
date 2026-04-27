#!/usr/bin/env bash
# scripts/new-host.sh
# Generates a unique sandbox host id.
# Outputs (stdout, KEY=VAL one per line):
#   HOST=<word>-<hex4>.<ZONE>
#   INSTANCE=<word>-<hex4>
#
# Inputs (env):
#   ZONE             (required)   e.g. winshare.tw
#   WORDS_FILE       (optional)   newline-separated word list (default: words.txt next to this script)
#   AVOID_DIR        (optional)   dir whose `<INSTANCE>.yaml` filenames are reserved (collision avoidance)
#   RANDOMNESS_SEED  (optional)   pre-baked candidate (only honoured if it does NOT collide with AVOID_DIR)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_env ZONE
WORDS_FILE="${WORDS_FILE:-$SCRIPT_DIR/../words.txt}"
[[ -r "$WORDS_FILE" ]] || die "words file not readable: $WORDS_FILE"

random_word() {
  shuf -n1 "$WORDS_FILE"
}

random_hex() {
  openssl rand -hex 2
}

candidate_collides() {
  local id=$1
  [[ -n "${AVOID_DIR:-}" && -f "$AVOID_DIR/$id.yaml" ]]
}

generate() {
  local seed_used=0
  for _ in $(seq 1 50); do
    local id
    if [[ -n "${RANDOMNESS_SEED:-}" && $seed_used -eq 0 ]]; then
      id="$RANDOMNESS_SEED"
      seed_used=1
    else
      id="$(random_word)-$(random_hex)"
    fi
    candidate_collides "$id" || { printf '%s\n' "$id"; return 0; }
  done
  die "could not generate unique host after 50 attempts"
}

instance="$(generate)"
printf 'HOST=%s.%s\n' "$instance" "$ZONE"
printf 'INSTANCE=%s\n' "$instance"
