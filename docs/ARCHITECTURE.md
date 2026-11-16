# Architecture

Smallest correct cut. One truth per fact.

## Shape

```
WhatsApp app ──► Android notification shade
                      │
                      ▼
            WhatsAppNotificationListener (Kotlin)
                      │ MethodChannel
                      ▼
            ArchiveService (Flutter) ──► SQLite (chats, messages)
                      │
                      ▼
            UI: Chats · Thread · Deleted · Settings

Optional cloud (later):
  Flutter ── HTTPS ──► NestJS API ──► PostgreSQL
                              └──► Lemon Squeezy / Paddle webhooks
```

## Module map

| Domain | Mobile | API | Notes |
|---|---|---|---|
| onboarding | `features/onboarding` | — | permissions explainer |
| chats | `features/chats` | — | glass list + 3D scroll |
| thread | `features/chat_detail` | — | bubbles, deleted badge |
| deleted | `features/deleted` | — | filter `is_deleted` |
| settings | `features/settings` | — | notification access, plan |
| archive core | `core/services`, `core/db` | — | ingest + idempotency |
| auth | (later) | `auth/*` | register / login / me |
| billing | (later) | `billing/*` | trial, checkout stub |

## Invariants (never break)

1. **Option A**: deleted content is shown only inside WAMemory; never written back into WhatsApp.
2. **Body retained**: marking `is_deleted=true` must not clear `body` / media reference.
3. **Idempotent ingest**: same `notification_key` must not duplicate a message row.
4. **Local-first**: archive works offline after Notification Access; API outage must not wipe SQLite.
5. **Honest limits**: hidden / missing notification text cannot be invented.
6. **One account / $5 plan** for MVP subscription model.
7. **Tenant isolation** (when sync lands): every row scoped by `user_id`; never leak across users.
8. **Secrets**: JWT / payment keys only from env; never commit `.env`.

## Boundaries

- Kotlin bridge only talks notifications ↔ MethodChannel. No business UI in Kotlin.
- Flutter `widgets/` = dumb visuals (glass, avatar, bubble). Features own screens.
- NestJS: validation at DTO edge; services own rules; in-memory store is temporary until Prisma.
