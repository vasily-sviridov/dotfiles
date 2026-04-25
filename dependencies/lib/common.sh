#!/usr/bin/env bash

if [[ -t 1 ]]; then
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  BLUE=$'\033[34m'
  YELLOW=$'\033[33m'
  RESET=$'\033[0m'
else
  RED=""
  GREEN=""
  BLUE=""
  YELLOW=""
  RESET=""
fi

log() { echo "${BLUE}==>${RESET} $*"; }
success() { echo "${GREEN}✔${RESET} $*"; }
warn() { echo "${YELLOW}⚠${RESET} $*"; }
die() { echo "${RED}✖${RESET} $*" >&2; exit 1; }

trap 'die "Failed at line $LINENO"' ERR

has() {
  command -v "$1" >/dev/null 2>&1
}

run() {
  log "$*"
  "$@"
}

detect_platform() {
  case "$(uname -s)" in
    Linux) PLATFORM="ubuntu" ;;
    Darwin) PLATFORM="macos" ;;
    *) die "Unsupported OS" ;;
  esac
}
