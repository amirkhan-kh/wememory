# Telefon + Contabo API

APK telefonda ishlaydi. Live Connect / sync uchun Contabo API kerak.

| Nima | Qiymat |
|------|--------|
| GitHub | `https://github.com/amirkhan-kh/wememory-mobile` |
| Server | `adminamirdev@13.140.202.159` |
| Papka | `~/projects/wememory-mobile` |
| **API URL (telefon)** | `http://13.140.202.159:8090/api` |
| Health | `http://13.140.202.159:8090/api/health` |
| APK yuklash | `http://13.140.202.159:8090/download/wamemory-test.apk` |
| Landing | `http://13.140.202.159:8090/` |

Flutter default shu URL (`WAMEMORY_API_BASE`). Cleartext HTTP Androidda yoqilgan.

---

## A) Mac — push + APK

```bash
cd /Users/amirxon/Desktop/mobile
git add -A
git commit -m "Phone Contabo API + deploy scripts"
git push origin main

# APK (Contabo API baked in)
./scripts/build-apk.sh
# yoki release:
# RELEASE=1 ./scripts/build-apk.sh
```

## B) Server — birinchi marta

```bash
ssh adminamirdev@13.140.202.159
cd ~/projects
git clone https://github.com/amirkhan-kh/wememory-mobile.git
cd wememory-mobile
cp deploy/.env.example deploy/.env
nano deploy/.env   # JWT_SECRET + POSTGRES_PASSWORD ni o‘zgartir
chmod 600 deploy/.env
./scripts/server-update.sh
```

Yoki Mac’dan bir buyruq:

```bash
./scripts/deploy-contabo.sh
```

## C) APK ni serverga qo‘yish

```bash
rsync -az deploy/web/download/wamemory-test.apk \
  adminamirdev@13.140.202.159:projects/wememory-mobile/deploy/web/download/
```

## D) Telefonda

1. Brauzer: `http://13.140.202.159:8090/download/wamemory-test.apk`  
   (release ~35MB; eski 140MB debug ko‘pincha yarim yuklanib **Parse error** berardi)
2. Yuklash **tugaguncha** kut — Files/Downloads da hajm ~35MB bo‘lishi kerak.
3. O‘rnat (Unknown sources). Eski `com.wamemory.app` bo‘lsa — o‘chirib qayta o‘rnat.
4. Och → Settings → **Setup guide / Инструкция** (qadam-baqadam).
5. Settings → **Notification access** yoq (Path A).
6. Settings → **Linked devices** — API: `http://13.140.202.159:8090/api`.
7. Path B: telefon raqam + QR / pairing (ban risk).

Vizual qo‘llanma (brauzer): `docs/SETUP_GUIDE_VISUAL.html`  
(`open docs/SETUP_GUIDE_VISUAL.html`)

## E) Keyingi yangilanish

```bash
# Mac
git push origin main
./scripts/build-apk.sh
rsync -az deploy/web/download/wamemory-test.apk \
  adminamirdev@13.140.202.159:projects/wememory-mobile/deploy/web/download/

# Server
ssh adminamirdev@13.140.202.159
cd ~/projects/wememory-mobile && ./scripts/server-update.sh
```

## Tekshiruv

```bash
curl -fsS http://13.140.202.159:8090/api/health
```

`{"ok":true...}` kutiladi.

## Lokal Mac (Kiri) — faqat dev

```bash
kdev on && kdev up
# Emulator API: WAMEMORY_API_BASE=http://10.0.2.2:3100/api flutter run
```

Telefon Contabo API ishlatadi; Mac Kiri faqat ishlab chiqish uchun.
