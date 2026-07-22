#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DOCKER_IMAGE="${DOCKER_IMAGE:-ros:noetic-ros-base-focal}"
WORK_DIR="${WORK_DIR:-${REPO_ROOT}/.work/docker}"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/debs}"
INSTALL_CHECK="${INSTALL_CHECK:-true}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      DOCKER_IMAGE="$2"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --skip-install-check)
      INSTALL_CHECK=false
      shift
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}"

docker pull "${DOCKER_IMAGE}"
docker run --rm \
  -e XGC2_APT_OVERLAY_URL="${XGC2_APT_OVERLAY_URL:-}" \
  -e DEBIAN_FRONTEND=noninteractive \
  -e GAZEBO_SIM_META_MODE="${GAZEBO_SIM_META_MODE:-compatible}" \
  -e INSTALL_CHECK="${INSTALL_CHECK}" \
  -v "${REPO_ROOT}:/workspace/gazebo-sim:ro" \
  -v "${OUTPUT_DIR}:/workspace/out" \
  "${DOCKER_IMAGE}" \
  bash -lc '
    set -euo pipefail

    sed -i \
      -e "s#http://archive.ubuntu.com/ubuntu#https://archive.ubuntu.com/ubuntu#g" \
      -e "s#http://security.ubuntu.com/ubuntu#https://archive.ubuntu.com/ubuntu#g" \
      -e "s#http://ports.ubuntu.com/ubuntu-ports#https://ports.ubuntu.com/ubuntu-ports#g" \
      /etc/apt/sources.list
    printf "%s\n" "Acquire::Retries \"5\";" \
      >/etc/apt/apt.conf.d/99-xgc2-retries
    apt_update() {
      local attempt
      for attempt in 1 2 3; do
        if apt-get update; then
          return 0
        fi
        [[ "${attempt}" -lt 3 ]] || return 1
        sleep "$((attempt * 5))"
      done
    }
    apt_install() {
      local attempt
      for attempt in 1 2 3; do
        if apt-get install "$@"; then
          return 0
        fi
        [[ "${attempt}" -lt 3 ]] || return 1
        sleep "$((attempt * 5))"
        apt_update
      done
    }
    apt_update
    apt_install -y --no-install-recommends ca-certificates curl dpkg-dev fakeroot gnupg

    /workspace/gazebo-sim/.xgc2/scripts/package_debs.sh \
      --output-dir /workspace/out

    if [[ "${INSTALL_CHECK}" == "true" ]]; then
      install -d -m 0755 /etc/apt/keyrings
      curl -fsSL https://xgc2.apt.xiaokang.ink/xgc2-archive-keyring.gpg \
        -o /etc/apt/keyrings/xgc2-archive-keyring.gpg
      echo "deb [signed-by=/etc/apt/keyrings/xgc2-archive-keyring.gpg] https://xgc2.apt.xiaokang.ink focal main" \
        > /etc/apt/sources.list.d/xgc2.list
      if [[ -n "${XGC2_APT_OVERLAY_URL:-}" ]]; then
        echo "deb [signed-by=/etc/apt/keyrings/xgc2-archive-keyring.gpg] ${XGC2_APT_OVERLAY_URL%/} focal main" \
          > /etc/apt/sources.list.d/00-xgc2-release-train.list
      fi
      apt_update
      apt_install -y --no-install-recommends /workspace/out/*.deb
      /workspace/gazebo-sim/.xgc2/scripts/check_installed_packages.sh
    fi

  '

echo "Debian package output:"
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name "*.deb" -print | sort
