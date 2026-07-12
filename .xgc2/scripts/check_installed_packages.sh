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

check_min_version ros-noetic-xgc2-gazebo-sim-manager 1.1.0-23
check_min_version ros-noetic-xgc2-gazebo-sim-examples 1.1.0-23
check_min_version ros-noetic-xgc2-robot-visualization 0.1.0-1
check_min_version ros-noetic-xgc2-gazebo-sim-visualization 1.1.0-7
check_min_version ros-noetic-xgc2-gazebo-sim-vrpn-bridge 1.1.0-8
check_min_version ros-noetic-xgc2-gazebo-sim-worlds 1.1.0-8
check_min_version ros-noetic-xgc2-gazebo-sim-scout 0.4.9-8
check_min_version ros-noetic-xgc2-gazebo-sim-px4-1-12 1.12.3-11
check_min_version ros-noetic-xgc2-gazebo-sim-px4-1-14 1.14.4-10
check_min_version ros-noetic-xgc2-gazebo-sim-fs150-sitl 1.1.0-7

test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/empty/empty.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/clearpath_playpen/clearpath_playpen.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/corridor_dynamic_9/corridor_dynamic_9.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/models/corridor/model.sdf"
test -x "/opt/ros/noetic/lib/gazebo_sim_examples/uav_auto_takeoff_track.py"
rosrun gazebo_sim_examples uav_auto_takeoff_track.py --help >/tmp/xgc2-uav-auto-takeoff-track-help.txt

echo "Installed Gazebo simulation suite check passed"
