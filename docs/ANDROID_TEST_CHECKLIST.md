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
- [ ] Banner “Enable” bosiladi → tizim sozlamasi ochiladi
- [ ] WAMemory uchun Notification access ON
- [ ] Ilovaga qaytib status “Enabled” bo‘ladi

## WhatsApp capture (real qurilma)
- [ ] WhatsApp’dan test kontaktiga xabar keladi
- [ ] Bildirishnoma matni ko‘rinadi
- [ ] WAMemory’da yangi chat/xabar paydo bo‘ladi
- [ ] Suhbatdosh xabarni o‘chiradi
- [ ] WAMemory’dagi oldingi nusxa saqlanadi / deleted deb belgilanadi

## Negativ testlar
- [ ] “Message” / yashirin preview → to‘liq matn yo‘qligini qayd etish
- [ ] Ilova o‘chirib yoqilganda SQLite ma’lumotlari qoladi
- [ ] Ikki foydalanuvchi yo‘q (bitta device local) — keyinroq account sync

## Billing (API)
- [ ] `POST /api/auth/register`
- [ ] `POST /api/billing/trial`
- [ ] Mock checkout URL qaytadi
