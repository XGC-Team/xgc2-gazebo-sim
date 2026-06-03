#!/usr/bin/env bash
set -euo pipefail

dpkg -s ros-noetic-xgc2-gazebo-sim-all >/dev/null
dpkg -s ros-noetic-xgc2-gazebo-sim-manager >/dev/null
dpkg -s ros-noetic-xgc2-gazebo-sim-vrpn-bridge >/dev/null
dpkg -s ros-noetic-xgc2-gazebo-sim-scout >/dev/null
dpkg -s ros-noetic-xgc2-gazebo-sim-px4-1-12 >/dev/null
dpkg -s ros-noetic-xgc2-gazebo-sim-px4-1-14 >/dev/null
dpkg -s ros-noetic-xgc2-gazebo-sim-fs150-sitl >/dev/null

echo "Installed Gazebo simulation suite check passed"
