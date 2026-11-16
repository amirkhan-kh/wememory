# TASKS

`[ ]` todo · `[~]` doing · `[x]` done · `[!]` blocked · 1 session = 1 line  
Batafsil: `docs/ROADMAP.md`

## Phase 0 — Docs + design
- [x] 0.1 WAMemory AGENTS/CLAUDE/docs (TradeFlow olib tashlandi)
- [x] 0.2 Glass + surreal + scroll 3D design lock
- [x] 0.3 Custom WaIcons
- [x] 0.4 Beginner setup + Contabo deploy papkalari

## Phase 1 — Lokal Flutter
- [ ] 1.1 Flutter ZIP tugashi (~1.8 GB)
- [ ] 1.2 `./scripts/install-flutter-from-zip.sh`
- [ ] 1.3 `flutter doctor` + android-licenses
- [ ] 1.4 `./scripts/bootstrap-flutter.sh`
- [x] 1.5 Crash fix + widget 3× (emulator AVD image yo‘q; real telefon USB test keyin)
- [x] 1.6 UI smoke 3× (`flutter test` 15/15 — onboarding/chats/deleted/settings/bubble)
- [ ] 1.7 Notification Access On
- [ ] 1.8 WhatsApp real capture test
- [x] 1.9 `./scripts/build-apk.sh` → `deploy/web/download/wamemory-test.apk` (29M)

## Phase 2 — Contabo test demo
- [x] 2.1 Serverga ko‘chirish — `13.140.202.159:~/projects/wamemory` (rsync, boshqa loyihalarga tegmagan)
- [x] 2.2 `.env` serverda yaratildi (random JWT/DB parol, `chmod 600`, repoda yo‘q)
- [x] 2.3 `docker compose -p wamemory up -d --build` → api + postgres + caddy running
- [x] 2.4 Health: `/api/health` (lokal 3× 200) + register/trial/checkout 3×
- [x] 2.5 APK’ni `deploy/web/download/` ga qo‘yish
- [~] 2.6 Telefonda yangi APK o‘rnatib ochish — crash sababi: stub NDK `llvm-strip` → APK da `libflutter.so` yo‘q edi. Rost NDK r27 o‘rnatildi, release APK 48M (`lib/*.so` bor). Telefon testi kutilmoqda

## Phase 3 — API mustahkamlash
- [x] 3.1 NestJS stub (auth + billing mock)
- [x] 3.2 Prisma schema tayyor (`backend/prisma/schema.prisma`)
- [ ] 3.3 Prisma migrate + Postgres ulash
- [ ] 3.4 Lemon Squeezy / Paddle

## Phase 4 — Ship
- [ ] 4.1 EN/RU l10n wiring
- [ ] 4.2 Privacy/Terms final
- [ ] 4.3 Play Console
- [ ] 4.4 Media / R2
