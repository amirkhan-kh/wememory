# Backend

NestJS + TypeScript. API under `/api`. Mobile can run fully offline; API is for accounts + billing (+ future sync).

```
backend/src/
  main.ts
  app.module.ts
  health.controller.ts
  auth/          register, login, me (JWT)
  users/         in-memory store (→ Prisma later)
  billing/       plan, trial, mock checkout
```

## Rules

- Validate with `class-validator` DTOs at the edge.
- JWT secret from `JWT_SECRET` env (dev fallback only for local).
- Never store card PANs — payment provider hosts checkout.
- Subscription state changes only via billing service (later: provider webhooks + idempotency).
- Error messages user-safe; no stack traces to clients.
- When Prisma lands: migrations forward-only; every archive sync row has `user_id`.

## Checklist per endpoint

- [ ] DTO limits (`MinLength`, email)
- [ ] Auth where needed
- [ ] Idempotent webhook handling (billing)
- [ ] Documented in `backend/README.md`
