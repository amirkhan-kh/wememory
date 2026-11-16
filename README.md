# WAMemory

Android-first WhatsApp message archive. Deleted messages stay visible **inside WAMemory** (Option A).

## Holat

| Qism | Holat |
|------|--------|
| App kod + glass/3D/WaIcons | Tayyor |
| NestJS API stub | Tayyor |
| Prisma schema (tayyor, ulanmagan) | Tayyor |
| Contabo deploy steki | Tayyor (`deploy/`) |
| Flutter SDK / run | ZIP yuklanishi kutilmoqda |
| Contabo’da live demo | Flutter + APK’dan keyin |

## Bosqichlar

1. **Lokal:** `docs/SETUP_BEGINNER.md` + `docs/ROADMAP.md` (A1–A9)  
2. **Contabo test:** `docs/CONTABO_DEPLOY.md` (B1–B6)  
3. Navbat: `docs/TASKS.md`

## Tez buyruqlar (Flutter o‘rnatilgach)

```bash
./scripts/install-flutter-from-zip.sh
./scripts/bootstrap-flutter.sh
cd wamemory && flutter run

# Contabo uchun APK + deploy
./scripts/build-apk.sh
./scripts/deploy-contabo.sh root@YOUR_SERVER_IP
```

## Preview (Flutter’siz)

```bash
open .research/ui-preview/index.html
```
