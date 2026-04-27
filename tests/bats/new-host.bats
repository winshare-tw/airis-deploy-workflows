#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "new-host: outputs HOST=<word>-<hex4>.<zone>" {
  run env ZONE=winshare.tw scripts/new-host.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ HOST=[a-z]{2,8}-[0-9a-f]{4}\.winshare\.tw ]]
}

@test "new-host: outputs INSTANCE=<word>-<hex4>" {
  run env ZONE=winshare.tw scripts/new-host.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ INSTANCE=[a-z]{2,8}-[0-9a-f]{4} ]]
}

@test "new-host: emits machine-readable KEY=VAL lines (one per output)" {
  run env ZONE=winshare.tw scripts/new-host.sh
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | grep -c '=')" -ge 2 ]
}

@test "new-host: respects WORDS_FILE override" {
  tmp=$(mktemp)
  echo "uniqword" > "$tmp"
  run env ZONE=winshare.tw WORDS_FILE="$tmp" scripts/new-host.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ HOST=uniqword-[0-9a-f]{4}\.winshare\.tw ]]
  rm -f "$tmp"
}

@test "new-host: avoids existing instance file in AVOID_DIR" {
  tmpdir=$(mktemp -d)
  words=$(mktemp)
  echo -e "alpha\nbeta" > "$words"
  mkdir -p "$tmpdir"
  touch "$tmpdir/alpha-aaaa.yaml"
  run env ZONE=winshare.tw WORDS_FILE="$words" AVOID_DIR="$tmpdir" \
      RANDOMNESS_SEED=alpha-aaaa scripts/new-host.sh
  [ "$status" -eq 0 ]
  hostpath=$(echo "$output" | awk -F= '/^INSTANCE=/{print $2}')
  [ ! -f "$tmpdir/$hostpath.yaml" ]
  rm -rf "$tmpdir" "$words"
}
