#!/usr/bin/env bash
# E2E test for mise + chezmoi migration.
# Fresh clone + ./install, then verify tools + dotfiles + no dotbot.
set +uo pipefail  # не прерываемся на ошибках — хотим увидеть всё

cd /dotfiles

echo "========== 1. ./install (fresh clone) =========="
./install
INSTALL_EXIT=$?
echo ">>> ./install EXIT_CODE=$INSTALL_EXIT"

echo ""
echo "========== 2. dotbot remnants (should be none outside test/ and .agent-plans) =========="
DOTBOT_FOUND=0
if grep -rln "dotbot" --include="*.sh" --include="*.md" --include="*.toml" --include="*.ignore" --include="*.yaml" . 2>/dev/null \
   | grep -v "^./test/" | grep -q .; then
  echo "DOTBOT REFERENCES FOUND:"
  grep -rln "dotbot" --include="*.sh" --include="*.md" --include="*.toml" --include="*.ignore" --include="*.yaml" . 2>/dev/null \
     | grep -v "^./test/"
  DOTBOT_FOUND=1
else
  echo "OK: no dotbot references outside test/"
fi

echo ""
echo "========== 3. chezmoi =========="
export PATH="$HOME/.local/bin:$PATH"
chezmoi --version 2>/dev/null || echo "chezmoi not on PATH"

echo ""
echo "========== 4. chezmoi-applied files in HOME =========="
ALL_OK=1
for f in .zshrc .zplugrc .editorconfig .gitconfig .gitattributes_global \
         .shell/.exports .shell/.aliases .shell/.external .shell/.std .shell/.wsl \
         .config/chezmoi/chezmoi.toml; do
  if [ -e "$HOME/$f" ]; then echo "OK   $HOME/$f"; else echo "MISS $HOME/$f"; ALL_OK=0; fi
done

echo ""
echo "========== 5. mise =========="
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:$PATH"
mise --version 2>/dev/null || echo "mise not on PATH"
mise current 2>&1 || echo "mise current failed"

echo ""
echo "========== 6. Tools (mise shims / PATH) =========="
for t in node go python rustc java clang-22 clang; do
  printf "%-10s " "$t"; command -v "$t" 2>/dev/null || echo "(not on PATH)"
done
for t in eza zoxide ruff uv cargo git-delta; do
  printf "%-10s " "$t"; command -v "$t" 2>/dev/null || echo "(not on PATH)"
done

echo ""
echo "========== 7. Versions =========="
for t in node go python rustc clang-22 eza zoxide ruff; do
  if command -v "$t" >/dev/null 2>&1; then
    printf "%-10s " "$t"; "$t" --version 2>&1 | head -1
  else
    echo "$t: (not available)"
  fi
done

echo ""
echo "========== E2E DONE =========="

# Exit non-zero if anything critical failed
if [ "$INSTALL_EXIT" != "0" ]; then exit 1; fi
if [ "$DOTBOT_FOUND" != "0" ]; then exit 1; fi
if [ "$ALL_OK" != "1" ]; then exit 1; fi
