#!/usr/bin/env bash

install_macos() {
  if ! has brew; then
    /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
