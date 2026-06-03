#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-noetic}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
META_MODE="${GAZEBO_SIM_META_MODE:-compatible}"
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

if [[ "${META_MODE}" == "compatible" ]]; then
  meta_pkg="ros-${ROS_DISTRO}-xgc2-gazebo-sim-all"
  meta_extra_fields="Replaces: ros-${ROS_DISTRO}-xgc2-gazebo-sim
Conflicts: ros-${ROS_DISTRO}-xgc2-gazebo-sim"
elif [[ "${META_MODE}" == "latest" ]]; then
  meta_pkg="ros-${ROS_DISTRO}-xgc2-gazebo-sim-all-latest"
  meta_extra_fields=""
else
  echo "GAZEBO_SIM_META_MODE must be compatible or latest" >&2
  exit 1
fi

meta_depends="$("${SCRIPT_DIR}/meta_depends.sh" --mode "${META_MODE}" --release-set "${RELEASE_SET}")"

build_meta_deb \
  "${meta_pkg}" \
  "${meta_depends}" \
  "XGC2 Gazebo Classic simulation aggregate package" \
  "${meta_extra_fields}"

find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.deb' -print | sort
