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
- [x] 1.7 Notification Access On — egasi Enabled + Android Allowed tasdiqladi
- [x] 1.8 WhatsApp real capture test — boshqa profildan xabar saqlandi; WA’da o‘chirilsa WAMemory’da qoladi (Option A)
- [x] 1.9 `./scripts/build-apk.sh` → `deploy/web/download/wamemory-test.apk` (29M)
- [x] 1.10 Settings WA-layout + launcher icon + strict analyze

## Phase 2 — Contabo test demo
- [x] 2.1 Serverga ko‘chirish — `13.140.202.159:~/projects/wamemory` (rsync, boshqa loyihalarga tegmagan)
- [x] 2.2 `.env` serverda yaratildi (random JWT/DB parol, `chmod 600`, repoda yo‘q)
- [x] 2.3 `docker compose -p wamemory up -d --build` → api + postgres + caddy running
- [x] 2.4 Health: `/api/health` (lokal 3× 200) + register/trial/checkout 3×
- [x] 2.5 APK’ni `deploy/web/download/` ga qo‘yish
- [x] 2.6 Telefonda yangi APK o‘rnatib ochish — egasi ochgan; yangi capture APK yuklanadi

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

## Phase 5 — Evolution + WA-shell (owner override)
- [x] 5.1 Stack unlock + Evolution deploy + Nest bridge + Flutter search/contacts/connect/send
- [x] 5.2 Evolution webhook → Nest → device sync (live incoming + phone pairing)
- [x] 5.5 WA profile setup (phone/name/about/photo) + Settings profile screen
- [x] 5.3b Video/audio full local persist + open/play
- [x] 5.4 Real-device QR connect + APK retest (APK+LAN Nest; egasi telefonda pairing tasdiqlashi kerak)
- [x] 5.6 Contabo Evolution + Nest wire + APK Contabo API base
