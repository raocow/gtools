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

## zsh completion

`install.sh` also symlinks a set of plain zsh completion functions into
`<target>/../share/zsh/site-functions` — real Tab-completion for every
command above (real branches, real open PRs — nothing generated or guessed,
same principle as `cd` completing real directories). No `source` line, no
compinit-ordering requirement: these autoload the standard way, so they just
work once that directory is on your `$fpath`.

`git new` is the one built specifically to fix chronically-verbose
LLM-authored branch names: `git new <TAB>` cycles through short *words
already used in this repo's existing branch names* (via `_multi_parts`), so
composing a name is a few Tab presses instead of typing a sentence — and it
works no matter what's driving your terminal (Claude, Codex, you by hand),
since it fires on the completion itself, not on any tool choosing to
cooperate.

If `install.sh` doesn't detect that zsh's own `_git` wins, it prints a
one-time setup snippet. The subtlety: these are `git <subcommand>` completions,
so completing their arguments goes through whatever `_git` is first on
`fpath`. zsh's own `_git` dispatches to `_git-<cmd>` user functions (how these
work); the `_git` that **Homebrew's `git` formula** ships does **not** — it
sends unknown subcommands' arguments to plain file completion. And `brew
shellenv` prepends Homebrew's `site-functions` dir, so by default brew's `_git`
wins and `git pr list <TAB>` / `git new <TAB>` just list files. The fix puts
zsh's own function dirs back in front (so its `_git` wins) while keeping the
completion dir on `fpath`:

```zsh
typeset -U fpath
fpath=(/usr/share/zsh/${ZSH_VERSION}/functions /usr/share/zsh/site-functions "$COMPLETION_DIR" $fpath)
autoload -Uz compinit && compinit
```

(`$COMPLETION_DIR` is `install.sh`'s target, e.g. `~/.local/share/zsh/site-functions`; with the Homebrew formula it's already on `fpath` and you can drop it.)

## Commands

| Command | What it does |
|---|---|
| `git sweep` | Delete local branches already merged into the base branch. Fetches first and compares against the base's **remote tip** (`origin/<base>`), so it works without pulling main and from any branch — a branch merged upstream is swept even if your local main is stale. Safe by default: only deletes branches verified merged into the base's remote tip (via `merge-base`), so no unmerged work is lost — and unlike a bare `git branch -d` it isn't fooled by a stale local base. `-f`/`--force` widens it to **every** local branch except base + current and force-deletes with `-D` — clears never-PR'd / squash-merged / unmerged branches too (deletes unmerged work; preview with `-n`). `-n` dry-run, `-b NAME` base. |
| `git wsweep` | The worktree analogue of `git sweep`: remove worktrees whose **HEAD is already merged** into the base's remote tip (`origin/<base>`, after a fetch), and **keep the branches** — so you can drop throwaway per-task checkouts and still switch to the branch later from your main worktree. Safe by default (verified with `merge-base`, judged by the worktree's HEAD so branch-backed and detached trees both work); the main worktree and the one you're in are never touched. `-f`/`--force` removes **every** other worktree regardless of merge status with `git worktree remove --force` — also dropping worktrees with uncommitted changes (discards those changes; branches survive; preview with `-n`). `-n` dry-run, `-b NAME` base. Removing a worktree never deletes its branch — run `git sweep` after if you want the merged branches gone too. |
| `git sync` | Rebase branch(es) onto `origin/<default>` and push: `git fetch → git rebase → git push --force-with-lease`. Bare `git sync` does the current branch. **Targets mirror `git pr merge`**: name one or more branches to sync — a PR number, head branch, URL, or `824-830`-style range, all mixable (numeric/URL resolve to the PR's head branch via `gh`; a plain branch name is used as-is, offline). `-x`/`--exclude <ids...>` drops branch(es)/PR(s) from either an explicit list or `--all` (same forms, ranges included). On the base branch (or a target that IS the base) it acts as a safe pull instead (`git fetch → git rebase origin/<base>`, no push). **When a rebase can't complete automatically it reacts like `git pr merge`: it aborts the rebase (branch left untouched, never half-rebased), skips it, and lists it at the end as needing manual resolution** — never a conflicted rebase left in your tree, never a failed run (resolve one by hand with `git checkout <branch> && git rebase origin/<base>`). `--all`/`-a` sweeps the whole repo: fast-forwards local base, **prunes** branches already merged into it, rebases + pushes the rest; purely-local (never-pushed) branches are rebased but not pushed; squash-merged branches look unmerged so they're rebased, not pruned (use `git sweep -f`). Guards against dirty trees. No `--method` (sync only ever rebases). `-n` dry-run, `-b NAME` base. |
| `git pr [<n>]` | **List** your open PRs in this repo as `<url> -- <title>` (bare `git pr`); `--no-title`/`-nt` prints just the URLs, one per line (easy to pipe). **Or check one out**: `git pr <n\|branch\|url>` runs `gh pr checkout` (the argument can be a PR number, head branch name, or PR URL), creating the branch or fast-forwarding an existing one to the PR's latest — always up to date. Checkout falls back to `refs/pull/<n>/head` for merged/closed PRs whose branch was deleted, and — if GitHub is unreachable — to a local branch stamped with the PR number (switched to as-is, not updated). **Or inspect specific ones**: `git pr list <id...>` shows title/link for the given PR(s) (any count, including one) instead of checking one out — any author, any state; `git pr <id> <id>` (2+ ids, a range, or `-x`, no `list`) does the same, kept for old muscle memory. An id can also be `.` or `@`, meaning the **current branch** (the PR for the branch you're on, like `gh pr view` with no arg) — works everywhere an id is accepted: `git pr list .`, `git pr .` (checkout), `git pr merge .`, `-x .`. **Or merge one or more**: `git pr merge <id...>` merges exactly the PRs you name (number/branch/URL/`824-830`-style range, all mixable, any author — you named them, so it's explicit), or `git pr merge --all`/`-a` (no ids) sweeps every mergeable PR **you authored** — that broad form never touches anyone else's PR, and neither form ever bypasses branch protection. `-x`/`--exclude <ids...>` drops PR(s) from either form (same id forms, including ranges — e.g. `git pr merge 824-830 -x 825 827`). Touches shared remote state (it merges PRs on GitHub), so it's worth knowing it acts by default; pass `-n`/`--dry-run` to preview the plan first without changing anything. It processes the targeted PRs in an order that minimizes conflicts (least-entangled first, by shared changed files — no LLM, just a conflict-adjacency count); for each PR, clean merges directly, needing-an-update rebases onto its base in a scratch worktree (never touches your current branch) and pushes, blocked/draft/unresolvable are always skipped. `--method merge\|squash\|rebase` overrides the merge method (default: the repo's own). Branches aren't auto-deleted — run `git sweep` after. Needs the GitHub CLI (`gh`). |
| `git new <name>` | Create `<name>` and switch to it (`git switch -c`, from the current branch unless `-b`/`--base <base>` is given) — a thin wrapper whose real point is Tab-completion: with the zsh completions enabled (see below), `git new <TAB>` cycles through short words already used in this repo's branch names, so composing a short name takes a few Tab presses instead of typing a sentence — and it works regardless of what's driving the terminal, since it's the shell doing the completing, not any agent. |
| `git haspr [<branch>]` | Check whether a branch (current branch by default) already has a PR, in **any state** — open, closed, or merged — so it catches one that already landed or got closed before you create a duplicate. Prints the URL + state and exits 0 if found; prints a clear message and exits 1 otherwise, so it's usable in scripts (`git haspr \|\| gh pr create`). Needs the GitHub CLI (`gh`). |
| `git done` | The bookend to `git pr`: switch back to the base (`origin/<default>`, usually main), **fast-forward it to origin** (so you land on an up-to-date main with the just-merged PR), and delete the branch you just left. Safe by default (`git branch -d`) so hopping back can't silently drop unmerged work — squash-merged branches look unmerged and are refused too, so pass `-f`/`--force` (`git branch -D`) when you know the branch is done. The fast-forward is best-effort: it's skipped with a note if you're offline or local base has diverged (never a merge commit). On a detached HEAD it just switches back to base; **already on the base, it just pulls** (fetch + fast-forward — nothing to delete). `-n` dry-run, `-b NAME` base. |

Each takes `-h` for a short usage summary, or `--help` to open its full man
page (installed to `share/man/man1` by `install.sh` and by Homebrew).

Genuinely shared logic (the color/step/warn output helpers, base-branch
resolution, PR-range expansion) lives once in `lib/git-tools-common.sh`,
which each command locates relative to its own real path (following the
symlink it's installed as) and sources — not copy-pasted per file. Only
things that are *coincidentally* similar but reasonably diverge per command
stay separate.

## Requirements

- `bash` (works on macOS's bash 3.2)
- `git`
- `gh` (GitHub CLI) — for `git pr`, and for `git sync` only when a target is a PR
  number or URL (naming branches directly needs no `gh`). `install.sh` installs it
  via Homebrew if missing (and prints manual instructions on other platforms);
  not fatal, so the other commands install fine without it.

## Notes

- `git sweep` won't catch **squash-merged** branches (a squash isn't an ancestor
  of the base, so `-d` correctly refuses it) — delete those by hand.
- `git sync` uses `--force-with-lease`, which still refuses to clobber remote
  commits you haven't fetched.
