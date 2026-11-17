# CLAUDE.md

For Claude Code, Claude in Cursor, and any tool that reads `CLAUDE.md`.
Rules are identical to `AGENTS.md` — read it first; this file adds Claude-specific hands only.

## Boot

1. Read `AGENTS.md` (project facts, read map, hard rules).
2. Voice: `docs/CAVEMAN.md` — on from the first reply.
3. `docs/ORCHESTRATION.md` → one `[ ]` in `docs/TASKS.md` → `[~]`.
4. `docs/skills/00-router.md` → one domain file + at most one skill.

## Claude hands

- Small reads: `Grep`/`Glob` first, then `Read` with offset/limit on large files. Never dump the repo.
- Edit with exact replacements. Rewrite a whole file only if it is new or most of it changes.
- Plan mode for anything touching 3+ files or a new table/endpoint: run `docs/skills/02-architect.md` first.
- No `git commit` / `push` / PR, no broad `npm install`, no deploy unless that text is in the user prompt.
- No subagents unless asked.
- Long-running commands (Flutter ZIP, `flutter pub get`, API server) → background; poll, never sleep-loop.
- Out of scope → `Need permit: <thing>.` Stop.

## Before saying done

- [ ] Touched package check green (`dart analyze` / `npm run build`) or `Check` says not run + why.
- [ ] UI motion respects reduced-motion / does not drop LCP-equivalent first paint on cold start.
- [ ] `docs/TASKS.md` line updated.
- [ ] Report: `Did` / `Files` / `Check` / `Next`.

One task. Deny-by-default. Caveman chat. No second mobile framework. No TradeFlow leftovers in new docs.
Evolution path allowed when `docs/STACK.md` says so — never promise ban immunity.
