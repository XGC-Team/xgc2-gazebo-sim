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

packages=(
  ros-noetic-xgc2-gazebo-sim-manager
  ros-noetic-xgc2-gazebo-sim-vrpn-bridge
  ros-noetic-xgc2-gazebo-sim-scout
  ros-noetic-xgc2-gazebo-sim-px4-1-12
  ros-noetic-xgc2-gazebo-sim-px4-1-14
  ros-noetic-xgc2-gazebo-sim-fs150-sitl
)

depends=()
for package in "${packages[@]}"; do
  depends+=("${package}")
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
