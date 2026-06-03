#!/usr/bin/env bash
set -euo pipefail

RELEASE_SET=""
APT_REPO_BASE_URL="${APT_REPO_BASE_URL:-https://xgc2.apt.xiaokang.ink}"
DISTRIBUTION="${APT_REPO_DISTRIBUTION:-focal}"
COMPONENT="${APT_REPO_COMPONENT:-main}"
ARCH="${ARCH:-$(dpkg --print-architecture)}"
RETRIES="${RETRIES:-20}"
SLEEP_SECONDS="${SLEEP_SECONDS:-30}"
EXTERNAL_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-set)
      RELEASE_SET="$2"
      shift 2
      ;;
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --retries)
      RETRIES="$2"
      shift 2
      ;;
    --sleep)
      SLEEP_SECONDS="$2"
      shift 2
      ;;
    --external-only)
      EXTERNAL_ONLY=true
      shift
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${RELEASE_SET}" || ! -f "${RELEASE_SET}" ]]; then
  echo "--release-set is required" >&2
  exit 1
fi

packages_url="${APT_REPO_BASE_URL%/}/dists/${DISTRIBUTION}/${COMPONENT}/binary-${ARCH}/Packages"

fetch_packages() {
  if curl -fsSL "${packages_url}" 2>/dev/null; then
    return 0
  fi
  curl -fsSL "${packages_url}.gz" | gzip -dc
}

expected_packages() {
  awk -v external_only="${EXTERNAL_ONLY}" '
    function flush() {
      if (package != "" && version != "") {
        if (external_only != "true" || local != "true") {
          print package, version
        }
      }
      package = ""
      version = ""
      local = "false"
    }
    /^  [A-Za-z0-9_]+:/ {
      flush()
      next
    }
    $1 == "local:" { local = $2 }
    $1 == "apt:" { package = $2 }
    package != "" && $1 == "version:" {
      version = $2
    }
    END { flush() }
  ' "${RELEASE_SET}"
}

tmp_packages="$(mktemp)"
cleanup() {
  rm -f "${tmp_packages}"
}
trap cleanup EXIT

attempt=1
while true; do
  if fetch_packages > "${tmp_packages}"; then
    missing=0
    while read -r package version; do
      [[ -z "${package}" ]] && continue
      if ! awk -v package="${package}" -v version="${version}" '
        $1 == "Package:" { current = $2 }
        current == package && $1 == "Version:" && $2 == version { found = 1 }
        END { exit found ? 0 : 1 }
      ' "${tmp_packages}"; then
        echo "missing ${package}=${version} for ${ARCH}" >&2
        missing=1
      fi
    done < <(expected_packages)

    if [[ "${missing}" -eq 0 ]]; then
      echo "APT release set is visible for ${ARCH}: ${RELEASE_SET}"
      exit 0
    fi
  fi

  if [[ "${attempt}" -ge "${RETRIES}" ]]; then
    echo "APT release set check failed after ${attempt} attempts for ${ARCH}" >&2
    exit 1
  fi

  echo "APT release set not ready for ${ARCH}; retry ${attempt}/${RETRIES}" >&2
  attempt=$((attempt + 1))
  sleep "${SLEEP_SECONDS}"
done
