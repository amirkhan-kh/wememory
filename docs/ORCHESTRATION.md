# Orchestration

1 session = 1 task. Fat chat → new session with a handoff.

## Loop

1. **Boot** — root `AGENTS.md` or `CLAUDE.md`.
2. **Lock** — `docs/STACK.md` is LOCKED.
3. **Pick** — `docs/TASKS.md`: named `[ ]` or top `[ ]` → `[~]`.
4. **Route** — `docs/skills/00-router.md` → one domain file + ≤ 1 skill.
5. **Scope** — one line: `Scope: <folders> · Check: <command>`.
6. **Read** — Grep, small reads, copy nearest pattern.
7. **Plan** — new write-path / screen → `docs/skills/02-architect.md`.
8. **Do** — smallest diff.
9. **Verify** — check from Scope. Red → fix → rerun.
10. **Close** — `[x]` or `[!] <reason>`. Report per `docs/CAVEMAN.md`. Stop.

## Task status

| Mark | Meaning |
|---|---|
| `[ ]` | Not started |
| `[~]` | In progress (only one) |
| `[x]` | Done + verified |
| `[!]` | Blocked + reason |

## Handoff

```
  - handoff: <done> · <next step> · <failing check, 1 line>
```
