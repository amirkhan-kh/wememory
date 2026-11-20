# Deploy

## Contabo — git only

To‘liq: **`docs/CONTABO_DEPLOY.md`**

1. Push: `https://github.com/amirkhan-kh/wememory-mobile` → `main`
2. Server: `cd ~/projects/wememory-mobile && ./scripts/server-update.sh`
3. Yoki Mac: `./scripts/deploy-contabo.sh`

Contabo’da bu loyiha uchun Docker stack **yo‘q**. Dev runtime = **Kiri** (`kdev`).

## Lokal (Mac + Kiri)

1. `kdev on`
2. `kdev up` (compose fayllar bilan)
3. Flutter: `cd wamemory && flutter run`
4. Release APK: `./scripts/build-apk.sh`
5. Kechqurun: `kdev night`

## Production keyinroq

- Play Console AAB
- Privacy/Terms URL
- Payment provider
- Postgres migrations (`backend/prisma/`)
- Never expose Postgres publicly
