# Polarr

Self-hosted music discovery, Lidarr requests, and streaming for [Umbrel](https://umbrel.com).

Source: [`polarr`](https://github.com/KevinGuest/polarr) · Image: `ghcr.io/kevinguest/polarr-app`

## Install

1. Install the **Lidarr** app on umbrelOS (required dependency).
2. App Store → Community App Stores → add:

```
https://github.com/KevinGuest/polarr-app
```

3. Install **Polarr**.

Open Polarr from the homescreen and finish first-run setup (admin account + Lidarr URL/API key).

| Port | Service |
| --- | --- |
| **3647** | Web UI / API |

Lidarr downloads to `/downloads/music` which is host `${UMBREL_ROOT}/data/storage/downloads/music`. Polarr mounts that at `/music` and writes there too.

## What’s included

- Discover + request flow (Lidarr)
- Optional Downtify-style fallback (yt-dlp + ffmpeg in the image)
- Browser streaming and iOS companion contract (`/api/stream/:id`)
- SQLite settings / library / requests store

## Version bump checklist

When shipping a new Umbrel package release:

1. Tag [`KevinGuest/polarr`](https://github.com/KevinGuest/polarr) first (`v*`). The image workflow checks that tag out of `KevinGuest/polarr`.
2. Push the same `v*` tag on this repo. The workflow publishes `ghcr.io/kevinguest/polarr-app:<version>`. `:latest` moves only on these tags.
3. Wait for that workflow run to finish so the image tag exists on GHCR.
4. Commit the image tag and `@sha256:` digest together (they are not known as a pair until step 3):
   - `polarr-app/docker-compose.yml` → `web` image **tag and `@sha256:` digest**
     - Resolve digest: `docker buildx imagetools inspect ghcr.io/kevinguest/polarr-app:<tag>`
   - `polarr-app/docker-compose.yml` → `POLARR_APP_VERSION` (must match manifest `version`)
   - `polarr-app/umbrel-app.yml` → `version` + `releaseNotes`

PRs and pushes that change `polarr-app/docker-compose.yml`, the digest check script, or its workflow look the tag up on GHCR anonymously and fail if the `@sha256` pin does not match. The same check runs weekly. Committing the digest before step 3 pins a digest that does not exist yet.

## Dev notes

- App package lives in `polarr-app/` (Umbrel community store layout).
- Store root: `umbrel-app-store.yml`
- GHCR workflow: `.github/workflows/docker.yml`
- Compose digest check: `.github/workflows/compose-digest.yml`
