# WAMemory — boshlang‘ich o‘rnatish (Mac, Flutter birinchi marta)

Siz mobil dasturchi bo‘lishingiz shart emas. Quyidagi tartibni **ketma-ket** bajaring.

Kompyuteringiz: **Apple Silicon Mac (arm64)** · Android Studio va Android SDK allaqachon bor.

---

## 0-qadam — Hozircha Flutter’siz ko‘rish

Ilovaning dizaynini brauzerda oching:

1. Finder’da oching: `Desktop/mobile/.research/ui-preview/index.html`
2. Yoki Terminal’da:

```bash
open /Users/amirxon/Desktop/mobile/.research/ui-preview/index.html
```

Bu **haqiqiy telefon ilovasi emas** — faqat UI ko‘rinishi.

---

## 1-qadam — Flutter SDK yuklash tugashini kuting

Fon’da Flutter ZIP yuklanmoqda (`/tmp/flutter_macos_arm64.zip`, taxminan **1.8 GB**).

Tekshirish:

```bash
ls -lh /tmp/flutter_macos_arm64.zip
```

**~1.8 GB** bo‘lsa — tayyor. Hali kichik bo‘lsa — kutib turing (tezlik sekin bo‘lishi mumkin).

Agar yuklash to‘xtab qolsa, Terminal’da qayta davom ettiring:

```bash
curl -L --http1.1 -C - -o /tmp/flutter_macos_arm64.zip \
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.35.5-stable.zip"
```

---

## 2-qadam — Flutter’ni o‘rnatish (bir marta)

Terminal’ni oching (**Applications → Utilities → Terminal** yoki Cursor ichidagi terminal) va **shu buyruqlarni birma-bir** yozing:

```bash
mkdir -p ~/development
rm -rf ~/development/flutter
unzip -q /tmp/flutter_macos_arm64.zip -d ~/development
```

PATH’ga qo‘shish (zsh uchun):

```bash
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

Tekshirish:

```bash
flutter --version
```

Versiya chiqishi kerak (masalan `Flutter 3.35.x`).

---

## 3-qadam — Flutter doctor (nima yetishmasligini ko‘rsatadi)

```bash
flutter doctor
```

Ko‘pincha kerak bo‘ladi:

### A) Xcode Command Line Tools (Mac uchun majburiy)

```bash
xcode-select --install
```

Oyna chiqsa → **Install** → tugaguncha kuting.

### B) Android litsenziyalar

```bash
flutter doctor --android-licenses
```

Har bir savolda `y` bosing.

### C) Android Studio

Sizda allaqachon bor (`/Applications/Android Studio.app`). Ichida:

1. Android Studio’ni oching
2. **More Actions → SDK Manager** (yoki Settings → Languages & Frameworks → Android SDK)
3. **SDK Platforms**: kamida bitta yangi Android (masalan Android 14 / API 34) belgilangan bo‘lsin
4. **SDK Tools**:
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - Android Emulator
5. Apply / OK

Yana:

```bash
flutter doctor
```

`Android toolchain` yonida ✓ bo‘lishi yaxshi. Qizil × bo‘lsa — xabar matnini menga yuboring.

---

## 4-qadam — Loyihani tayyorlash

```bash
cd /Users/amirxon/Desktop/mobile
./scripts/bootstrap-flutter.sh
```

Bu skript:

- Flutter borligini tekshiradi
- `wamemory` ichida Android papkasini to‘ldiradi
- bizning NotificationListener kodini saqlab qoladi
- `flutter pub get` qiladi

Agar skript xato bersa, qo‘lda:

```bash
cd /Users/amirxon/Desktop/mobile/wamemory
flutter create . --project-name app --org com.wamemory --platforms=android
# Keyin android/app/src/main/kotlin va AndroidManifest.xml ni biznikiga qaytarish kerak bo‘lishi mumkin
flutter pub get
```

---

## 5-qadam — Qayerda ishga tushirasiz?

### Variant A — Telefon (tavsiya, WhatsApp testi uchun)

1. Telefonda **Developer options** yoqing  
   (Odatda: Settings → About phone → Build number’ni 7 marta bosing)
2. **USB debugging** yoqing
3. USB kabel bilan Mac’ga ulang
4. Telefonda “Allow USB debugging?” → **Allow**

Tekshirish:

```bash
flutter devices
```

Telefoningiz ro‘yxatda ko‘rinsin.

### Variant B — Emulator (kompyuter ichidagi virtual telefon)

1. Android Studio → **Device Manager** → Create device  
2. Pixel 6 + system image yuklab oling → Finish  
3. ▶ Play bilan emulatorni oching  

```bash
flutter devices
```

**Muhim:** Emulatorda haqiqiy WhatsApp notification arxivlash ishlamaydi (yoki cheklangan). UI ko‘rish uchun yaxshi; WhatsApp testi uchun **haqiqiy Android telefon** kerak.

---

## 6-qadam — Ilovani RUN qilish

```bash
cd /Users/amirxon/Desktop/mobile/wamemory
flutter run
```

Birinchi marta **5–15 daqiqa** ketishi mumkin (yuklab olish + build).

Muvaffaqiyatli bo‘lsa:

1. Onboarding chiqadi → Continue / Get started  
2. Chats ekrani (demo suhbatlar)  
3. Settings → Notification access (telefonda)  

Telefonda: **Settings → Apps → Special access → Notification access → WAMemory → On**

---

## 7-qadam — Nimalarni ko‘rasiz (MVP)

| Joy | Nima |
|-----|------|
| Chats | Glass kartalar, scroll’da 3D |
| Chat ochish | Bubble’lar, deleted badge |
| Deleted | O‘chirilgan xabarlar |
| FAB (+) | Test xabar qo‘shadi |
| Notification Access | Real WhatsApp matnini saqlash (telefon) |

---

## Tez-tez uchraydigan muammolar

| Muammo | Yechim |
|--------|--------|
| `flutter: command not found` | `source ~/.zshrc` yoki Terminal’ni qayta oching |
| `No devices found` | Telefon USB debugging / emulator yoqilganligini tekshiring |
| Build xato / Gradle | Internet kerak; birinchi build uzoq |
| ZIP hali kichik | 1-qadam — yuklashni tugating |
| Faqat dizayn kerak | 0-qadam — HTML preview |

---

## Qisqa cheklist

- [ ] ZIP ~1.8 GB
- [ ] `flutter --version` ishlaydi
- [ ] `flutter doctor` asosan yashil
- [ ] `flutter devices` da qurilma bor
- [ ] `cd wamemory && flutter run` ochildi

Tayyor bo‘lgach keyingi yordam: Notification Access + WhatsApp’dan bitta test xabar.
