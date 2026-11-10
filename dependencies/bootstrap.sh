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
  # mise.run installs to $HOME/.local/bin/mise; make it available in this shell
  export PATH="$HOME/.local/bin:$PATH"
  retry 3 sh -c 'curl -fsSL --retry 3 https://mise.run | sh'
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
  # GitHub can flake (504) on individual tool downloads; retry the whole set.
  retry 3 mise install || die "mise install failed after retries"
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
  retry 3 sh -c 'BINDIR="$HOME/.local/bin" sh -c "$(curl -fsSL --retry 3 https://get.chezmoi.io)"'
  if ! has chezmoi; then
    die "chezmoi installation failed after retries"
  fi
}

setup_chezmoi() {
  log "Applying dotfiles with chezmoi (source: $REPO_DIR)"
  retry 3 chezmoi init --apply "$REPO_DIR" || die "chezmoi apply failed after retries"
}

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------

install_ubuntu_packages() {
  local packages_file="$ROOT_DIR/ubuntu-packages.txt"
  if [[ ! -f "$packages_file" ]]; then
    warn "$packages_file not found, skipping apt packages"
  else
    retry 3 sudo apt-get update
    # shellcheck disable=SC2046
    retry 3 sudo apt-get install -y $(grep -vE '^\s*(#|$)' "$packages_file" | tr '\n' ' ')
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
    retry 3 brew install $(grep -vE '^\s*(#|$)' "$packages_file" | tr '\n' ' ')
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
  retry 3 cargo install cargo-binstall || die "cargo-binstall installation failed after retries"
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
  retry 3 cargo binstall -y $(grep -vE '^\s*(#|$)' "$crates_file" | tr '\n' ' ') || die "cargo-binstall crates installation failed after retries"
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
  retry 3 sh -c 'curl -LsSf --retry 3 https://astral.sh/uv/install.sh | sh'
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
    retry 3 uv tool install "$tool" || warn "uv tool install $tool failed after retries"
  done < "$tools_file"
}

# ---------------------------------------------------------------------------
# zerobrew
# ---------------------------------------------------------------------------

install_zerobrew() {
  if has zerobrew; then
    success "zerobrew already installed: $(zerobrew --version)"
    return
  fi
  log "Installing zerobrew"

  # Determine platform and architecture for zerobrew release assets.
  # Release assets are named: zb-<os>-<arch> (e.g. zb-linux-x64, zb-darwin-arm64)
  local os arch
  case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *) die "Unsupported OS: $(uname -s)" ;;
  esac
  case "$(uname -m)" in
    x86_64) arch="x64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) die "Unsupported architecture: $(uname -m)" ;;
  esac

  local url="https://github.com/zerobrewhq/zerobrew/releases/latest/download/zb-${os}-${arch}"
  mkdir -p "$HOME/.zerobrew/bin"

  # zerobrew can flake; retry with backoff.
  retry 3 sh -c "curl -fsSL --retry 3 '${url}' -o '$HOME/.zerobrew/bin/zerobrew'" || die "zerobrew download failed after retries"
  chmod +x "$HOME/.zerobrew/bin/zerobrew"
  export PATH="$HOME/.zerobrew/bin:$PATH"

  if ! has zerobrew; then
    die "zerobrew is not available on PATH"
  fi
}

install_zerobrew_packages() {
  local packages_file="$ROOT_DIR/zerobrew-packages.txt"
  if [[ ! -f "$packages_file" ]]; then
    warn "$packages_file not found, skipping zerobrew packages"
    return
  fi

  install_zerobrew

  # Initialize zerobrew store before installing any packages.
  log "Initializing zerobrew store"
  retry 3 zerobrew init || warn "zerobrew init failed after retries"

  log "Installing zerobrew packages"
  local pkg
  while IFS= read -r pkg || [ -n "$pkg" ]; do
    # skip blank lines and comments
    [[ -z "${pkg// }" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    log "Installing zerobrew package: $pkg"
    retry 3 zerobrew install "$pkg" || warn "zerobrew install $pkg failed after retries"
  done < "$packages_file"
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

  install_zerobrew
  install_zerobrew_packages

  success "Bootstrap done 🎉"
}

main "$@"
