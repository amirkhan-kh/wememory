# Deploy

## Test demo (Contabo) — asosiy yo‘l

To‘liq qadamlar: **`docs/CONTABO_DEPLOY.md`**

Qisqa:

1. Mac: Flutter → `./scripts/build-apk.sh`
2. Mac: `./scripts/deploy-contabo.sh root@SERVER_IP`
3. Server: `deploy/.env` (DOMAIN, JWT, DB password)
4. Ochish: `https://DOMAIN/` → APK download + `/api/health`

Stack fayllari: `deploy/docker-compose.yml`, `deploy/Caddyfile`, `deploy/web/`.

## Mobile (lokal)

1. `./scripts/install-flutter-from-zip.sh`
2. `./scripts/bootstrap-flutter.sh`
3. `cd wamemory && flutter run`
4. Release APK: `./scripts/build-apk.sh`

## Production keyinroq

- Play Console AAB
- Privacy/Terms URL
- Payment provider
- Postgres migrations (`backend/prisma/`)
- Never expose Postgres publicly
