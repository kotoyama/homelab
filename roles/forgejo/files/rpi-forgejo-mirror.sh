#!/usr/bin/env bash
set -euo pipefail

# required env vars
: "${FORGEJO_ORG:?}"
: "${FORGEJO_URL:?}"
: "${FORGEJO_TOKEN:?}"
: "${GITHUB_TOKEN:?}"
: "${FORGEJO_EXT_ORG:?}"
FORGEJO_EXT_MIRRORS="${FORGEJO_EXT_MIRRORS:-}"

page_tmp="$(mktemp)"
resp_tmp="$(mktemp)"

# always remove temp files
trap 'rm -f "$page_tmp" "$resp_tmp"' EXIT

echo "▶️ Starting Forgejo mirror seeding..."

forgejo_post() {
  # status -> stdout, response body -> $resp_tmp
  curl --silent --show-error --max-time 600 \
    --header "Authorization: token ${FORGEJO_TOKEN}" \
    --header "Content-Type: application/json" \
    --output "$resp_tmp" \
    --write-out '%{http_code}' \
    --request POST \
    --data "$2" \
    "${FORGEJO_URL}/api/v1${1}"
}

github_get() {
  curl --silent --show-error --max-time 60 \
    --header "Authorization: Bearer ${GITHUB_TOKEN}" \
    --header "Accept: application/vnd.github+json" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    --output "$page_tmp" \
    --write-out '%{http_code}' \
    "$1"
}

ensure_org() {
  local org="$1" status
  status="$(forgejo_post "/orgs" "$(jq -n --arg username "$org" '{username: $username}')")" || status=000
  if [ "$status" = 201 ]; then
    echo "ℹ️ Created organization ${org}"
  elif [ "$status" = 422 ] && jq -er '.message | test("already exist")' "$resp_tmp" >/dev/null; then
    echo "ℹ️ Organization ${org} already exists"
  else
    echo "❌ ERROR: Failed to create organization ${org} (HTTP ${status})" >&2
    cat "$resp_tmp" >&2
    exit 1
  fi
}

migrate_repo() {
  local status
  status="$(forgejo_post "/repos/migrate" "$1")" || status=000
  case "$status" in
    201)
      echo "ℹ️ Mirrored ${2}"
      created=$((created + 1))
      # give the Pi breathing room between initial clones
      sleep 5
      ;;
    409)
      echo "ℹ️ Already mirrored: ${2}"
      skipped=$((skipped + 1))
      ;;
    *)
      echo "❌ ERROR: Failed to mirror ${2} (HTTP ${status})" >&2
      cat "$resp_tmp" >&2
      failed=$((failed + 1))
      ;;
  esac
}

ensure_org "$FORGEJO_ORG"

if [ -n "$FORGEJO_EXT_MIRRORS" ]; then
  ensure_org "$FORGEJO_EXT_ORG"
fi

created=0
skipped=0
failed=0
page=1

# pull mirrors of your own GitHub repositories; forks are skipped
while :; do
  status="$(github_get "https://api.github.com/user/repos?affiliation=owner&visibility=all&per_page=100&page=${page}")" || status=000
  if [ "$status" != "200" ]; then
    echo "❌ ERROR: Failed to list GitHub repositories (page ${page}, HTTP ${status})" >&2
    cat "$page_tmp" >&2
    exit 1
  fi
  count="$(jq 'length' "$page_tmp")"
  if [ "$count" -eq 0 ]; then
    break
  fi

  while IFS=$'\t' read -r name private html_url; do
    payload="$(jq -n \
      --arg clone_addr "$html_url" \
      --arg repo_name "$name" \
      --arg repo_owner "$FORGEJO_ORG" \
      --arg service "github" \
      --arg auth_token "$GITHUB_TOKEN" \
      --argjson private "$private" \
      '{clone_addr: $clone_addr, repo_name: $repo_name, repo_owner: $repo_owner,
        mirror: true, private: $private, service: $service, auth_token: $auth_token}')"
    migrate_repo "$payload" "$name"
  done < <(jq -r '.[] | select(.fork == false) | [.name, (.private | tostring), .html_url] | @tsv' "$page_tmp")

  if [ "$count" -lt 100 ]; then
    break
  fi
  page=$((page + 1))
done

# pull mirrors of third-party public repositories
for url in $FORGEJO_EXT_MIRRORS; do
  name="$(basename "$url" .git)"
  payload="$(jq -n \
    --arg clone_addr "$url" \
    --arg repo_name "$name" \
    --arg repo_owner "$FORGEJO_EXT_ORG" \
    '{clone_addr: $clone_addr, repo_name: $repo_name, repo_owner: $repo_owner,
      mirror: true, private: false}')"
  migrate_repo "$payload" "${FORGEJO_EXT_ORG}/${name} (${url})"
done

if [ "$failed" -eq 0 ]; then
  echo "✅ OK: Done: ${created} created, ${skipped} skipped, ${failed} failed"
else
  echo "❌ ERROR: Done: ${created} created, ${skipped} skipped, ${failed} failed"
  # non-zero exit so systemd flags the run as failed
  exit 1
fi
