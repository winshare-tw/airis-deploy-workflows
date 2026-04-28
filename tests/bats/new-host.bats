#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "new-host: outputs HOST=<word>-<word>.<zone>" {
  run env ZONE=winshare.tw scripts/new-host.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ HOST=[a-z]+-[a-z]+\.winshare\.tw ]]
}

@test "new-host: outputs INSTANCE=<word>-<word>" {
  run env ZONE=winshare.tw scripts/new-host.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ INSTANCE=[a-z]+-[a-z]+ ]]
}

@test "new-host: emits machine-readable KEY=VAL lines (one per output)" {
  run env ZONE=winshare.tw scripts/new-host.sh
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | grep -c '=')" -ge 2 ]
}

@test "new-host: respects WORDS_FILE override (two distinct words)" {
  tmp=$(mktemp)
  printf 'alpha\nbeta\n' > "$tmp"
  run env ZONE=winshare.tw WORDS_FILE="$tmp" scripts/new-host.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ HOST=(alpha-beta|beta-alpha)\.winshare\.tw ]]
  rm -f "$tmp"
}

@test "new-host: avoids existing instance file in AVOID_DIR" {
  tmpdir=$(mktemp -d)
  words=$(mktemp)
  printf 'alpha\nbeta\ngamma\n' > "$words"
  mkdir -p "$tmpdir"
  touch "$tmpdir/alpha-beta.yaml"
  run env ZONE=winshare.tw WORDS_FILE="$words" AVOID_DIR="$tmpdir" \
      RANDOMNESS_SEED=alpha-beta scripts/new-host.sh
  [ "$status" -eq 0 ]
  hostpath=$(echo "$output" | awk -F= '/^INSTANCE=/{print $2}')
  [ ! -f "$tmpdir/$hostpath.yaml" ]
  rm -rf "$tmpdir" "$words"
}
