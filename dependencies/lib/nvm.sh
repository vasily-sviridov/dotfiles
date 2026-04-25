#!/usr/bin/env bash

install_nvm() {
  export NVM_DIR="${HOME}/.nvm"

  if [[ ! -d "$NVM_DIR" ]]; then
    log "Installing nvm"
    run curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  else
    success "nvm already installed"
  fi

  set +u
  # shellcheck disable=SC1090
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

  run nvm install --lts
  run nvm use --lts
  run nvm alias default 'lts/*'
  set -u

  success "Node: $(node --version)"
  success "npm: $(npm --version)"
}
