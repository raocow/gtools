# git-tools

Personal custom `git` subcommands. Git treats any executable named `git-<name>`
on your `PATH` as `git <name>`, so these work like built-ins once installed.

## Install

```bash
git clone <this-repo> ~/git-tools
cd ~/git-tools
./install.sh                 # symlinks bin/git-* into ~/.local/bin
# (pass a dir to link elsewhere, e.g. ./install.sh ~/bin)
```

`./install.sh` symlinks, so a later `git pull` here updates the commands in
place. Make sure the target dir is on your `PATH`.

## Commands

| Command | What it does |
|---|---|
| `git sweep` | Delete local branches already merged into the base branch. Fetches first and compares against the base's **remote tip** (`origin/<base>`), so it works without pulling main and from any branch — a branch merged upstream is swept even if your local main is stale. Safe by default: `git branch -d` (refuses anything unmerged). `-f`/`--force` widens it to **every** local branch except base + current and force-deletes with `-D` — clears never-PR'd / squash-merged / unmerged branches too (deletes unmerged work; preview with `-n`). `-n` dry-run, `-b NAME` base. |
| `git sync` | Rebase the current branch onto `origin/<default>` and push it: `git fetch → git rebase → git push --force-with-lease`. Guards against running on `main`/dirty trees; stops cleanly on conflicts. `-n` dry-run, `-b NAME` base. |
| `git pr <n>` | Check out the branch for GitHub PR `#n`. If it's already local, just switch; otherwise fetch it (falls back to `refs/pull/<n>/head` for merged/closed PRs). Needs the GitHub CLI (`gh`). |

Each takes `-h` for help.

## Requirements

- `bash` (works on macOS's bash 3.2)
- `git`
- `gh` (GitHub CLI) — only for `git pr`. `install.sh` installs it via Homebrew if
  missing (and prints manual instructions on other platforms); not fatal, so the
  other commands install fine without it.

## Notes

- `git sweep` won't catch **squash-merged** branches (a squash isn't an ancestor
  of the base, so `-d` correctly refuses it) — delete those by hand.
- `git sync` uses `--force-with-lease`, which still refuses to clobber remote
  commits you haven't fetched.
