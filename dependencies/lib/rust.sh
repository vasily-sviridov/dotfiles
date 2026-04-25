#!/usr/bin/env bash

install_rust() {
  if ! has rustup; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
  fi

  run rustup toolchain install stable
  run rustup component add rustfmt clippy

  if ! has cargo-binstall; then
    run cargo install cargo-binstall
  fi

  local tools=(
    bat
    bore-cli
    broot
    cargo-update
    du-dust
    eza
    fd-find
    git-delta
    gitlogue
    prek
    ripgrep
    tokei
    xh
    zoxide
  )

  for tool in "${tools[@]}"; do
    has "$tool" || run cargo binstall -y "$tool"
  done
}
