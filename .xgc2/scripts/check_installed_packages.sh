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

check_min_version ros-noetic-xgc2-gazebo-scene 1.1.0-33
check_min_version ros-noetic-xgc2-gazebo-sim-mecanum 0.1.0-1
check_min_version ros-noetic-xgc2-robot-visualization 0.1.0-1
check_min_version ros-noetic-xgc2-gazebo-sim-visualization 1.1.0-12
check_min_version ros-noetic-xgc2-gazebo-sim-vrpn-bridge 1.1.0-16
check_min_version ros-noetic-xgc2-gazebo-sim-worlds 1.1.0-14
check_min_version ros-noetic-xgc2-gazebo-sim-scout 0.4.9-25
check_min_version ros-noetic-xgc2-gazebo-sim-px4-1-12 1.12.3-11
check_min_version ros-noetic-xgc2-gazebo-sim-px4-1-14 1.14.4-10
check_min_version ros-noetic-xgc2-gazebo-sim-fs150-sitl 1.1.0-13

test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/empty/empty.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/clearpath_playpen/clearpath_playpen.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/worlds/corridor_dynamic_9/corridor_dynamic_9.world"
test -f "/opt/ros/noetic/share/gazebo_sim_worlds/models/corridor/model.sdf"
test -f "/opt/ros/noetic/lib/libxgc2_gazebo_scene_system.so"
test -f "/opt/ros/noetic/lib/libgazebo_sim_mecanum_contract.so"
test -f "/opt/ros/noetic/share/gazebo_sim_mecanum/models/xgc2_mecanum_ugv/model.sdf"
roslaunch --files gazebo_sim_mecanum simple.launch gui:=false >/tmp/xgc2-mecanum-simple-files.txt

echo "Installed Gazebo simulation suite check passed"
