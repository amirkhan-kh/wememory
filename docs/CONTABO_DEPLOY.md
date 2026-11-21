# Contabo — git pull + API (telefon)

To‘liq telefon yo‘li: **`docs/PHONE_INSTALL.md`**

## Qisqa

| Nima | Qiymat |
|------|--------|
| Host | `13.140.202.159` · user `adminamirdev` |
| Repo | `https://github.com/amirkhan-kh/wememory-mobile` |
| Papka | `~/projects/wememory-mobile` |
| Compose | `docker compose -p wamemory` (faqat shu loyiha) |
| HTTP | `8090` (80/443 = boshqa stacklar) |
| API | `http://13.140.202.159:8090/api` |
| Lokal Mac | Kiri: `kdev on` → `kdev up` |

## Yangilash

```bash
# Mac
git push origin main
./scripts/deploy-contabo.sh
# APK:
./scripts/build-apk.sh
rsync -az deploy/web/download/wamemory-test.apk \
  adminamirdev@13.140.202.159:projects/wememory-mobile/deploy/web/download/
```

Serverda qo‘lda:

```bash
cd ~/projects/wememory-mobile && ./scripts/server-update.sh
```

## .env

Birinchi marta: `cp deploy/.env.example deploy/.env` → `JWT_SECRET` / `POSTGRES_PASSWORD`.  
`chmod 600 deploy/.env` — repoga **qo‘yilmasin**.

## Evolution (Path B, ixtiyoriy)

```bash
cd ~/projects/wememory-mobile/deploy/evolution
# .env + docker compose -f docker-compose.yml -f docker-compose.contabo.yml up -d
```

Ban risk — test raqam.

## Muammolar

| Belgi | Yechim |
|-------|--------|
| health fail | `docker compose -p wamemory ps` / logs |
| APK 404 | `build-apk.sh` + rsync download/ |
| telefon API | Settings da `http://13.140.202.159:8090/api` |
| git pull dirty | `git checkout -- .` keyin pull |
