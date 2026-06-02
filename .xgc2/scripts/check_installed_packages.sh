#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-noetic}"
source "/opt/ros/${ROS_DISTRO}/setup.bash"

dpkg -s ros-noetic-xgc2-gazebo-sim >/dev/null
dpkg -s ros-noetic-xgc2-gazebo-sim-manager >/dev/null
dpkg -s ros-noetic-xgc2-gazebo-sim-vrpn-bridge >/dev/null
dpkg -s ros-noetic-xgc2-agilex >/dev/null
dpkg -s ros-noetic-xgc2-scout-description >/dev/null
dpkg -s ros-noetic-xgc2-scout-gazebo-sim >/dev/null
test "$(rospack find gazebo_session_manager)" = "/opt/ros/${ROS_DISTRO}/share/gazebo_session_manager"
test "$(rospack find gazebo_sim_vrpn_bridge)" = "/opt/ros/${ROS_DISTRO}/share/gazebo_sim_vrpn_bridge"
test "$(rospack find scout_description)" = "/opt/ros/${ROS_DISTRO}/share/scout_description"
test "$(rospack find scout_gazebo_sim)" = "/opt/ros/${ROS_DISTRO}/share/scout_gazebo_sim"

roslaunch --files gazebo_session_manager session_manager.launch world_name:=/tmp/xgc2-empty.world >/tmp/xgc2-gazebo-session-manager-files.txt
roslaunch --files gazebo_session_manager gzserver_vrpn.launch world_name:=/tmp/xgc2-empty.world >/tmp/xgc2-gzserver-vrpn-files.txt
roslaunch --files gazebo_sim_vrpn_bridge gazebo_vrpn_server.launch >/tmp/xgc2-gazebo-vrpn-server-files.txt
roslaunch --files scout_gazebo_sim mini_gz_classic_simple.launch rviz:=false >/tmp/xgc2-scout-gazebo-files.txt
roslaunch --files vrpn_client_ros sample.launch >/tmp/xgc2-vrpn-client-files.txt

echo "Installed package check passed"
