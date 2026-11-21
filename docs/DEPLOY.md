# Deploy

## Telefon + Contabo API

To‘liq: **`docs/PHONE_INSTALL.md`** · Contabo: **`docs/CONTABO_DEPLOY.md`**

| | |
|--|--|
| API | `http://13.140.202.159:8090/api` |
| APK | `http://13.140.202.159:8090/download/wamemory-test.apk` (~35MB release; `./scripts/build-apk.sh`) |
| Repo | `https://github.com/amirkhan-kh/wememory-mobile` |

```bash
# Mac
git push origin main
./scripts/build-apk.sh
./scripts/deploy-contabo.sh
rsync -az deploy/web/download/wamemory-test.apk \
  adminamirdev@13.140.202.159:projects/wememory-mobile/deploy/web/download/
```

Server: `git pull` + `docker compose -p wamemory` (8090).  
Lokal Mac: **Kiri** (`kdev on` → `kdev up`) — faqat dev.

## Lokal (Mac + Kiri)

1. `kdev on`
2. `kdev up`
3. `cd wamemory && flutter run`
4. APK: `./scripts/build-apk.sh` (default Contabo API URL)

## Production keyinroq

- Play Console AAB
- Privacy/Terms URL
- Payment provider
- Postgres migrations (`backend/prisma/`)
- Never expose Postgres publicly
