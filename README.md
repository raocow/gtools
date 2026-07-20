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
| `git sweep` | Delete local branches already merged into the base branch. Fetches first and compares against the base's **remote tip** (`origin/<base>`), so it works without pulling main and from any branch — a branch merged upstream is swept even if your local main is stale. Safe by default: only deletes branches verified merged into the base's remote tip (via `merge-base`), so no unmerged work is lost — and unlike a bare `git branch -d` it isn't fooled by a stale local base. `-f`/`--force` widens it to **every** local branch except base + current and force-deletes with `-D` — clears never-PR'd / squash-merged / unmerged branches too (deletes unmerged work; preview with `-n`). `-n` dry-run, `-b NAME` base. |
| `git wsweep` | The worktree analogue of `git sweep`: remove worktrees whose **HEAD is already merged** into the base's remote tip (`origin/<base>`, after a fetch), and **keep the branches** — so you can drop throwaway per-task checkouts and still switch to the branch later from your main worktree. Safe by default (verified with `merge-base`, judged by the worktree's HEAD so branch-backed and detached trees both work); the main worktree and the one you're in are never touched. `-f`/`--force` removes **every** other worktree regardless of merge status with `git worktree remove --force` — also dropping worktrees with uncommitted changes (discards those changes; branches survive; preview with `-n`). `-n` dry-run, `-b NAME` base. Removing a worktree never deletes its branch — run `git sweep` after if you want the merged branches gone too. |
| `git sync` | Rebase the current branch onto `origin/<default>` and push it: `git fetch → git rebase → git push --force-with-lease`. On the base branch it acts as a safe pull instead (`git fetch → git rebase origin/<base>`, no push — fast-forwards when only behind, replays local commits when diverged). Guards against dirty trees; stops cleanly on conflicts. `--all`/`-a` does the whole repo in one pass: fast-forwards local base, **prunes** branches already merged into it, and rebases + pushes the rest — branches that hit rebase conflicts are aborted untouched and listed to fix by hand; purely-local (never-pushed) branches are rebased but not pushed; squash-merged branches look unmerged so they're rebased, not pruned (use `git sweep -f`). `-n` dry-run, `-b NAME` base. |
| `git pr <n>` | Check out PR `#n`'s branch, **always up to date**: runs `gh pr checkout`, which creates the branch or fast-forwards an existing one to the PR's latest. Falls back to `refs/pull/<n>/head` for merged/closed PRs whose branch was deleted, and — if GitHub is unreachable — to a local branch stamped with the PR number (switched to as-is, not updated). Needs the GitHub CLI (`gh`). |
| `git prs` | Print one link per line for every open PR you've authored in the current repo (nothing else — easy to skim or pipe). `--title`/`-t` appends the title as `<link> -- <title>`. Needs the GitHub CLI (`gh`). |
| `git done` | The bookend to `git pr`: switch back to the base (`origin/<default>`, usually main), **fast-forward it to origin** (so you land on an up-to-date main with the just-merged PR), and delete the branch you just left. Safe by default (`git branch -d`) so hopping back can't silently drop unmerged work — squash-merged branches look unmerged and are refused too, so pass `-f`/`--force` (`git branch -D`) when you know the branch is done. The fast-forward is best-effort: it's skipped with a note if you're offline or local base has diverged (never a merge commit). On a detached HEAD it just switches back to base; **already on the base, it just pulls** (fetch + fast-forward — nothing to delete). `-n` dry-run, `-b NAME` base. |

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
