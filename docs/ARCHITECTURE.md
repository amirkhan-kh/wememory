# Architecture

Smallest correct cut. One truth per fact.

## Shape

```
Path A (Notification Access — lower ban risk):
  WhatsApp app ──► notification shade ──► Kotlin NLS ──► ArchiveService ──► SQLite

Path B (Evolution Linked Device — unofficial, ban risk):
  WhatsApp phone ── QR link ──► Evolution API
                                      │ webhook
                                      ▼
                               NestJS /evolution/*
                                      │ HTTPS
                                      ▼
                               Flutter WaBridgeService ──► ArchiveService ──► SQLite
                               Flutter composer ──► Nest sendText ──► Evolution ──► WhatsApp
```

UI (WhatsApp-familiar):
  Chats · Contacts · Global search · Thread (+ composer) · Deleted · Settings (+ Connect QR)

## Module map

| Domain | Mobile | API | Notes |
|---|---|---|---|
| onboarding | `features/onboarding` | — | permissions explainer |
| chats | `features/chats` | — | glass list + 3D scroll |
| contacts | `features/contacts` | — | from archived chats + Evolution contacts later |
| search | `features/search` | — | global title + body search |
| connect | `features/connect` | `evolution/*` | QR / connection state |
| thread | `features/chat_detail` | `evolution/send` | bubbles + send |
| deleted | `features/deleted` | — | filter `is_deleted` |
| settings | `features/settings` | — | notify access, plan, connect entry |
| archive core | `core/services`, `core/db` | — | ingest + idempotency |
| wa bridge | `core/services/wa_bridge_service.dart` | `evolution/*` | Nest proxies Evolution |
| auth | (later) | `auth/*` | register / login / me |
| billing | (later) | `billing/*` | trial, checkout stub |

## Invariants (never break)

1. **Deleted restore into WhatsApp**: never claim or implement rewriting deleted history back into WhatsApp.
2. **Body retained**: marking `is_deleted=true` must not clear `body` / media reference.
3. **Idempotent ingest**: same `notification_key` / Evolution message id must not duplicate a row.
4. **Local-first**: SQLite remains source of truth on device; API/Evolution outage must not wipe it.
5. **Honest limits**: hidden notification text cannot be invented; Evolution may miss events too.
6. **Ban honesty**: never promise WhatsApp account safety when using Evolution / Linked Device.
7. **One account / $5 plan** for MVP subscription model (multi-tenant later).
8. **Tenant isolation** (when sync lands): every cloud row scoped by `user_id`.
9. **Secrets**: JWT / Evolution `AUTHENTICATION_API_KEY` only from env; never commit `.env`.

## Boundaries

- Kotlin bridge only talks notifications ↔ MethodChannel.
- NestJS owns Evolution API key; Flutter never embeds the master Evolution key.
- Flutter `widgets/` = dumb visuals. Features own screens.
