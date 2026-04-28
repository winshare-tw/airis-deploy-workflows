#!/usr/bin/env bash
# scripts/new-host.sh
# Generates a unique sandbox host id from two distinct words.
# Outputs (stdout, KEY=VAL one per line):
#   HOST=<word>-<word>.<ZONE>
#   INSTANCE=<word>-<word>
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

# Two distinct words joined by dash. Falls back to allowing duplicate after
# 5 tries so a single-word WORDS_FILE doesn't infinite-loop.
random_pair() {
  local w1 w2 i
  w1=$(random_word)
  for i in 1 2 3 4 5; do
    w2=$(random_word)
    [[ "$w2" != "$w1" ]] && break
  done
  printf '%s-%s' "$w1" "$w2"
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
      id="$(random_pair)"
    fi
    candidate_collides "$id" || { printf '%s\n' "$id"; return 0; }
  done
  die "could not generate unique host after 50 attempts"
}

instance="$(generate)"
printf 'HOST=%s.%s\n' "$instance" "$ZONE"
printf 'INSTANCE=%s\n' "$instance"
