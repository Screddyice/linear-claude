#!/usr/bin/env bash
# insert-linear-link — print a Linear magic-word line for the current branch.
#
# Usage:
#   insert-linear-link [PREFIXES] [BASE_BRANCH]
#
#   PREFIXES     Comma-separated Linear team prefixes to look for. Default: HSOS,NEB,ENG.
#   BASE_BRANCH  Branch to diff commits against. Default: main.
#
# Exit codes:
#   0  Found a match — line printed to stdout.
#   1  No match found — nothing printed, nothing fabricated.
#   2  Misuse (e.g. not in a git repo).
#
# Examples:
#   $ insert-linear-link
#   Closes HSOS-158
#
#   $ insert-linear-link ENG main
#   Closes ENG-42
#
#   # Splice into a PR body builder:
#   line=$(insert-linear-link HSOS,NEB) || true
#   gh pr create --body "$(cat <<EOF
#   ## Summary
#   ...
#   ${line}
#   EOF
#   )"

set -euo pipefail

PREFIXES_RAW="${1:-HSOS,NEB,ENG}"
BASE_BRANCH="${2:-main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "insert-linear-link: not in a git repository" >&2
  exit 2
fi

# Build a regex like "\b(HSOS|NEB|ENG)-[0-9]+\b"
prefix_alt=$(echo "$PREFIXES_RAW" | tr ',' '|' | tr -d '[:space:]')
if [[ -z "$prefix_alt" ]]; then
  echo "insert-linear-link: no prefixes given" >&2
  exit 2
fi
issue_re="\b(${prefix_alt})-[0-9]+\b"

# Sources, in order of trust:
#   1. Branch name (sometimes teams sneak the ID in despite a hook)
#   2. Commit messages on this branch since base
# Prefer symbolic-ref so we get the branch name even on an unborn HEAD
# (newly-init'd repo with no commits yet). Falls back to abbrev-ref for
# detached-HEAD safety.
branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
match=""

if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
  # grep -E ERE, -o match-only, -i case-insensitive
  match=$(printf '%s\n' "$branch" | grep -oEi "$issue_re" | head -n1 || true)
fi

if [[ -z "$match" ]]; then
  # Look in commit subjects + bodies on this branch only — only meaningful if
  # the repo has a HEAD commit AND the base branch exists.
  if git rev-parse --verify --quiet HEAD >/dev/null \
     && git rev-parse --verify --quiet "$BASE_BRANCH" >/dev/null; then
    match=$(git log --pretty=%B "$BASE_BRANCH"..HEAD 2>/dev/null \
      | grep -oEi "$issue_re" \
      | head -n1 || true)
  fi
fi

if [[ -z "$match" ]]; then
  exit 1
fi

# Normalize to uppercase prefix-NUMBER form.
normalized=$(echo "$match" | tr '[:lower:]' '[:upper:]')
echo "Closes ${normalized}"
