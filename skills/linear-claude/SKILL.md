---
name: linear-claude
description: Use when opening a pull request via gh pr create, /ship, or any other PR-creation flow. Ensures the PR body includes a Linear magic word (Closes/Fixes/Resolves/Refs followed by an issue ID) so Linear's GitHub integration auto-attaches the PR to the issue. Required when the repo enforces a branch-naming convention (feat/be-, bug-fix/, hot-fix/, etc.) that blocks Linear's branch-based auto-link.
---

# Linear-Claude — PR magic-word convention

Linear's GitHub integration attaches a PR to an issue only if it can find the issue ID. There are two paths:

1. **Branch name** contains the ID (e.g. `username/eng-123-foo`).
2. **Magic word** in the PR title or body (`Closes ENG-123`, `Fixes ENG-123`, `Refs ENG-123`).

If the repo enforces a branch-naming convention like Conventional Commits (`feat/fe-…`, `feat/be-…`, `bug-fix/…`, `hot-fix/…`), path (1) **never fires** — the issue ID can't appear in the branch. Path (2) becomes the only option.

This skill makes path (2) automatic.

## When to apply

Apply whenever you are about to open a pull request, including:

- Direct `gh pr create` calls
- `/ship` (gstack) or any equivalent skill
- Any tool that builds a PR body string

If the user is authoring or editing an existing PR body, apply the same convention.

## The rule

Include exactly one line in the PR body when there's a corresponding Linear issue:

```
Closes <ISSUE-ID>
```

Where `<ISSUE-ID>` is `<TEAM-PREFIX>-<NUMBER>` (e.g. `HSOS-158`, `ENG-42`, `NEB-318`).

| Keyword | Effect on issue when PR merges |
|---|---|
| `Closes` / `Fixes` / `Resolves` | Issue moves to **Done** automatically |
| `Refs` / `Part of` | PR attaches but issue stays open (use for partial work) |

If there is **no** corresponding Linear issue, omit the line. **Never fabricate an issue ID.**

## How to find the right ID

Try in this order, stopping when you have a confident match:

1. **Ask the user.** If you can ask a clarifying question, ask: "Is there a Linear issue this PR closes? If yes, paste the ID."
2. **Scan recent commits.** Run `git log main..HEAD --pretty=%B` and grep for `[A-Z]{2,6}-\d+`. The most recent matching ID wins.
3. **Scan the branch name.** Some teams sneak the ID in despite the convention (e.g. `bug-fix/hsos-123-foo`). Grep the current branch with `git rev-parse --abbrev-ref HEAD`.
4. **Query Linear.** If you have access to a Linear MCP server (Composio, native, etc.), query for issues recently assigned to the user that match the work described in this PR. Pick only if confidence is high.

If none of these produce a match, omit the line. Don't guess.

## Where to put the line

Append the line to the PR body, on its own line, after the summary paragraph and before any test plan or generation footer. Example:

```
## Summary

Adds a Cloud SQL pgvector backend for the KB vector store. Drops the
@supabase/supabase-js dependency.

Closes HSOS-158

## Test plan

- [x] Migrations run cleanly on staging
- [x] Existing inbox conversations still load
```

If multiple Linear issues are involved, list each on its own line:

```
Closes HSOS-158
Closes HSOS-160
Refs NEB-302
```

## Anti-patterns

- **Do not** put the issue ID in the branch name to "be safe." Most repos with a Conventional-Commits hook will reject the push and waste a round-trip.
- **Do not** paste a `https://linear.app/...` URL as a substitute. URLs in the body don't trigger the GitHub integration's auto-attach.
- **Do not** add the line "just in case" when there's no matching issue. Linear creates orphan attachments and noisy notifications when IDs don't resolve.
- **Do not** hide the line in a collapsed `<details>` block. The integration parses it from the rendered body.

## Verification

After opening the PR, confirm the attach landed by visiting the Linear issue. Within ~30 seconds you should see:

1. A new GitHub attachment on the right rail with the PR title and a pending/open status badge.
2. The issue's workflow state moved to **In Progress** (default Linear behavior on PR open with `Closes` / `Fixes`).

If neither happens within a minute, your team's Linear ↔ GitHub integration may not be installed on this repo. Ask the workspace admin to check the Linear → Settings → Integrations → GitHub page.
