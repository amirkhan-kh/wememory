# Android test checklist (Flutter tayyor bo‘lgach)

## O‘rnatish
- [ ] `./scripts/bootstrap-flutter.sh` muvaffaqiyatli
- [ ] `flutter doctor` da Android toolchain OK
- [ ] Real telefon yoki emulatorda `flutter run`

## UI
- [ ] Onboarding 3 ta slide
- [ ] Chats ro‘yxati demo ma’lumot bilan ochiladi
- [ ] Chat ochiladi, bubble’lar to‘g‘ri (in/out)
- [ ] Deleted xabar sariq badge bilan ko‘rinadi
- [ ] Deleted tabda o‘chirilgan xabarlar bor
- [ ] Settings ochiladi

## Notification Access
- [ ] Yangi APK: `http://13.140.202.159:8090/download/wamemory-test.apk` (48M, capture harden)
- [ ] Banner “Enable” bosiladi → tizim sozlamasi ochiladi
- [ ] WAMemory uchun Notification access ON
- [ ] Ilovaga qaytib banner yo‘qoladi / status Enabled

## WhatsApp capture (real qurilma) — xavfsiz yo‘l = Notification Access (Baileys emas)
- [ ] WhatsApp chat bildirishnomasi ON + preview matn ko‘rinsin
- [ ] Boshqa telefondan **yangi** matn yuborilsin (Flor Camden demo emas)
- [ ] Shade’da title + text ko‘rinsin
- [ ] WAMemory → Chats da **shu kontakt nomi** bilan yangi chat/xabar
- [ ] Suhbatdosh Delete for everyone
- [ ] WAMemory’da oldingi matn qoladi / deleted belgisi (marker notification bo‘lsa)

## Negativ testlar
- [ ] “Message” / yashirin preview → to‘liq matn yo‘qligini qayd etish
- [ ] Ilova o‘chirib yoqilganda SQLite ma’lumotlari qoladi
- [ ] Ikki foydalanuvchi yo‘q (bitta device local) — keyinroq account sync

## Billing (API)
- [ ] `POST /api/auth/register`
- [ ] `POST /api/billing/trial`
- [ ] Mock checkout URL qaytadi

## Path B — real device Connect (5.4)
- [ ] Mac: Colima + `deploy/evolution` up + Nest `:3100` (`npm run start:dev`)
- [ ] Yangi APK (`./scripts/build-apk.sh`) — default API = `http://<Mac-LAN>:3100/api`
- [ ] Telefon va Mac **bir Wi‑Fi**
- [ ] Setup: raqam (test) → ism → about → rasm
- [ ] Settings → Connect WhatsApp → API URL to‘g‘ri → **Link this number**
- [ ] Pairing code **yoki** QR chiqadi
- [ ] WhatsApp → Linked devices → kod/QR (faqat **test** raqam)
- [ ] State `open` / “WhatsApp linked”
- [ ] Boshqa telefondan matn → WAMemory Chats da paydo (sync ~2s)
- [ ] Ban: immunitet yo‘q — asosiy shaxsiy raqam bilan qilma

## Path B — media (5.3)
- [ ] Chat → + yoki camera → Photo/Video/Document
- [ ] Linked bo‘lsa Evolution orqali yuboriladi; aks holda lokal saqlanadi
- [ ] Kelgan rasm: caption + (base64 bo‘lsa) lokal preview
- [ ] Video/audio → local `media/` + SQLite `media_path` (tap to open)
- [ ] Send limits: video ~28 MB, other ~16 MB
