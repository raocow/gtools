# git-tools

Personal custom `git` subcommands. Git treats any executable named `git-<name>`
on your `PATH` as `git <name>`, so these work like built-ins once installed.

You're gonna need the github CLI for git pr so install that before installing this.
These commands are essentially git shortcuts to speed up your dev cycle. I'm sure 
there are safety reasons for why these commands don't already exists, but I feel pretty
safe using them. `git sweep` is a lot quicker than asking an LLM to clear out every
merged branch. `git pr` + `git done` is a nice way to checkout and test your coworker's code
and delete it afterward.

In that sense, it's probably not too useful for individual devs who don't use PRs, but
anyone that works with a team, I recommend.

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
| `git sync` | Rebase the current branch onto `origin/<default>` and push it: `git fetch → git rebase → git push --force-with-lease`. Guards against running on `main`/dirty trees; stops cleanly on conflicts. `--all`/`-a` does the whole repo in one pass: fast-forwards local base, **prunes** branches already merged into it, and rebases + pushes the rest — branches that hit rebase conflicts are aborted untouched and listed to fix by hand; purely-local (never-pushed) branches are rebased but not pushed; squash-merged branches look unmerged so they're rebased, not pruned (use `git sweep -f`). `-n` dry-run, `-b NAME` base. |
| `git pr <n>` | Check out the branch for GitHub PR `#n`. If it's already local, just switch; otherwise fetch it (falls back to `refs/pull/<n>/head` for merged/closed PRs). Needs the GitHub CLI (`gh`). |
| `git done` | The bookend to `git pr`: switch back to the base (`origin/<default>`, usually main), **fast-forward it to origin** (so you land on an up-to-date main with the just-merged PR), and delete the branch you just left. Safe by default (`git branch -d`) so hopping back can't silently drop unmerged work — squash-merged branches look unmerged and are refused too, so pass `-f`/`--force` (`git branch -D`) when you know the branch is done. The fast-forward is best-effort: it's skipped with a note if you're offline or local base has diverged (never a merge commit). Guards against running on the base itself or a detached HEAD. `-n` dry-run, `-b NAME` base. |

Each takes `-h` for a short usage summary, or `--help` to open its full man
page (installed to `share/man/man1` by `install.sh` and by Homebrew).

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
