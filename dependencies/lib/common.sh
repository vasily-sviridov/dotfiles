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

log() { echo "${BLUE}==>${RESET} $*" >&2; }
success() { echo "${GREEN}✔${RESET} $*" >&2; }
warn() { echo "${YELLOW}⚠${RESET} $*" >&2; }
die() { echo "${RED}✖${RESET} $*" >&2; exit 1; }

trap 'die "Failed at line $LINENO"' ERR

has() {
  command -v "$1" >/dev/null 2>&1
}

run() {
  log "$*"
  "$@"
}

# retry: run a command with quadratic backoff (1s, 4s, 9s, ...)
# Usage: retry <max_attempts> <command> [args...]
retry() {
  local max_attempts="$1"
  shift
  local attempt=0
  while [[ $attempt -lt $max_attempts ]]; do
    attempt=$((attempt + 1))
    if "$@"; then
      return 0
    fi
    if [[ $attempt -ge $max_attempts ]]; then
      return 1
    fi
    local delay=$((attempt * attempt))
    warn "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
    sleep "$delay"
  done
  return 1
}

detect_platform() {
  case "$(uname -s)" in
    Linux) PLATFORM="ubuntu" ;;
    Darwin) PLATFORM="macos" ;;
    *) die "Unsupported OS" ;;
  esac
}
