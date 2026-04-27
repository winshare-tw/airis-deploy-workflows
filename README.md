# airis-deploy-workflows

Reusable GitHub Actions workflows + Helm chart for shipping AiRis services to k8s.

## Usage (consumer side)

```yaml
jobs:
  deploy:
    uses: winshare-tw/airis-deploy-workflows/.github/workflows/deploy-sandbox.yml@v1
    with:
      app: airis-webapp
      dockerfile: Dockerfile
      port: 8080
    secrets: inherit
```

See `docs/usage.md` for the full input / output / secrets reference.

## Available workflows

- `deploy-sandbox.yml` — build, push, render, commit; produces a sandbox at `<word>-<hex4>.winshare.tw`
- `promote-latest.yml` — flip the `app.winshare.tw` / `api.winshare.tw` alias to a target sandbox
- `destroy-sandbox.yml` — remove a sandbox by host

## Spec

`mingxianliu/airisclaw:docs/superpowers/specs/2026-04-27-airis-deploy-design.md`
