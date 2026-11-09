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
  run curl https://mise.run | sh
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
  run mise install
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
  run sh -c "$(curl -fsSL https://get.chezmoi.io)"
}

setup_chezmoi() {
  log "Applying dotfiles with chezmoi (source: $REPO_DIR)"
  run chezmoi init --apply "$REPO_DIR"
}

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------

install_ubuntu_packages() {
  run sudo apt-get update

  local packages=(
    build-essential
    cmake
    ninja-build
    git
    curl
    wget
    jq
    fzf
    neovim
    python3
    python3-venv
    tmux
    unzip
    zsh
  )

  run sudo apt-get install -y "${packages[@]}"

  # clang-22 (system, not managed by mise)
  if ! has clang-22; then
    log "Installing clang-22 via apt.llvm.org"
    run wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- 22 all
  fi
}

install_macos_packages() {
  if ! has brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  run brew update

  local packages=(
    cmake
    ninja
    git
    curl
    wget
    jq
    fzf
    neovim
    tmux
    zsh
    llvm
  )

  run brew install "${packages[@]}"
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
  run curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_uv_tools() {
  local tools_file="$ROOT_DIR/uv-tools.txt"
  if [[ ! -f "$tools_file" ]]; then
    warn "$tools_file not found, skipping uv tools"
    return
  fi

  install_uv

  # shellcheck disable=SC2046
  run uv tool install $(grep -vE '^\s*(#|$)' "$tools_file" | tr '\n' ' ')
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

main() {
  install_mise
  activate_mise
  install_mise_tools

  install_chezmoi
  setup_chezmoi

  case "$(uname -s)" in
    Linux) install_ubuntu_packages ;;
    Darwin) install_macos_packages ;;
    *) die "Unsupported OS" ;;
  esac

  install_crates
  install_uv_tools

  success "Bootstrap done 🎉"
}

main "$@"
