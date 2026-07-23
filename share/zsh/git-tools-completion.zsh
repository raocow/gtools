# git-tools zsh completion — Tab-completion for the git-* commands, and for
# `git switch -c` / `git checkout -b` new-branch naming.
#
# Enable by adding to ~/.zshrc, BEFORE compinit runs:
#   source "$(brew --prefix)/share/zsh/git-tools-completion.zsh"
#
# How this works: zsh's own `_git` completion (from the zsh distribution)
# dispatches unknown subcommands to a function named `_git-<subcommand>` if
# one exists — that's the same mechanism it uses for its own built-ins
# (_git-checkout, _git-switch, ...), each guarded by
# `(( $+functions[_git-checkout] )) || _git-checkout() {...}`. Sourcing this
# file BEFORE compinit's first run means our definitions win that guard, so
# no monkey-patching or fpath tricks are needed — just defining these
# functions here is enough.
#
# All candidates come from real data (existing branches, real open PRs via
# `gh`) — nothing is generated or guessed, same principle as `cd` completing
# real directories.

# ---- shared candidate sources -------------------------------------------

# Local + remote branch short names, deduped, excluding HEAD/detached markers.
_gtools_branches() {
  git for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null \
    | sed 's#^origin/##' | grep -v '^HEAD$' | sort -u
}

# Open PR numbers for this repo, "NUMBER:head-branch" — best effort, silent if
# gh/network is unavailable (never blocks completion on an error).
_gtools_open_prs() {
  gh pr list --state open --limit 200 --json number,headRefName \
    --jq '.[] | "\(.number):\(.headRefName)"' 2>/dev/null
}

# PR numbers + branch names + URLs together, for commands that take either.
_gtools_pr_ids() {
  # compadd must run in THIS shell, not a subshell, or the completion system
  # never sees the candidates — so collect into arrays first, no pipes-to-loop.
  local -a prs pr_nums pr_descs branches
  prs=(${(f)"$(_gtools_open_prs)"})
  local p num branch
  for p in $prs; do
    num="${p%%:*}"; branch="${p#*:}"
    pr_nums+=("$num")
    pr_descs+=("$num  ($branch)")
  done
  branches=(${(f)"$(_gtools_branches)"})
  (( $#pr_nums )) && compadd -X 'open PRs' -d pr_descs -a pr_nums
  (( $#branches )) && compadd -X 'branches' -a branches
}

# ---- our own commands -----------------------------------------------------

_git-pr() {
  local -a args
  args=(
    '(-h --help)'{-h,--help}'[show help]'
    '(-nt --no-title)'{-nt,--no-title}'[list bare URLs]'
  )
  if (( CURRENT == 2 )); then
    _alternative \
      'subcommands:subcommand:(merge)' \
      'flags:flag:(-h --help -nt --no-title)' \
      'ids:PR or branch:_gtools_pr_ids'
    return
  fi
  if [[ ${words[2]} == merge ]]; then
    case ${words[CURRENT-1]} in
      --method) compadd merge squash rebase; return ;;
      -x|--exclude) _gtools_pr_ids; return ;;
    esac
    _alternative \
      'flags:flag:(-a --all -x --exclude -n --dry-run --method -h --help)' \
      'ids:PR, branch, or NNN-MMM range:_gtools_pr_ids'
    return
  fi
  _alternative \
    'flags:flag:(-h --help -nt --no-title)' \
    'ids:PR, branch, or URL:_gtools_pr_ids'
}

_git-haspr() {
  _alternative \
    'flags:flag:(-h --help)' \
    'branches:branch:_gtools_branches'
}

_git-sync() {
  case ${words[CURRENT-1]} in
    -b|--base) _gtools_branches; return ;;
    -x|--exclude) _gtools_pr_ids; return ;;
  esac
  _alternative \
    'flags:flag:(-a --all -x --exclude -b --base -n --dry-run -h --help)' \
    'ids:branch, PR, or NNN-MMM range:_gtools_pr_ids'
}

_git-sweep() {
  case ${words[CURRENT-1]} in
    -b|--base) _gtools_branches; return ;;
  esac
  _alternative 'flags:flag:(-f --force -n --dry-run -b --base -h --help)'
}

_git-wsweep() {
  case ${words[CURRENT-1]} in
    -b|--base) _gtools_branches; return ;;
  esac
  _alternative 'flags:flag:(-f --force -n --dry-run -b --base -h --help)'
}

_git-done() {
  case ${words[CURRENT-1]} in
    -b|--base) _gtools_branches; return ;;
  esac
  _alternative 'flags:flag:(-f --force -n --dry-run -b --base -h --help)'
}

_git-slug() {
  case ${words[CURRENT-1]} in
    -n|-l) return ;;
    -t|--ticket) return ;;
  esac
  _alternative 'flags:flag:(-n -l -t --ticket -h --help)'
}

# ---- new-branch naming: git switch -c / git checkout -b ------------------
#
# There's nothing to complete against yet (the name doesn't exist), so this
# harvests short TOKENS from real existing branch names in the repo (split on
# - and /) and offers them via _multi_parts — the standard zsh completer for
# "cycle through hyphen-separated segments," so you Tab through real
# precedent one word at a time instead of typing a sentence: fix<TAB> ->
# fix-md<TAB> -> fix-md-crash, composing from words this repo already uses.
_gtools_branch_tokens() {
  _gtools_branches \
    | grep -vE '^(main|master|HEAD)$' \
    | tr '/-' '\n\n' \
    | grep -vE '^[0-9]*$' \
    | sort -u
}

_gtools_new_branch_name() {
  local -a tokens
  tokens=(${(f)"$(_gtools_branch_tokens)"})
  _multi_parts - tokens
}

(( $+functions[_git-switch] )) && unfunction _git-switch
_git-switch() {
  case ${words[CURRENT-1]} in
    -c|-C) _gtools_new_branch_name; return ;;
  esac
  _alternative \
    'flags:flag:(-c -C --detach -h --help)' \
    'branches:branch:_gtools_branches'
}

(( $+functions[_git-checkout] )) && unfunction _git-checkout
_git-checkout() {
  case ${words[CURRENT-1]} in
    -b|-B) _gtools_new_branch_name; return ;;
  esac
  _alternative \
    'flags:flag:(-b -B --detach -h --help)' \
    'branches:branch:_gtools_branches'
}
