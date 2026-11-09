#!/usr/bin/env bash
# E2E test for mise + chezmoi migration.
# Fresh clone + ./install, then verify tools + dotfiles + no dotbot.
set -uo pipefail

FAIL=0

fail() {
  echo "FAIL: $*" >&2
  FAIL=1
}

cd /dotfiles

echo "========== 1. ./install (fresh clone) =========="
./install
INSTALL_EXIT=$?
echo ">>> ./install EXIT_CODE=$INSTALL_EXIT"
if [ "$INSTALL_EXIT" != "0" ]; then
  fail "./install exited with $INSTALL_EXIT"
fi

echo ""
echo "========== 2. dotbot remnants (should be none outside test/) =========="
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
if [ "$DOTBOT_FOUND" != "0" ]; then
  fail "dotbot references remain in repository"
fi

echo ""
echo "========== 3. chezmoi =========="
export PATH="$HOME/.local/bin:$PATH"
if ! chezmoi --version >/dev/null 2>&1; then
  fail "chezmoi not installed / not on PATH"
else
  chezmoi --version
fi

echo ""
echo "========== 4. chezmoi-applied files in HOME =========="
ALL_OK=1
for f in .zshrc .zplugrc .editorconfig .gitconfig .gitattributes_global \
         .shell/.exports .shell/.aliases .shell/.external .shell/.std .shell/.wsl \
         .config/chezmoi/chezmoi.toml; do
  if [ -e "$HOME/$f" ]; then echo "OK   $HOME/$f"; else echo "MISS $HOME/$f"; ALL_OK=0; fi
done
if [ "$ALL_OK" != "1" ]; then
  fail "some chezmoi-managed files are missing in $HOME"
fi

echo ""
echo "========== 5. mise =========="
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/mise/shims:$PATH"
if ! mise --version >/dev/null 2>&1; then
  fail "mise not installed / not on PATH"
else
  mise --version
fi
if ! mise current >/dev/null 2>&1; then
  fail "mise current failed"
else
  mise current
fi

echo ""
echo "========== 6. Tools (mise shims / PATH) =========="
MISSING_TOOLS=""
for t in node go python rustc java; do
  if command -v "$t" >/dev/null 2>&1; then
    printf "%-10s %s\n" "$t" "$(command -v "$t")"
  else
    printf "%-10s (not on PATH)\n" "$t"
    MISSING_TOOLS="$MISSING_TOOLS $t"
  fi
done
for t in eza zoxide ruff uv cargo delta; do
  if command -v "$t" >/dev/null 2>&1; then
    printf "%-10s %s\n" "$t" "$(command -v "$t")"
  else
    printf "%-10s (not on PATH)\n" "$t"
    MISSING_TOOLS="$MISSING_TOOLS $t"
  fi
done
if [ -n "$MISSING_TOOLS" ]; then
  fail "missing tools on PATH:$MISSING_TOOLS"
fi

echo ""
echo "========== 7. Versions =========="
# clang-22 is environment-dependent (llvm.sh may not support brand-new Ubuntu),
# so it is a soft check only.
if command -v clang-22 >/dev/null 2>&1; then
  echo "clang-22: $(clang-22 --version 2>&1 | head -1)"
else
  echo "clang-22: (not available — environment-dependent, soft check)"
fi

EXPECTED="node lts go 1.27.3 python 3.14 rust stable java 21"
ACTUAL=$(mise current 2>/dev/null || true)
for pair in node:lts go:1.27.3 python:3.14 rust:stable java:21; do
  tool="${pair%%:*}"
  ver="${pair##*:}"
  if echo "$ACTUAL" | grep -q "^$tool $ver"; then
    echo "OK   $tool $ver"
  else
    fail "mise: expected $tool=$ver, got: $(echo "$ACTUAL" | grep "^$tool " || echo "<not installed>)"
  fi
done

echo ""
echo "========== E2E DONE =========="

if [ "$FAIL" != "0" ]; then
  echo "E2E FAILED" >&2
  exit 1
fi
echo "E2E PASSED"
