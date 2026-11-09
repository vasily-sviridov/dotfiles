# Dotfiles

Tool versions are pinned with [mise](https://mise.jdx.dev) (`.mise.toml`); dotfiles are applied with
[chezmoi](https://www.chezmoi.io) (`dot_config/chezmoi/chezmoi.toml`, `dot_*` source files).

## Installation

1. Clone this repo with: `git clone https://github.com/vasily-sviridov/dotfiles dotfiles`
2. `cd dotfiles/`
3. Run: `./install`

`./install` is a thin entrypoint that delegates to `dependencies/bootstrap.sh`, which installs
mise and chezmoi, installs the pinned toolchains (`mise install`), applies the dotfiles
(`chezmoi init --apply`), installs system packages (incl. clang-22), cargo-binstall crates, and uv
tools.
