# AGENTS.md

Root contract for every agent: Cursor (Auto, Grok, Composer), Codex, Gemini, Claude, others.
Pair: `AGENTS.md` + `CLAUDE.md` (same rules, Claude-specific hands). All other markdown lives in `docs/`.

## Project in 5 lines

**WAMemory** — Android-first WhatsApp message archive SaaS. User grants Notification Access; app saves notification text locally; deleted WhatsApp messages stay visible **inside WAMemory** (Option A — never restored into WhatsApp).
Stack **LOCKED** (`docs/STACK.md`): Flutter + Dart · Kotlin NotificationListener · SQLite (sqflite) · NestJS API · PostgreSQL later · EN + RU.
App: `wamemory/` · API: `backend/` · Preview: `.research/ui-preview/index.html`.
Tariff: **$5/mo**, 7-day trial, 1 WhatsApp account, ~2 GB media quota (policy in `docs/DECISIONS.md`).
Checks: Flutter `dart analyze` / `flutter test` when SDK present · `npm run build` in `backend/` · Android checklist `docs/ANDROID_TEST_CHECKLIST.md`.

## Boot (every session)

1. Read this file. Voice = caveman (below). Hands = `docs/STRICT.md`.
2. `docs/ORCHESTRATION.md` → pick one `[ ]` in `docs/TASKS.md` (or the explicit user task) → mark `[~]`.
3. Route with `docs/skills/00-router.md` → open **one** domain file + at most **one** skill.
4. Grep → small reads → plan (`docs/skills/02-architect.md` for any new write-path) → edit → verify → report.
5. Mark `[x]` (or `[!]` + reason). Stop.

## Read map

| Need | Open |
|---|---|
| Session flow, handoff | `docs/ORCHESTRATION.md` |
| What is allowed | `docs/STRICT.md` |
| Voice / report | `docs/CAVEMAN.md` |
| Stack lock, commands | `docs/STACK.md` |
| Modules, invariants | `docs/ARCHITECTURE.md` |
| API work | `docs/BACKEND.md` |
| Flutter UI / motion / glass | `docs/FRONTEND.md` |
| Product decisions | `docs/DECISIONS.md` |
| Tests | `docs/TESTING.md` + `docs/ANDROID_TEST_CHECKLIST.md` |
| Privacy copy | `docs/PRIVACY_DRAFT.md` |
| Ship | `docs/DEPLOY.md` |
| Queue | `docs/TASKS.md` |

Do not open `BACKEND.md` and `FRONTEND.md` in one turn unless the task spans both.

## Skills

| Skill | Use when |
|---|---|
| `docs/skills/00-router.md` | Start of every task: map request → files |
| `docs/skills/01-caveman.md` | Always on: voice + report shape |
| `docs/skills/02-architect.md` | New endpoint, table, screen, or state change |
| `docs/skills/03-motion-glass.md` | UI look: glass, surreal aurora, scroll 3D |
| `docs/skills/04-ui-testing.md` | Any test task, any UI change that needs proof |

## Design lock (mobile)

- Palette lead: deep night `#0B141A` / panel `#1F2C34` · accent `#00A884` / `#25D366` · glass frost white @ 6–14% opacity.
- Surreal extras allowed: soft teal–violet aurora mist, specular glass edges — **no** TradeFlow navy/sky CRM look, **no** warehouse/order motifs.
- Surfaces: glassmorphism cards (blur + thin border + soft highlight). Scroll lists use perspective / 3D tilt (respect `disableAnimations` / reduced motion).
- Brand wordmark **WAMemory** is the hero signal on the chats header — not a generic “Chats” only title.

## Caveman (always on)

Chat replies follow `docs/CAVEMAN.md` from the first message. Off only on `stop caveman` / `normal mode`.
Reply in the user's language (usually Uzbek). Code, docs, commits, comments: normal full prose — caveman is chat-only.
End every task with: `Did` / `Files` / `Check` / `Next`.

## Hard rules

1. One session = one task. Fat chat → new session.
2. Prompt = allow-list. Undeclared git, install, deploy, delete, secrets → `Need permit: <thing>.` Stop.
3. Flutter: `features/<area>` · `core/` · `widgets/`. NestJS: module → service → controller. No drive-by refactor, no new package without permit.
4. Invariants in `docs/ARCHITECTURE.md` never break (tenant isolation later, idempotent ingest, deleted flag keeps body, no WhatsApp restore claim).
5. Done = relevant check green + task line updated. Can't run check → say so in `Check`.
6. Never claim WhatsApp account safety or 100% capture of hidden notifications.
7. Do not reintroduce TradeFlow / CRM / warehouse / order domain into this repo.
