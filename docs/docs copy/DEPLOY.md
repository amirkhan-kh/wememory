# Deploy

Only when the prompt asks (task `3.3` or "deploy"). Otherwise `Need permit: deploy`.

## Target

Chosen layout: **frontend on Vercel**, **API + PostgreSQL on one small VPS** (`docker-compose.prod.yml`: `db`, `backend`, `caddy` with automatic HTTPS).
The browser only talks to the Vercel domain; Next rewrites `/api/v1/*` to `API_INTERNAL_URL`, so the auth cookie stays first-party and no CORS preflight is needed.
The same `backend/Dockerfile` also runs on Render / Railway / Fly with a managed PostgreSQL if a VPS is not wanted.

### API host (VPS, 1 vCPU / 1 GB is enough)

1. DNS: `A api.<domain>` → server IP. Open ports 80 and 443 only.
2. `cp .env.example .env`, fill every value (`openssl rand -hex 32` for secrets).
   `SEED_DEMO=true` fills the first boot with demo data (a year of history, several minutes); use it only for a demo instance. The seed runs only on an empty database (no rows in `users`).
3. `docker compose -f docker-compose.prod.yml up -d --build` → wait for `backend` healthy → `curl https://api.<domain>/health`.

### Vercel (frontend)

1. Import the GitHub repo → **Root Directory = `frontend`** (framework Next.js is detected; `frontend/vercel.json` pins install/build and region `fra1`).
2. Environment variables (Production + Preview):
   - `API_INTERNAL_URL=https://api.<domain>` — required; the build warns when it is missing.
   - `NEXT_PUBLIC_SITE_URL=https://<domain>` — optional; canonical/OG/sitemap fall back to the Vercel production domain.
   - `DEMO_LOGIN=manager/demo123` — optional; shows a demo hint on `/login` (leave unset on a real tenant).
3. Deploy. Then set `CORS_ORIGIN` on the API host to the exact Vercel/custom origin and restart `backend`.
4. Custom domain later: add it in Vercel → Domains, update `NEXT_PUBLIC_SITE_URL` and `CORS_ORIGIN`, redeploy.

## Pre-flight (all must be true)

- [ ] `npm run typecheck` green in both packages; `npm run build` green in `frontend/`.
- [ ] `npm run test:e2e` green (`docs/TESTING.md` done bar) on the release commit.
- [ ] Lighthouse 100 on `/` and `/login` (`docs/skills/03-lighthouse.md`).
- [ ] `JWT_SECRET` = random ≥ 32 bytes, not the compose default.
- [ ] `SECRET_KEY` = random ≥ 32 bytes, set once and backed up — it encrypts integration credentials; changing it makes saved secrets unreadable (re-enter them).
- [ ] Public URL is HTTPS: integration inbound URLs (feeds, 1C, PBX) carry the token in the path.
- [ ] Payme / Click endpoint URLs registered in their cabinets point to the HTTPS prod host; run Payme Sandbox (test.paycom.uz) and Click test before switching Payme `Rejim` to "Ishchi".
- [ ] Didox: partner token from a Didox partnership agreement; first send on `Muhit = Test` (stage.goodsign.biz). Clients need `inn`, products `ikpu` + `package_code` before shipping.
- [ ] SAP Service Layer with self-signed cert → `NODE_EXTRA_CA_CERTS=/path/ca.pem` on the backend, never disable TLS checks.
- [ ] `ADMIN_PASSWORD` changed; real tenant: `SEED_DEMO=false` and no demo users. Demo instance: `SEED_DEMO=true` is fine, but every demo user shares `demo123` — never store real data there.
- [ ] `CORS_ORIGIN` = exact prod origin. Cookie `secure` in prod.
- [ ] DB password not `tradeflow`; DB port not public.
- [ ] `.env.example` in git with keys only; real `.env` never committed.

## Ship

1. Backup DB (`pg_dump`) if it holds data.
2. Build images, start: migrations run on backend boot (`core/migrate.ts`) — forward-only.
3. Verify: `GET /health` → `{ ok: true }`, login works, one order flow S1 by hand or `@smoke` tests against prod URL.
4. Report URL, commit, health result.

## Rollback

Previous image tag + restore `pg_dump` if a migration broke data. Never `down -v` on prod.
No surprise SSH: every remote command must be named in the prompt or plan the user approved.
