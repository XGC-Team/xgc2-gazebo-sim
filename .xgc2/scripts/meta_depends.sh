#!/usr/bin/env bash
set -euo pipefail

MODE="locked"
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

if [[ "${MODE}" != "locked" && "${MODE}" != "latest" ]]; then
  echo "--mode must be locked or latest" >&2
  exit 1
fi

if [[ "${MODE}" == "locked" && ( -z "${RELEASE_SET}" || ! -f "${RELEASE_SET}" ) ]]; then
  echo "--release-set is required for locked mode" >&2
  exit 1
fi

packages=(
  ros-noetic-xgc2-gazebo-sim-manager
  ros-noetic-xgc2-gazebo-sim-vrpn-bridge
  ros-noetic-xgc2-gazebo-sim-scout
  ros-noetic-xgc2-gazebo-sim-px4-1-12
  ros-noetic-xgc2-gazebo-sim-px4-1-14
  ros-noetic-xgc2-gazebo-sim-fs150-sitl
)

release_version_for() {
  local package="$1"
  awk -v package="${package}" '
    $1 == "apt:" && $2 == package {
      in_package = 1
      next
    }
    in_package && $1 == "version:" {
      print $2
      exit
    }
    in_package && $1 ~ /^[A-Za-z0-9_]+:$/ {
      in_package = 0
    }
  ' "${RELEASE_SET}"
}

depends=()
for package in "${packages[@]}"; do
  if [[ "${MODE}" == "locked" ]]; then
    version="$(release_version_for "${package}")"
    if [[ -z "${version}" ]]; then
      echo "missing locked version for ${package} in ${RELEASE_SET}" >&2
      exit 1
    fi
    depends+=("${package} (= ${version})")
  else
    depends+=("${package}")
  fi
done

depends+=("ros-noetic-vrpn-client-ros")

joined=""
for depends_entry in "${depends[@]}"; do
  if [[ -n "${joined}" ]]; then
    joined+=", "
  fi
  joined+="${depends_entry}"
done

printf '%s\n' "${joined}"
