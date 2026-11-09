#!/usr/bin/env bash
#
# Bootstrap a machine with mise + chezmoi.
#
# Installs mise and chezmoi, installs the pinned mise toolchains,
# applies dotfiles with chezmoi, installs system packages (incl. clang-22),
# cargo-binstall crates from dependencies/crates.txt, and uv tools from
# dependencies/uv-tools.txt.
#
# Intended to be called from ./install (thin entrypoint).

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/.." && pwd)"

# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"

has() {
  command -v "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# mise
# ---------------------------------------------------------------------------

install_mise() {
  if has mise; then
    success "mise already installed: $(mise --version)"
    return
  fi
  log "Installing mise"
  # mise.run can flake (504 etc.); retry up to 3 times before giving up.
  for i in 1 2 3; do
    if curl -fsSL --retry 3 https://mise.run | sh; then
      break
    fi
    warn "mise install attempt $i failed, retrying..."
    sleep 5
  done
  # mise.run installs to $HOME/.local/bin/mise; make it available in this shell
  export PATH="$HOME/.local/bin:$PATH"
  if ! has mise; then
    die "mise installation failed after retries"
  fi
}

activate_mise() {
  # Make mise shims available in this (bash) bootstrap shell.
  if has mise; then
    eval "$(mise activate bash)"
  else
    die "mise is not available on PATH"
  fi
}

install_mise_tools() {
  log "Installing pinned mise toolchains (see .mise.toml)"
  # mise exits non-zero if any single tool fails, even when others installed fine.
  # GitHub can flake (504) on individual tool downloads; retry the whole set.
  local ok=0
  for i in 1 2 3; do
    if mise install; then
      ok=1
      break
    fi
    warn "mise install attempt $i failed, retrying..."
    sleep 10
  done
  if [ "$ok" != "1" ]; then
    die "mise install failed after retries"
  fi
}

# ---------------------------------------------------------------------------
# chezmoi
# ---------------------------------------------------------------------------

install_chezmoi() {
  if has chezmoi; then
    success "chezmoi already installed: $(chezmoi --version)"
    return
  fi
  log "Installing chezmoi"
  # Install into $HOME/.local/bin and make it available in this shell.
  export PATH="$HOME/.local/bin:$PATH"
  # get.chezmoi.io can flake (504); retry up to 3 times.
  for i in 1 2 3; do
    if BINDIR="$HOME/.local/bin" sh -c "$(curl -fsSL --retry 3 https://get.chezmoi.io)"; then
      break
    fi
    warn "chezmoi install attempt $i failed, retrying..."
    sleep 5
  done
  if ! has chezmoi; then
    die "chezmoi installation failed after retries"
  fi
}

setup_chezmoi() {
  log "Applying dotfiles with chezmoi (source: $REPO_DIR)"
  run chezmoi init --apply "$REPO_DIR"
}

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------

install_ubuntu_packages() {
  local packages_file="$ROOT_DIR/ubuntu-packages.txt"
  if [[ ! -f "$packages_file" ]]; then
    warn "$packages_file not found, skipping apt packages"
  else
    run sudo apt-get update
    # shellcheck disable=SC2046
    run sudo apt-get install -y $(grep -vE '^\s*(#|$)' "$packages_file" | tr '\n' ' ')
  fi

  # clang-22 (system, not managed by mise)
  if ! has clang-22; then
    log "Installing clang-22 via apt.llvm.org"
    # llvm.sh may not support brand-new Ubuntu versions; warn but continue.
    run wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- 22 all \
      || warn "clang-22 installation skipped (distro not supported by llvm.sh)"
  fi
}

install_macos_packages() {
  if ! has brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  run brew update

  local packages_file="$ROOT_DIR/macos-packages.txt"
  if [[ ! -f "$packages_file" ]]; then
    warn "$packages_file not found, skipping brew packages"
  else
    # shellcheck disable=SC2046
    run brew install $(grep -vE '^\s*(#|$)' "$packages_file" | tr '\n' ' ')
  fi
}

# ---------------------------------------------------------------------------
# cargo-binstall crates
# ---------------------------------------------------------------------------

install_cargo_binstall() {
  if has cargo-binstall; then
    success "cargo-binstall already installed"
    return
  fi

  if ! has cargo; then
    die "cargo is required to install cargo-binstall (install rust via mise first)"
  fi

  log "Installing cargo-binstall"
  run cargo install cargo-binstall
}

install_crates() {
  local crates_file="$ROOT_DIR/crates.txt"
  if [[ ! -f "$crates_file" ]]; then
    warn "$crates_file not found, skipping crates"
    return
  fi

  install_cargo_binstall

  log "Installing cargo-binstall crates"
  # shellcheck disable=SC2046
  run cargo binstall -y $(grep -vE '^\s*(#|$)' "$crates_file" | tr '\n' ' ')
}

# ---------------------------------------------------------------------------
# uv tools
# ---------------------------------------------------------------------------

install_uv() {
  if has uv; then
    success "uv already installed: $(uv --version)"
    return
  fi
  log "Installing uv"
  # astral.sh can flake; retry up to 3 times.
  for i in 1 2 3; do
    if curl -LsSf --retry 3 https://astral.sh/uv/install.sh | sh; then
      break
    fi
    warn "uv install attempt $i failed, retrying..."
    sleep 5
  done
  if ! has uv; then
    die "uv installation failed after retries"
  fi
}

install_uv_tools() {
  local tools_file="$ROOT_DIR/uv-tools.txt"
  if [[ ! -f "$tools_file" ]]; then
    warn "$tools_file not found, skipping uv tools"
    return
  fi

  install_uv

  local tool
  while IFS= read -r tool || [ -n "$tool" ]; do
    # skip blank lines and comments
    [[ -z "${tool// }" || "$tool" =~ ^[[:space:]]*# ]] && continue
    run uv tool install "$tool"
  done < "$tools_file"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

main() {
  install_mise
  activate_mise

  # System packages first: mise-installed node needs libatomic1,
  # rust/cargo needs a C compiler (build-essential / llvm).
  case "$(uname -s)" in
    Linux) install_ubuntu_packages ;;
    Darwin) install_macos_packages ;;
    *) die "Unsupported OS" ;;
  esac

  install_mise_tools

  install_chezmoi
  setup_chezmoi

  install_crates
  install_uv_tools

  success "Bootstrap done 🎉"
}

main "$@"
