# linear-claude

The smallest possible system that keeps **Linear ↔ GitHub PR auto-link** working when you also have a strict branch-naming convention (Conventional Commits, gstack, etc.) that blocks Linear's branch-based linking.

> If your team enforces `feat/be-foo` / `bug-fix/bar` branch names, Linear's default
> auto-link (which reads the issue ID out of the branch) **silently does nothing.**
> The only mechanism that still works is **magic words in the PR body** —
> and your tooling has to put them there. This repo is that tooling.

---

## The story

Linear has a GitHub integration. It can attach PRs to issues two ways:

1. **Branch name** — `username/eng-123-fix-thing` → auto-attaches to ENG-123.
2. **Magic words** — `Closes ENG-123`, `Fixes ENG-123`, `Refs ENG-123` in the PR title or body → auto-attaches.

If your repo has a husky pre-push hook that enforces a branch convention like:

```
feat/fe-<name>   feat/be-<name>   bug-fix/<name>   hot-fix/<name>
```

…then path (1) is dead. Linear quietly stops attaching anything. You don't get an error message — you just notice, weeks later, that no PR has linked to a Linear issue in months.

That's exactly what happened to a real workspace I was running. Recent PRs had been merging happily, the integration was healthy at the GitHub-App level (`repository_selection: all`), every team's `gitLinkbackMessagesEnabled` was `true`, and the workspace had **zero** GitHub-sourced attachments across its entire history.

The fix is one line of convention. This repo bakes it in.

---

## The convention

Every PR you open should include one line in the body when there's a Linear issue:

```
Closes HSOS-158
```

- `Closes` / `Fixes` / `Resolves` — Linear marks the issue **Done** when the PR merges.
- `Refs` / `Part of` — attaches the PR but leaves the issue open (use for partial work).
- If there is no Linear issue, **omit the line.** Don't fabricate IDs.

That's it. One line, in the body. That single line carries the auto-attach.

---

## What's in this repo

| Path | What it is |
|---|---|
| `skills/linear-claude/SKILL.md` | A Claude Code skill that drops into `~/.claude/skills/linear-claude/`. Tells Claude to include the magic word every time it opens a PR via `gh pr create` or `/ship`. |
| `.github/workflows/validate-linear-link.yml` | An optional GitHub Actions workflow you can copy into your repo. Comments a polite reminder if a PR opens without a magic word. |
| `scripts/insert-linear-link.sh` | A bash helper that scans the current branch's commit messages for an issue ID and prints the magic-word line, ready to splice into your PR body. |

Pick one or all three. They're independent.

---

## Install — Claude Code skill

```bash
git clone https://github.com/Screddyice/linear-claude.git
mkdir -p ~/.claude/skills
cp -r linear-claude/skills/linear-claude ~/.claude/skills/
```

Now Claude Code will see the `linear-claude` skill and apply the convention whenever you ship a PR.

If you use a slash command like `/ship` (gstack), the skill layers on top — your existing flow doesn't change, just gets a magic word inserted at PR-body build time.

---

## Install — GitHub Action

Drop `.github/workflows/validate-linear-link.yml` into any repo where you want PRs validated. Configure your team's prefix at the top of the file:

```yaml
env:
  LINEAR_PREFIXES: HSOS,NEB,ENG  # comma-separated
```

The action runs on `pull_request: [opened, edited]`. If the PR body lacks a magic word matching any configured prefix, the action posts a single comment reminding you (no failure — it's a soft signal, not a gate).

---

## Install — bash helper

Add to your shell profile or a project-level `bin/` directory:

```bash
curl -fsSL https://raw.githubusercontent.com/Screddyice/linear-claude/main/scripts/insert-linear-link.sh \
  -o ~/.local/bin/insert-linear-link && chmod +x ~/.local/bin/insert-linear-link
```

Usage:

```bash
$ insert-linear-link HSOS,NEB
Closes HSOS-158
```

The script greps the current branch's commit messages and most-recent commits on `main..HEAD` for any matching issue ID, picks the first one, and prints the magic-word line. Pipe it into your PR body builder.

---

## Why not just edit the branch convention?

You could lift the branch-name restriction and let Linear's branch-based auto-link do its thing. Two reasons not to:

1. **Conventional Commits projects rely on the branch prefix to drive changelogs and release-please.** Lifting it breaks downstream tooling.
2. **The magic-word path works in every Linear workspace, not just the rare one with branch auto-link configured.** A convention that works everywhere beats one that requires per-team setup.

So: keep your branch convention. Add the magic word.

---

## Status

Lives in production at [`teamnebula-ai/hyperscale`](https://github.com/teamnebula-ai/hyperscale) and the broader Team Nebula AI workspace. Verified end-to-end on 2026-05-08: a PR with `Closes HSOS-158` produced a `sourceType: "github"` attachment on the Linear issue and auto-moved it to **In Progress** in under 30 seconds.

---

## License

MIT — see [LICENSE](./LICENSE).
