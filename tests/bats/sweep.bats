#!/usr/bin/env bats

# Render two sandboxes with explicit expires-at, then exercise sweep.sh
# against frozen-time NOW values.
setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  GITOPS_DIR="$(mktemp -d)"
  export GITOPS_DIR APP=airis-webapp

  # The "current" instance — the one a render just produced. expires-at is
  # in the future relative to the NOW we'll feed sweep.sh below.
  APP=$APP INSTANCE=fresh-aaaa HOST=fresh-aaaa.winshare.tw \
    PORT=8080 IMAGE_TAG=fresh-aaaa ALIAS=app PROMOTE=true TTL=7d \
    scripts/render.sh

  # A sibling sandbox with an expires-at well in the past (forced via TTL=-30d
  # would require negative arithmetic; instead, render with short TTL then
  # rewrite the annotation to a fixed past stamp via yq).
  APP=$APP INSTANCE=stale-bbbb HOST=stale-bbbb.winshare.tw \
    PORT=8080 IMAGE_TAG=stale-bbbb ALIAS=app PROMOTE=false TTL=7d \
    scripts/render.sh
  yq -i '(select(.kind == "Deployment") | .metadata.annotations["airis.winshare.tw/expires-at"]) = "2020-01-01T00:00:00Z"' \
    "$GITOPS_DIR/sandboxes/$APP/stale-bbbb.yaml"
}

teardown() { rm -rf "$GITOPS_DIR"; }

@test "sweep: removes a sandbox whose expires-at is in the past" {
  NOW=2026-05-08T00:00:00Z APP=airis-webapp INSTANCE=fresh-aaaa \
    scripts/sweep.sh
  [ ! -f "$GITOPS_DIR/sandboxes/airis-webapp/stale-bbbb.yaml" ]
  [   -f "$GITOPS_DIR/sandboxes/airis-webapp/fresh-aaaa.yaml" ]
}

@test "sweep: never touches the INSTANCE just rendered" {
  # Even with a NOW past every expires-at, the current INSTANCE is preserved.
  NOW=2099-01-01T00:00:00Z APP=airis-webapp INSTANCE=fresh-aaaa \
    scripts/sweep.sh
  [ -f "$GITOPS_DIR/sandboxes/airis-webapp/fresh-aaaa.yaml" ]
}

@test "sweep: leaves a sandbox whose expires-at is still in the future" {
  # Pick a NOW before stale-bbbb's rewritten expires-at.
  NOW=2019-01-01T00:00:00Z APP=airis-webapp INSTANCE=fresh-aaaa \
    scripts/sweep.sh
  [ -f "$GITOPS_DIR/sandboxes/airis-webapp/stale-bbbb.yaml" ]
}

@test "sweep: ignores a manifest with no expires-at annotation" {
  # Strip the annotation entirely from stale-bbbb; it should not be deleted
  # because we don't know when it expires.
  yq -i 'del(select(.kind == "Deployment") | .metadata.annotations["airis.winshare.tw/expires-at"])' \
    "$GITOPS_DIR/sandboxes/$APP/stale-bbbb.yaml"
  NOW=2099-01-01T00:00:00Z APP=airis-webapp INSTANCE=fresh-aaaa \
    scripts/sweep.sh
  [ -f "$GITOPS_DIR/sandboxes/airis-webapp/stale-bbbb.yaml" ]
}

@test "sweep: writes swept count to GITHUB_OUTPUT when set" {
  out_file="$(mktemp)"
  GITHUB_OUTPUT="$out_file" \
    NOW=2026-05-08T00:00:00Z APP=airis-webapp INSTANCE=fresh-aaaa \
    scripts/sweep.sh
  grep -qx 'swept=1' "$out_file"
  rm -f "$out_file"
}

@test "sweep: empty app dir is a no-op (zero swept)" {
  rm -rf "$GITOPS_DIR/sandboxes/$APP"
  mkdir -p "$GITOPS_DIR/sandboxes/$APP"
  out_file="$(mktemp)"
  GITHUB_OUTPUT="$out_file" \
    NOW=2099-01-01T00:00:00Z APP=airis-webapp INSTANCE=ghost-zzzz \
    scripts/sweep.sh
  grep -qx 'swept=0' "$out_file"
  rm -f "$out_file"
}
