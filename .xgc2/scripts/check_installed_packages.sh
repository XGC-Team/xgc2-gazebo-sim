#!/usr/bin/env bash
set -euo pipefail

dpkg -s ros-noetic-xgc2-gazebo-sim-all >/dev/null

check_min_version() {
  local package="$1"
  local min_version="$2"
  dpkg -s "${package}" >/dev/null
  local installed_version
  installed_version="$(dpkg-query -W -f='${Version}' "${package}")"
  dpkg --compare-versions "${installed_version}" ge "${min_version}"
}

check_min_version ros-noetic-xgc2-gazebo-sim-manager 1.0.12-1
check_min_version ros-noetic-xgc2-gazebo-sim-examples 1.0.12-1
check_min_version ros-noetic-xgc2-gazebo-sim-vrpn-bridge 1.0.12-1
check_min_version ros-noetic-xgc2-gazebo-sim-scout 0.4.8-1
check_min_version ros-noetic-xgc2-gazebo-sim-px4-1-12 1.12.3-6
check_min_version ros-noetic-xgc2-gazebo-sim-px4-1-14 1.14.4-6
check_min_version ros-noetic-xgc2-gazebo-sim-fs150-sitl 1.0.11-1

echo "Installed Gazebo simulation suite check passed"
