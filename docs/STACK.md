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
| WA bridge | Evolution API via **Kiri** (`kdev up`, `deploy/evolution/`) — QR link, webhooks, sendText |
| Local containers | **Kiri** + `kdev on` / `kdev up` (Docker Desktop emas) |
| Contabo phone API | Git clone `wememory-mobile` → `./scripts/server-update.sh` (`docker compose -p wamemory`, port **8090**) |
| Phone API URL | `http://13.140.202.159:8090/api` (`WAMEMORY_API_BASE` in `build-apk.sh`) |
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
| Containers (local) | `kdev on` → `kdev up` | root (Kiri) |
| Evolution (local) | `kdev up` yoki `docker compose -f deploy/evolution/docker-compose.yml up -d` (Kiri context) | root |
| Contabo deploy | `./scripts/deploy-contabo.sh` (git pull + compose up) | root |
| Phone APK | `./scripts/build-apk.sh` → Contabo `/download/` | root |
| Phone guide | `docs/PHONE_INSTALL.md` | docs |
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
