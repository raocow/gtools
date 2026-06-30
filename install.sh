#!/usr/bin/env bash
#
# Install the git-* commands by symlinking them onto your PATH.
#
#   ./install.sh              # link into ~/.local/bin (default)
#   ./install.sh ~/bin        # or a directory of your choice
#
# Symlinks (not copies), so `git pull` in this repo updates the installed
# commands instantly. Git discovers any `git-<name>` on PATH as `git <name>`.
#
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-$HOME/.local/bin}"

mkdir -p "$target"
for f in "$here"/bin/git-*; do
  name="$(basename "$f")"
  chmod +x "$f"
  ln -sf "$f" "$target/$name"
  echo "linked  $name  →  $target/$name"
done

case ":$PATH:" in
  *":$target:"*) ;;
  *)
    echo
    echo "⚠  $target is not on your PATH. Add this to your ~/.zshrc (or ~/.bashrc):"
    echo "       export PATH=\"$target:\$PATH\""
    ;;
esac

# `git pr` needs the GitHub CLI (gh). Best-effort install if it's missing —
# never fatal, so `sweep`/`sync` still install fine without it.
if command -v gh >/dev/null 2>&1; then
  echo
  echo "gh (GitHub CLI) found — 'git pr' is good to go."
else
  echo
  echo "gh (GitHub CLI) not found — needed only for 'git pr'."
  if command -v brew >/dev/null 2>&1; then
    echo "Installing via Homebrew…"
    brew install gh || echo "⚠  'brew install gh' failed — install manually: https://cli.github.com"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "   Debian/Ubuntu:  sudo apt-get install gh   (see https://github.com/cli/cli#installation)"
  elif command -v dnf >/dev/null 2>&1; then
    echo "   Fedora:         sudo dnf install gh"
  else
    echo "   Install it from https://cli.github.com"
  fi
  command -v gh >/dev/null 2>&1 && echo "   Now run 'gh auth login' once to authenticate."
fi

echo
echo "Done. Try:  git sweep -h"
