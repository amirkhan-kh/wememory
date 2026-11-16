# WAMemory API

NestJS stub for auth + billing while the Android app is built.

## Run

```bash
cd backend
npm install
npm run start:dev
```

Health: `GET http://localhost:3000/api/health`

## Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/api/health` | no | Health |
| POST | `/api/auth/register` | no | Register |
| POST | `/api/auth/login` | no | Login |
| GET | `/api/auth/me` | Bearer | Current user |
| GET | `/api/billing/plan` | no | $5 plan |
| POST | `/api/billing/trial` | Bearer | Start 7-day trial |
| GET | `/api/billing/subscription` | Bearer | Subscription state |
| POST | `/api/billing/checkout` | Bearer | Mock checkout URL |

In-memory store only — PostgreSQL/Prisma comes after Flutter runs.
