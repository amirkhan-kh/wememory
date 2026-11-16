# WAMemory — Yakuniy qarorlar (ChatGPT suhbatidan)

Manba: https://chatgpt.com/share/6af8a793-4920-83eb-bbad-2effa81cfadc  
Holat: MVP — Android birinchi

## Mahsulot
- **Nom:** WAMemory
- **Maqsad:** WhatsApp xabarlarining nusxasini saqlash; o‘chirilganda WAMemory ichida ko‘rsatish
- **Platforma (MVP):** Android APK (iOS keyinroq, Notification Listener cheklovi tufayli)
- **Interfeys:** WhatsApp Dark Mode’ga yaqin (Sarf Pearl / redesign referenslari)
- **Variant:** **A** — o‘chirilgan xabar WAMemory ilovasida ko‘rinadi (asl WhatsApp chatiga qaytarilmaydi)

## Biznes
- Tarif: **$5 / oy**, 1 akkaunt
- Trial: **7 kun**
- Grace period: **30 kun**
- Storage kvota: **2 GB / mijoz**
- Retention: mijoz tanlaydi (30 / 90 / 365)
- Tillar: **EN + RU**
- To‘lov: xalqaro (Lemon Squeezy / Paddle)
- Marketing: dastlab tanishlarga tavsiya; Telegram support

## Texnik stack (bepul / ochiq litsenziya)
| Qism | Texnologiya |
|------|-------------|
| Mobil | Flutter + Dart |
| Android bridge | Kotlin NotificationListenerService |
| Local DB | SQLite (sqflite) |
| Backend (keyin) | NestJS + PostgreSQL |
| Media | Local + keyin R2 |

## MVP funksiyalar
- Shaxsiy chatlar (guruhlar keyinroq)
- Matn, rasm, video, audio, hujjat, voice message
- Status / qo‘ng‘iroq YO‘Q
- Faqat ulanishdan keyingi xabarlar
- O‘chirilgan xabarlar: chat ichida + Deleted bo‘limi
- Qidiruv, export
- Bildirishnoma o‘chirilgan xabar uchun MVP’da YO‘Q

## Chegaralar (mijozga ochiq aytiladi)
- Bildirishnoma kelmagan / matni yashirilgan xabarlar kafolatlanmaydi
- Media alohida mexanizm talab qiladi
- iOS’da Android kabi notification listen yo‘q
- Bu WhatsApp rasmiy mahsuloti emas

## UI referens
- WhatsApp Dark Mode — Sarf Pearl (Dribbble)
- Palette: bg `#0B141A` / `#111B21`, accent `#25D366` / `#00A884`, bubble out `#005C4B`, bubble in `#1F2C34`
