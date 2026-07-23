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

# zsh completion: symlink into <target>/../share/zsh/site-functions, the
# standard Homebrew/zsh convention — these are plain autoloadable functions
# (one per file, named to match), so they just work once that directory is on
# $fpath. No `source` line, no compinit-ordering requirement, unlike a
# hand-rolled completion script.
fndir="$(dirname "$target")/share/zsh/site-functions"
mkdir -p "$fndir"
if [ -d "$here/share/zsh/site-functions" ]; then
  for c in "$here"/share/zsh/site-functions/*; do
    name="$(basename "$c")"
    ln -sf "$c" "$fndir/$name"
  done
  echo "linked  $(basename "$fndir")/*  →  $fndir/"
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

# Best-effort check: is $fndir already on zsh's fpath in an interactive
# shell? If so, completion (incl. `git new` for short-name Tab-cycling) just
# works already — nothing more to do. If not, this is the one-time GENERAL
# Homebrew zsh-completions snippet, not anything gtools-specific — it also
# covers every other formula's completions, present and future.
on_fpath=0
if command -v zsh >/dev/null 2>&1; then
  case ":$(zsh -ic 'echo $fpath' 2>/dev/null):" in
    *":$fndir:"*) on_fpath=1 ;;
  esac
fi

echo
if [ "$on_fpath" = 1 ]; then
  echo "zsh completion is already set up — Tab-completion (incl. 'git new' for"
  echo "short-name cycling on new branches) works with no further action."
else
  echo "For Tab-completion of these commands — including 'git new <TAB>' for"
  echo "cycling through short names instead of typing a long one — add this to"
  echo "~/.zshrc (the general Homebrew zsh-completions snippet, not specific to"
  echo "gtools; skip it if you already have something like it). Append, don't"
  echo "prepend: Homebrew's git package ships its own _git (a different"
  echo "implementation) in this same directory, which doesn't support the"
  echo "_git-<subcommand> dispatch these completions rely on — prepending would"
  echo "let it shadow the system _git that does."
  echo "       fpath+=(\"$fndir\")"
  echo "       autoload -Uz compinit && compinit"
fi
echo
echo "Done. Try:  git sweep -h   (or full man page: git sweep --help)"
