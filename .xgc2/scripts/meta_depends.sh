#!/usr/bin/env bash
set -euo pipefail

MODE="compatible"
RELEASE_SET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --release-set)
      RELEASE_SET="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "${MODE}" != "compatible" && "${MODE}" != "latest" ]]; then
  echo "--mode must be compatible or latest" >&2
  exit 1
fi

if [[ -z "${RELEASE_SET}" || ! -f "${RELEASE_SET}" ]]; then
  echo "--release-set is required" >&2
  exit 1
fi

depends=()
while read -r package version; do
  [[ -z "${package}" ]] && continue
  depends+=("${package} (>= ${version})")
done < <(
  awk '
    function flush() {
      if (package != "" && version != "" && local != "true") {
        print package, version
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
    package != "" && $1 == "version:" { version = $2 }
    END { flush() }
  ' "${RELEASE_SET}"
)

depends+=("ros-noetic-vrpn-client-ros")

joined=""
for depends_entry in "${depends[@]}"; do
  if [[ -n "${joined}" ]]; then
    joined+=", "
  fi
  joined+="${depends_entry}"
done

printf '%s\n' "${joined}"
