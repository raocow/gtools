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

# Man pages: symlink into <target>/../share/man/man1, which `man` derives from a
# bin dir on PATH (e.g. ~/.local/bin → ~/.local/share/man). That's what lets
# `git <cmd> --help` open the page — git turns `--help` into `man git-<cmd>`.
mandir="$(dirname "$target")/share/man/man1"
mkdir -p "$mandir"
for m in "$here"/man/git-*.1; do
  name="$(basename "$m")"
  ln -sf "$m" "$mandir/$name"
  echo "linked  $name  →  $mandir/$name"
done

# zsh completion: symlink next to the man pages (<target>/../share/zsh), and
# print the source line — unlike bin/man, this can't just be "on PATH"; it
# has to be `source`d from ~/.zshrc, and specifically BEFORE compinit runs
# (see the file's own header for why).
zshdir="$(dirname "$target")/share/zsh"
mkdir -p "$zshdir"
completion="$here/share/zsh/git-tools-completion.zsh"
if [ -f "$completion" ]; then
  ln -sf "$completion" "$zshdir/git-tools-completion.zsh"
  echo "linked  git-tools-completion.zsh  →  $zshdir/git-tools-completion.zsh"
fi

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
echo "For Tab-completion of these commands (and short-name cycling for new"
echo "branches on 'git switch -c' / 'git checkout -b'), add this to ~/.zshrc"
echo "ABOVE any 'compinit' line:"
echo "       source \"$zshdir/git-tools-completion.zsh\""
echo
echo "Done. Try:  git sweep -h   (or full man page: git sweep --help)"
