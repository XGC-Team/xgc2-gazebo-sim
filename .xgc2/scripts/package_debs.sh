#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-noetic}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
META_MODE="${GAZEBO_SIM_META_MODE:-locked}"
RELEASE_SET="${GAZEBO_SIM_RELEASE_SET:-${REPO_ROOT}/.xgc2/release-set.yml}"

product_version() {
  awk -F': *' '/^version:[[:space:]]*/ {print $2; exit}' "${REPO_ROOT}/.xgc2/product.yml"
}

VERSION="${PACKAGE_VERSION:-$(product_version)}"

if [[ -z "${VERSION}" ]]; then
  echo "package version is missing; set PACKAGE_VERSION or .xgc2/product.yml version" >&2
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root)
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

if [[ -z "${OUTPUT_DIR}" ]]; then
  echo "--output-dir is required" >&2
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}"/*.deb

write_control() {
  local pkg_root="$1"
  local package="$2"
  local depends="$3"
  local description="$4"
  local extra_fields="${5:-}"

  mkdir -p "${pkg_root}/DEBIAN" "${pkg_root}/usr/share/doc/${package}"
  {
    cat <<EOF
Package: ${package}
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: ${ARCH}
Maintainer: XGC2 <apt@example.com>
Depends: ${depends}
EOF
    if [[ -n "${extra_fields}" ]]; then
      printf '%s\n' "${extra_fields}"
    fi
    cat <<EOF
Description: ${description}
EOF
  } > "${pkg_root}/DEBIAN/control"
  printf '%s package\n' "${package}" > "${pkg_root}/usr/share/doc/${package}/README"
  chmod 0755 "${pkg_root}/DEBIAN"
}

build_meta_deb() {
  local package="$1"
  local depends="$2"
  local description="$3"
  local extra_fields="${4:-}"

  local pkg_root="${BUILD_DIR}/${package}"
  rm -rf "${pkg_root}"
  mkdir -p "${pkg_root}"

  write_control "${pkg_root}" "${package}" "${depends}" "${description}" "${extra_fields}"
  fakeroot dpkg-deb --build "${pkg_root}" "${OUTPUT_DIR}/${package}_${VERSION}_${ARCH}.deb" >/dev/null
}

copy_fs150_sitl_payload() {
  local pkg_root="$1"
  local package_share="${pkg_root}/opt/ros/${ROS_DISTRO}/share/gazebo_sim_fs150_sitl"
  local package_lib="${pkg_root}/opt/ros/${ROS_DISTRO}/lib/gazebo_sim_fs150_sitl"

  mkdir -p "${package_share}" "${package_lib}"

  cp "${REPO_ROOT}/fs150-sitl/package.xml" "${package_share}/"
  cp "${REPO_ROOT}/fs150-sitl/CMakeLists.txt" "${package_share}/"
  cp -a "${REPO_ROOT}/fs150-sitl/config" "${package_share}/"
  cp -a "${REPO_ROOT}/fs150-sitl/launch" "${package_share}/"
  cp -a "${REPO_ROOT}/fs150-sitl/reports" "${package_share}/"
  cp "${REPO_ROOT}/fs150-sitl/scripts/generate_fs150_sitl_params.py" "${package_lib}/"
  chmod 0755 "${package_lib}/generate_fs150_sitl_params.py"
}

build_fs150_sitl_deb() {
  local package="ros-${ROS_DISTRO}-xgc2-gazebo-sim-fs150-sitl"
  local depends="python3, ros-${ROS_DISTRO}-roslaunch, ros-${ROS_DISTRO}-mavros, ros-${ROS_DISTRO}-xgc2-gazebo-sim-px4-1-12"
  local pkg_root="${BUILD_DIR}/${package}"

  rm -rf "${pkg_root}"
  mkdir -p "${pkg_root}"

  write_control \
    "${pkg_root}" \
    "${package}" \
    "${depends}" \
    "FS150 PX4 1.12 iris SITL wrapper for XGC2 Gazebo simulation"

  copy_fs150_sitl_payload "${pkg_root}"

  fakeroot dpkg-deb --build "${pkg_root}" "${OUTPUT_DIR}/${package}_${VERSION}_${ARCH}.deb" >/dev/null
}

if [[ "${META_MODE}" == "locked" ]]; then
  meta_pkg="ros-${ROS_DISTRO}-xgc2-gazebo-sim-all"
  meta_extra_fields="Replaces: ros-${ROS_DISTRO}-xgc2-gazebo-sim
Conflicts: ros-${ROS_DISTRO}-xgc2-gazebo-sim"
elif [[ "${META_MODE}" == "latest" ]]; then
  meta_pkg="ros-${ROS_DISTRO}-xgc2-gazebo-sim-all-latest"
  meta_extra_fields=""
else
  echo "GAZEBO_SIM_META_MODE must be locked or latest" >&2
  exit 1
fi

meta_depends="$("${SCRIPT_DIR}/meta_depends.sh" --mode "${META_MODE}" --release-set "${RELEASE_SET}")"

build_fs150_sitl_deb

build_meta_deb \
  "${meta_pkg}" \
  "${meta_depends}" \
  "XGC2 Gazebo Classic simulation aggregate package" \
  "${meta_extra_fields}"

find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.deb' -print | sort
