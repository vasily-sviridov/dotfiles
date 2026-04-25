#!/usr/bin/env bash

install_golang() {
  local version="1.26.2"
  local os arch archive url
  local install_root="${HOME}/.local/go"
  local version_dir="${install_root}/${version}"
  local current_link="${install_root}/current"

  if [[ -x "${current_link}/bin/go" ]]; then
    success "Go already installed: $("${current_link}/bin/go" version)"
    return
  fi

  case "$(uname -s)" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *) die "Unsupported OS for Go" ;;
  esac

  case "$(uname -m)" in
    x86_64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) die "Unsupported arch for Go" ;;
  esac

  archive="go${version}.${os}-${arch}.tar.gz"
  url="https://go.dev/dl/${archive}"

  log "Installing Go ${version} → ${version_dir}"

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  run mkdir -p "$install_root"
  run curl -L "$url" -o "$tmp/go.tar.gz"
  run tar -C "$tmp" -xzf "$tmp/go.tar.gz"
  run mv "$tmp/go" "$version_dir"
  run ln -sfn "$version_dir" "$current_link"

  export PATH="${current_link}/bin:$PATH"

  success "Installed $(go version)"
}
