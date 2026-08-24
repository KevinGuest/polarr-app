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

When shipping a new Umbrel package release, update **all** of:

1. `polarr-app/umbrel-app.yml` → `version` + `releaseNotes`
2. `polarr-app/docker-compose.yml` → `POLARR_APP_VERSION` (must match manifest `version`)
3. `polarr-app/docker-compose.yml` → `web` image **tag and `@sha256:` digest**
   - Resolve digest: `docker buildx imagetools inspect ghcr.io/kevinguest/polarr-app:<tag>`
4. Publish the image from this repo’s `Docker image` workflow (builds source from `KevinGuest/polarr`)

## Dev notes

- App package lives in `polarr-app/` (Umbrel community store layout).
- Store root: `umbrel-app-store.yml`
- GHCR workflow: `.github/workflows/docker.yml`
