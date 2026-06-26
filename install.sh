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

echo
echo "Done. Try:  git sweep -h"
