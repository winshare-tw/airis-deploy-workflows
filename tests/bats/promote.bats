#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  GITOPS_DIR="$(mktemp -d)"
  export GITOPS_DIR

  for id in bold-7f3e calm-9a21 vivid-1234; do
    APP=airis-webapp INSTANCE="$id" HOST="$id.winshare.tw" \
      PORT=8080 IMAGE_TAG="$id" ALIAS=app \
      PROMOTE="$([ "$id" = bold-7f3e ] && echo true || echo false)" \
      scripts/render.sh
  done
}

teardown() { rm -rf "$GITOPS_DIR"; }

target_label() {
  yq eval-all 'select(.kind == "Deployment") | (.metadata.labels.latest // "ABSENT")' \
    "$GITOPS_DIR/sandboxes/airis-webapp/$1.yaml"
}

@test "promote: target gets latest=true, prior latest loses it" {
  APP=airis-webapp TARGET_INSTANCE=calm-9a21 ALIAS=app \
    scripts/promote.sh
  [ "$(target_label calm-9a21)" = 'true' ]
  [ "$(target_label bold-7f3e)" = 'ABSENT' ]
  [ "$(target_label vivid-1234)" = 'ABSENT' ]
}

@test "promote: only flips within the same alias bucket" {
  APP=airis-webapp-api INSTANCE=other-aaaa HOST=other-aaaa.winshare.tw \
    PORT=8900 IMAGE_TAG=other-aaaa ALIAS=api PROMOTE=true \
    scripts/render.sh

  APP=airis-webapp TARGET_INSTANCE=calm-9a21 ALIAS=app \
    scripts/promote.sh

  result=$(yq eval-all 'select(.kind == "Deployment") | (.metadata.labels.latest // "ABSENT")' \
    "$GITOPS_DIR/sandboxes/airis-webapp-api/other-aaaa.yaml")
  [ "$result" = 'true' ]
}

@test "promote: failure when target manifest does not exist" {
  run env APP=airis-webapp TARGET_INSTANCE=missing-xxxx ALIAS=app \
        scripts/promote.sh
  [ "$status" -ne 0 ]
  [[ "$output" =~ "does not exist" ]]
}
