# WAMemory

Android-first WhatsApp archive + live bridge. Deleted copies stay **inside WAMemory**.

## Telefon (Contabo)

| | |
|--|--|
| API | `http://13.140.202.159:8090/api` |
| APK | `http://13.140.202.159:8090/download/wamemory-test.apk` |
| Guide | **`docs/PHONE_INSTALL.md`** |

```bash
git push origin main
./scripts/build-apk.sh
./scripts/deploy-contabo.sh
rsync -az deploy/web/download/wamemory-test.apk \
  adminamirdev@13.140.202.159:projects/wememory-mobile/deploy/web/download/
```

## Lokal Mac (Kiri)

```bash
kdev on && kdev up
cd wamemory && flutter run
```

## Docs

- `docs/PHONE_INSTALL.md` — telefon + server
- `docs/CONTABO_DEPLOY.md` — Contabo
- `docs/TASKS.md` — navbat
- `AGENTS.md` — agent qoidalari
