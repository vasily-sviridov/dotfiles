#!/usr/bin/env bash

install_ubuntu() {
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

  if ! has clang-20; then
    wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- 20 all
  fi
}
