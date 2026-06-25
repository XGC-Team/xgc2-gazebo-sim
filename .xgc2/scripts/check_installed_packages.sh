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

check_min_version ros-noetic-xgc2-gazebo-sim-manager 1.0.29-1
check_min_version ros-noetic-xgc2-gazebo-sim-examples 1.0.29-1
check_min_version ros-noetic-xgc2-gazebo-sim-vrpn-bridge 1.0.29-1
check_min_version ros-noetic-xgc2-gazebo-sim-worlds 1.0.21-1
check_min_version ros-noetic-xgc2-gazebo-sim-scout 0.4.9-1
check_min_version ros-noetic-xgc2-gazebo-sim-px4-1-12 1.12.3-7
check_min_version ros-noetic-xgc2-gazebo-sim-px4-1-14 1.14.4-6
check_min_version ros-noetic-xgc2-gazebo-sim-fs150-sitl 1.0.13-1

test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/empty/empty.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/weston_robot_empty/weston_robot_empty.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/clearpath_playpen/clearpath_playpen.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/corridor_dynamic_9/corridor_dynamic_9.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/models/corridor/model.sdf"

echo "Installed Gazebo simulation suite check passed"
