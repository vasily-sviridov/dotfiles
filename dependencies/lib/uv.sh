#!/usr/bin/env bash

install_uv() {
  if ! has uv; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
}
