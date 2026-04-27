#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  GITOPS_DIR="$(mktemp -d)"
  export GITOPS_DIR

  APP=airis-webapp INSTANCE=bold-7f3e HOST=bold-7f3e.winshare.tw \
    PORT=8080 IMAGE_TAG=bold-7f3e ALIAS=app PROMOTE=true \
    scripts/render.sh
  APP=airis-webapp INSTANCE=calm-9a21 HOST=calm-9a21.winshare.tw \
    PORT=8080 IMAGE_TAG=calm-9a21 ALIAS=app PROMOTE=false \
    scripts/render.sh
}

teardown() { rm -rf "$GITOPS_DIR"; }

@test "destroy: removes a non-latest sandbox manifest" {
  HOST=calm-9a21.winshare.tw scripts/destroy.sh
  [ ! -f "$GITOPS_DIR/sandboxes/airis-webapp/calm-9a21.yaml" ]
  [   -f "$GITOPS_DIR/sandboxes/airis-webapp/bold-7f3e.yaml" ]
}

@test "destroy: refuses to remove a latest=true sandbox without FORCE" {
  run env HOST=bold-7f3e.winshare.tw scripts/destroy.sh
  [ "$status" -ne 0 ]
  [[ "$output" =~ "is currently latest" ]]
  [ -f "$GITOPS_DIR/sandboxes/airis-webapp/bold-7f3e.yaml" ]
}

@test "destroy: removes latest=true sandbox when FORCE=1" {
  FORCE=1 HOST=bold-7f3e.winshare.tw scripts/destroy.sh
  [ ! -f "$GITOPS_DIR/sandboxes/airis-webapp/bold-7f3e.yaml" ]
}

@test "destroy: errors clearly when host is not found anywhere" {
  run env HOST=ghost-zzzz.winshare.tw scripts/destroy.sh
  [ "$status" -ne 0 ]
  [[ "$output" =~ "no manifest found" ]]
}
