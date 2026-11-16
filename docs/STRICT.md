# STRICT

Prompt = allow-list. Default deny. Hands only — voice is `docs/CAVEMAN.md`.

## Always OK

- Read anything in the repo.
- Edit files inside the task `Scope`.
- Update the task line in `docs/TASKS.md`.
- Run read-only / local checks: `dart analyze`, `npm run build`, `git status`, `git diff`.
- Commands the user typed verbatim.
- Continue / resume Flutter SDK download already started by the user session.

## Need permit

| Area | Examples |
|---|---|
| Git writes | `commit`, `push`, branch, PR, rebase, reset, stash |
| Packages | new npm/pub dependency not named in the task |
| Deletes / renames | Delete user data paths, public API renames |
| Infra | prod deploy, VPS SSH, DB wipe |
| Secrets | `.env*`, keys, `JWT_SECRET` real values |
| Scope creep | Extra apps, TradeFlow port, second framework |
| External | Live payment charges, mass email |

Format: `Need permit: <thing> — <why, 1 line>.` Stop this turn.

## Never (ask twice)

- Force-push to `main`.
- Commit secrets or real chat exports.
- Promise WhatsApp ban immunity.

Unclear → one question. No silent workaround around a denied step.
