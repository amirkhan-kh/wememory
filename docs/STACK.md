# STACK LOCK

Status: **REVISED** — 2026-11-17 (owner override). Previous 2026-11-15 lock replaced.

Product goal: WhatsApp-familiar client (chats, contacts, global search, send/receive) with archive of deleted messages inside WAMemory.

| Layer | Choice |
|---|---|
| Mobile UI | **Flutter** + Dart, Material 3 dark, custom glass widgets |
| Capture path A (safe-ish) | Kotlin `NotificationListenerService` → MethodChannel (local archive) |
| Capture / live path B | **Evolution API** (Baileys-based Linked Device) via NestJS proxy |
| Local DB | SQLite via `sqflite` |
| API | NestJS + TypeScript (`backend/`) |
| WA bridge | Evolution API Docker (`deploy/evolution/`) — QR link, webhooks, sendText |
| Auth | JWT (Bearer) |
| Billing (planned) | Lemon Squeezy / Paddle adapter |
| Cloud media (planned) | Cloudflare R2 |
| Languages | **EN** + **RU** (`wamemory/lib/l10n/`) |

Folders: `wamemory/` · `backend/` · `docs/` · `scripts/` · `deploy/` · `.research/`.

## Commands

| Goal | Command | Where |
|---|---|---|
| Bootstrap Flutter SDK + project | `./scripts/bootstrap-flutter.sh` | root |
| App run | `flutter run` | `wamemory/` |
| Analyze | `dart analyze` / `flutter analyze` | `wamemory/` |
| API dev | `npm run start:dev` | `backend/` |
| API build | `npm run build` | `backend/` |
| Evolution (local) | `docker compose -f deploy/evolution/docker-compose.yml up -d` | root |
| UI preview (no Flutter) | open `.research/ui-preview/index.html` | root |

## Risk (mandatory)

- Evolution / Baileys is **unofficial**. Meta may ban the linked WhatsApp number.
- Never promise ban immunity. Prefer a **dedicated test number**, not the owner’s primary personal account.
- NotificationListener path remains available as lower-risk archive-only mode.

## Forbidden additions

- Second mobile framework (React Native / Kotlin-only UI rewrite)
- Claiming restore-of-deleted-messages **into** WhatsApp chat history
- TradeFlow stack (Next CRM, Express modules, warehouses, orders)
- Heavy GSAP-on-web assumptions inside Flutter — use Flutter animation APIs
