# Testing

## Mobile

Follow `docs/ANDROID_TEST_CHECKLIST.md`.

Matrix idea (when Flutter SDK available):

| Area | Happy | Empty | Error / denied |
|---|---|---|---|
| Chats | demo rows | no chats | DB open fail |
| Thread | bubbles + deleted badge | empty chat | — |
| Deleted | list | empty copy | — |
| Notifications | access ON + ingest | access OFF banner | channel missing on iOS/desktop |

Repeat flaky UI checks **3×** before calling green.

## API

| Case | Expect |
|---|---|
| `GET /api/health` | 200 `{ ok: true }` |
| register → login → me | 201/200 + Bearer |
| bad password | 401 |
| trial + checkout | subscription object + mock URL |

## Motion / glass

- Reduced motion: no perspective tilt.
- Scroll performance: list stays ≥ ~50 fps on mid device (manual).
