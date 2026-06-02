#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT=""
OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-noetic}"
VERSION="${PACKAGE_VERSION:-1.0.0-1}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root)
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${INSTALL_ROOT}" || -z "${OUTPUT_DIR}" ]]; then
  echo "--install-root and --output-dir are required" >&2
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
PREFIX="/opt/ros/${ROS_DISTRO}"
PREFIX_ROOT="${INSTALL_ROOT}${PREFIX}"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}"/*.deb

copy_path() {
  local src="$1"
  local dst_root="$2"
  if [[ -e "${src}" ]]; then
    mkdir -p "${dst_root}$(dirname "${src#${INSTALL_ROOT}}")"
    cp -a "${src}" "${dst_root}${src#${INSTALL_ROOT}}"
  fi
}

write_control() {
  local pkg_root="$1"
  local package="$2"
  local depends="$3"
  local description="$4"

  mkdir -p "${pkg_root}/DEBIAN" "${pkg_root}/usr/share/doc/${package}"
  cat > "${pkg_root}/DEBIAN/control" <<EOF
Package: ${package}
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: ${ARCH}
Maintainer: XGC2 <apt@example.com>
Depends: ${depends}
Description: ${description}
EOF
  printf '%s package\n' "${package}" > "${pkg_root}/usr/share/doc/${package}/README"
  chmod 0755 "${pkg_root}/DEBIAN"
}

copy_ros_package_paths() {
  local ros_pkg="$1"
  local dst_root="$2"

  copy_path "${PREFIX_ROOT}/share/${ros_pkg}" "${dst_root}"
  copy_path "${PREFIX_ROOT}/lib/${ros_pkg}" "${dst_root}"
  copy_path "${PREFIX_ROOT}/include/${ros_pkg}" "${dst_root}"
}

copy_libs() {
  local dst_root="$1"
  shift
  local lib
  for lib in "$@"; do
    copy_path "${PREFIX_ROOT}/lib/${lib}.a" "${dst_root}"
    copy_path "${PREFIX_ROOT}/lib/${lib}.so" "${dst_root}"
  done
}

build_ros_package_deb() {
  local package="$1"
  local ros_pkg="$2"
  local depends="$3"
  local description="$4"
  shift 4

  local pkg_root="${BUILD_DIR}/${package}"
  rm -rf "${pkg_root}"
  mkdir -p "${pkg_root}"

  if [[ -n "${ros_pkg}" ]]; then
    copy_ros_package_paths "${ros_pkg}" "${pkg_root}"
  fi
  if [[ "$#" -gt 0 ]]; then
    copy_libs "${pkg_root}" "$@"
  fi

  write_control "${pkg_root}" "${package}" "${depends}" "${description}"
  fakeroot dpkg-deb --build "${pkg_root}" "${OUTPUT_DIR}/${package}_${VERSION}_${ARCH}.deb" >/dev/null
}

build_meta_deb() {
  local package="$1"
  local depends="$2"
  local description="$3"

  local pkg_root="${BUILD_DIR}/${package}"
  rm -rf "${pkg_root}"
  mkdir -p "${pkg_root}"

  write_control "${pkg_root}" "${package}" "${depends}" "${description}"
  fakeroot dpkg-deb --build "${pkg_root}" "${OUTPUT_DIR}/${package}_${VERSION}_${ARCH}.deb" >/dev/null
}

manager_pkg="ros-noetic-xgc2-gazebo-sim-manager"
vrpn_bridge_pkg="ros-noetic-xgc2-gazebo-sim-vrpn-bridge"
scout_description_pkg="ros-noetic-xgc2-scout-description"
scout_gazebo_pkg="ros-noetic-xgc2-scout-gazebo-sim"
agilex_meta_pkg="ros-noetic-xgc2-agilex"
meta_pkg="ros-noetic-xgc2-gazebo-sim"

build_ros_package_deb \
  "${vrpn_bridge_pkg}" \
  "gazebo_sim_vrpn_bridge" \
  "ros-noetic-roscpp, ros-noetic-gazebo-msgs, ros-noetic-geometry-msgs, ros-noetic-tf2, ros-noetic-tf2-ros, ros-noetic-vrpn" \
  "XGC2 Gazebo Classic model pose to VRPN tracker server bridge"

build_ros_package_deb \
  "${manager_pkg}" \
  "gazebo_session_manager" \
  "ros-noetic-rospy, ros-noetic-roslaunch, ros-noetic-rosnode, ros-noetic-gazebo-msgs, ros-noetic-gazebo-ros, ros-noetic-geometry-msgs, ros-noetic-controller-manager-msgs, ros-noetic-std-srvs, ros-noetic-vrpn-client-ros, ${vrpn_bridge_pkg} (= ${VERSION})" \
  "XGC2 Gazebo Classic session manager and WebUI tools"

build_ros_package_deb \
  "${scout_description_pkg}" \
  "scout_description" \
  "ros-noetic-urdf, ros-noetic-xacro, ros-noetic-joint-state-publisher, ros-noetic-joint-state-publisher-gui, ros-noetic-robot-state-publisher, ros-noetic-rviz" \
  "XGC2 AgileX Scout robot description"

build_ros_package_deb \
  "${scout_gazebo_pkg}" \
  "scout_gazebo_sim" \
  "${scout_description_pkg} (= ${VERSION}), ros-noetic-roscpp, ros-noetic-geometry-msgs, ros-noetic-gazebo-msgs, ros-noetic-nav-msgs, ros-noetic-sensor-msgs, ros-noetic-std-msgs, ros-noetic-tf, ros-noetic-tf2, ros-noetic-tf2-ros, ros-noetic-controller-manager, ros-noetic-gazebo-plugins, ros-noetic-gazebo-ros, ros-noetic-gazebo-ros-control, ros-noetic-joint-state-controller, ros-noetic-joint-state-publisher, ros-noetic-robot-state-publisher, ros-noetic-rostopic, ros-noetic-rviz, ros-noetic-velocity-controllers" \
  "XGC2 AgileX Scout Gazebo Classic simulation" \
  libscout_gazebo

build_meta_deb \
  "${agilex_meta_pkg}" \
  "${scout_description_pkg} (= ${VERSION}), ${scout_gazebo_pkg} (= ${VERSION})" \
  "XGC2 AgileX aggregate package"

build_meta_deb \
  "${meta_pkg}" \
  "${manager_pkg} (= ${VERSION}), ${vrpn_bridge_pkg} (= ${VERSION}), ${agilex_meta_pkg} (= ${VERSION})" \
  "XGC2 Gazebo Classic simulation aggregate package"

find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.deb' -print | sort
