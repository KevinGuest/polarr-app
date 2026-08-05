# polarr-app

Docker / Umbrel release packaging for [Polarr](https://github.com/KevinGuest/polarr).

## Image

Built from the Polarr source repo and published to GHCR:

```
ghcr.io/kevinguest/polarr-app:latest
ghcr.io/kevinguest/polarr-app:0.1.0
```

Workflow: push to `main` (or `workflow_dispatch`) → multi-arch build from `KevinGuest/polarr` → push GHCR.

## Run

```bash
docker run --rm -p 3647:3000 \
  -v polarr-data:/data -v polarr-music:/music \
  ghcr.io/kevinguest/polarr-app:latest
```

## Umbrel

Draft package: `umbrel-package/polarr/`

Pin the published digest before store submission.

## License note

Same as Polarr — self-hosted library tooling; respect copyright laws for acquired content.
