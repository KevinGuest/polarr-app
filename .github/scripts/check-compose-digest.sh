#!/usr/bin/env bash
# Resolve each digest-pinned ghcr.io image in the Umbrel compose file and
# fail when the anonymous registry digest for that tag differs from the pin.
set -euo pipefail

compose_file=${1:-polarr-app/docker-compose.yml}
accept='application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json'

if [[ ! -f "$compose_file" ]]; then
  echo "error: compose file not found: $compose_file" >&2
  exit 1
fi

lookup_digest() {
  local repo=$1 tag=$2
  local manifest_url="https://ghcr.io/v2/${repo}/manifests/${tag}"
  local challenge realm service scope token headers http digest

  challenge=$(curl -sS -D - -o /dev/null "$manifest_url" | tr -d '\r' || true)
  realm=$(printf '%s\n' "$challenge" | sed -n 's/.*realm="\([^"]*\)".*/\1/p' | head -n 1)
  service=$(printf '%s\n' "$challenge" | sed -n 's/.*service="\([^"]*\)".*/\1/p' | head -n 1)
  scope=$(printf '%s\n' "$challenge" | sed -n 's/.*scope="\([^"]*\)".*/\1/p' | head -n 1)
  if [[ -z "$realm" || -z "$service" || -z "$scope" ]]; then
    echo "error: GHCR did not offer an anonymous token challenge for ghcr.io/${repo}:${tag}" >&2
    return 1
  fi

  token=$(
    curl -fsSL --get "$realm" \
      --data-urlencode "service=${service}" \
      --data-urlencode "scope=${scope}" \
      | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("token") or d.get("access_token") or "")'
  )
  if [[ -z "$token" ]]; then
    echo "error: anonymous GHCR token request failed for ghcr.io/${repo}:${tag}" >&2
    return 1
  fi

  headers=$(
    curl -sS -D - -o /dev/null \
      -H "Authorization: Bearer ${token}" \
      -H "Accept: ${accept}" \
      "$manifest_url" | tr -d '\r' || true
  )
  http=$(printf '%s\n' "$headers" | awk 'BEGIN{IGNORECASE=1} /^HTTP/{code=$2} END{print code}')
  digest=$(printf '%s\n' "$headers" | awk 'BEGIN{IGNORECASE=1} /^docker-content-digest:/{print $2; exit}')
  if [[ "$http" != "200" || -z "$digest" ]]; then
    echo "error: anonymous manifest lookup for ghcr.io/${repo}:${tag} failed (HTTP ${http:-unknown})" >&2
    return 1
  fi
  printf '%s\n' "$(printf '%s' "$digest" | tr '[:upper:]' '[:lower:]')"
}

found=0
status=0

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ ! "$line" =~ ^[[:space:]]*image:[[:space:]]*(.*)$ ]]; then
    continue
  fi
  ref=${BASH_REMATCH[1]}
  ref=${ref%%#*}
  ref=${ref%"${ref##*[![:space:]]}"}
  ref=${ref#"${ref%%[![:space:]]*}"}
  ref=${ref#\"}
  ref=${ref%\"}
  ref=${ref#\'}
  ref=${ref%\'}
  if [[ -z "$ref" ]]; then
    continue
  fi
  found=1

  if [[ ! "$ref" =~ ^ghcr\.io/([a-z0-9._/-]+):([A-Za-z0-9._-]+)@sha256:([a-fA-F0-9]{64})$ ]]; then
    echo "error: ${compose_file} image must be ghcr.io/<repo>:<tag>@sha256:<digest>, got: ${ref}" >&2
    status=1
    continue
  fi

  repo=${BASH_REMATCH[1]}
  tag=${BASH_REMATCH[2]}
  pinned="sha256:$(printf '%s' "${BASH_REMATCH[3]}" | tr '[:upper:]' '[:lower:]')"
  if ! actual=$(lookup_digest "$repo" "$tag"); then
    status=1
    continue
  fi
  if [[ "$actual" != "$pinned" ]]; then
    echo "error: ghcr.io/${repo}:${tag} digest mismatch" >&2
    echo "  pinned:   ${pinned}" >&2
    echo "  registry: ${actual}" >&2
    status=1
    continue
  fi
  echo "ok: ghcr.io/${repo}:${tag}@${pinned}"
done < "$compose_file"

if [[ "$found" -eq 0 ]]; then
  echo "error: no image references in ${compose_file}" >&2
  exit 1
fi

exit "$status"
