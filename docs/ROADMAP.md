# WAMemory — qolgan bosqichlar (testgacha)

Holat belgisi: `[ ]` kutilyapti · `[~]` jarayonda · `[x]` tayyor · `[!]` blok

## A. Lokal (Mac) — Flutter kelgach

| # | Bosqich | Natija | Qanday |
|---|---------|--------|--------|
| A1 | Flutter ZIP tugashi | ~1.8 GB fayl | `/tmp/flutter_macos_arm64.zip` yoki Downloads |
| A2 | Flutter o‘rnatish | `flutter --version` | `docs/SETUP_BEGINNER.md` 2-qadam yoki `./scripts/install-flutter-from-zip.sh` |
| A3 | Doctor + licenses | Android ✓ | `flutter doctor` |
| A4 | Bootstrap loyiha | `wamemory` run-ready | `./scripts/bootstrap-flutter.sh` |
| A5 | `flutter run` | Ilova telefonda/emulatorda | `cd wamemory && flutter run` |
| A6 | UI smoke | Glass, 3D, iconlar, deleted | `docs/ANDROID_TEST_CHECKLIST.md` |
| A7 | Notification Access | Settings’da On | Telefonda Special access |
| A8 | WhatsApp capture test | Real xabar arxivda | Checklist 1.4 |
| A9 | Release APK (test) | `wamemory-test.apk` | `./scripts/build-apk.sh` |

## B. Contabo VPS — test ko‘rsatish

APK serverda “ishlamaydi” — u **Android telefonda** ochiladi. Contabo’da:

| # | Bosqich | Natija |
|---|---------|--------|
| B1 | Docker + Caddy | HTTPS sayt + API |
| B2 | NestJS API | `https://<domain>/api/health` |
| B3 | Postgres | users / subscriptions (Prisma) |
| B4 | Test landing | APK yuklab olish + status |
| B5 | APK host | `https://<domain>/download/wamemory-test.apk` |
| B6 | (ixtiyoriy) Flutter web | Brauzerda UI demo |

Yo‘riqnoma: `docs/CONTABO_DEPLOY.md` · fayllar: `deploy/`

## C. Mahsulot keyingi

| # | Bosqich |
|---|---------|
| C1 | Prisma schema ishga tushirish |
| C2 | EN/RU l10n ekranlarga ulash |
| C3 | Lemon Squeezy / Paddle |
| C4 | Media (R2) |
| C5 | Play Console / Privacy final |

## Tayyor kod (kutish paytida yozilgan)

- Flutter UI + WaIcons + glass/3D
- Kotlin NotificationListener
- NestJS auth/billing stub
- Agent docs + setup beginner
- Contabo `deploy/` steki (shu commit/papka)
