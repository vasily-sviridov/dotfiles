# Dotfiles

Personal shell, editor, and tool configs used across several machines — Ubuntu
workstations, macOS laptops, and WSL2. The goal is a reproducible, boring setup
that can be re-applied in one command without snowflake steps.

Dotfiles are applied with [chezmoi](https://www.chezmoi.io) (`dot_config/chezmoi/`,
`dot_*` source files). Tool versions are pinned with [mise](https://mise.jdx.dev)
(`.mise.toml`). Shell is zsh with oh-my-zsh and zplug; editor is Neovim with
LazyVim. System packages, cargo crates, uv tools, and zerobrew packages live in
versioned lists under `dependencies/` rather than being hardcoded in scripts.

## Install

```bash
git clone https://github.com/vasily-sviridov/dotfiles dotfiles
cd dotfiles
./install
```

`./install` delegates to `dependencies/bootstrap.sh`, which:

1. Installs `mise` and `chezmoi`.
2. Runs `mise install` for pinned toolchains.
3. Runs `chezmoi init --apply` to write dotfiles into `$HOME`.
4. Installs system packages (Ubuntu or macOS, including `clang-22`).
5. Installs cargo-binstall crates from `dependencies/crates.txt`.
6. Installs uv tools from `dependencies/uv-tools.txt`.
7. Installs zerobrew packages from `dependencies/zerobrew-packages.txt`.

## Platforms

Ubuntu, macOS, WSL2.

## Adding software

| File | Purpose |
| --- | --- |
| `dependencies/crates.txt` | cargo-binstall crates (one per line) |
| `dependencies/uv-tools.txt` | uv tools (one per line) |
| `dependencies/zerobrew-packages.txt` | zerobrew packages (one per line) |
| `dependencies/ubuntu-packages.txt` | apt packages |
| `dependencies/macos-packages.txt` | brew packages |

Zsh completions live in `dot_shell/dot_completions` and are generated once per binary update, not on every shell start.

## License

[MIT](LICENSE)
