# STACK LOCK

Status: **LOCKED** — 2026-11-15. No switch later without rewriting this file.

| Layer | Choice |
|---|---|
| Mobile UI | **Flutter** + Dart, Material 3 dark, custom glass widgets |
| Android bridge | Kotlin `NotificationListenerService` → MethodChannel `com.wamemory.app/notifications` |
| Local DB | SQLite via `sqflite` |
| API | NestJS + TypeScript (`backend/`) |
| Auth | JWT (Bearer) |
| Billing (planned) | Lemon Squeezy / Paddle adapter — Stripe not assumed for UZ entity |
| Cloud media (planned) | Cloudflare R2 |
| Languages | **EN** + **RU** (`wamemory/lib/l10n/`) |

Folders: `wamemory/` · `backend/` · `docs/` · `scripts/` · `.research/`.

## Commands

| Goal | Command | Where |
|---|---|---|
| Bootstrap Flutter SDK + project | `./scripts/bootstrap-flutter.sh` | root |
| App run | `flutter run` | `wamemory/` |
| Analyze | `dart analyze` / `flutter analyze` | `wamemory/` |
| API dev | `npm run start:dev` | `backend/` |
| API build | `npm run build` | `backend/` |
| UI preview (no Flutter) | open `.research/ui-preview/index.html` | root |

## Forbidden additions

- Second mobile framework (React Native / Kotlin-only UI rewrite)
- WhatsApp Web / Baileys / WAHA inside the **mobile MVP** path (QR archive is a separate future track)
- Claiming restore-into-WhatsApp behaviour
- TradeFlow stack (Next CRM, Express modules, warehouses, orders)
- Heavy GSAP-on-web assumptions inside Flutter — use Flutter animation APIs
