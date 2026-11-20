# Contabo — git pull (Docker stack o‘chirilgan)

## Hozirgi server (test)

| Nima | Qiymat |
|------|--------|
| Host | `13.140.202.159` (Ubuntu 24.04, user `adminamirdev`) |
| Papka | `~/projects/wememory-mobile` |
| GitHub | `https://github.com/amirkhan-kh/wememory-mobile` |
| Yangilash | `git pull` / `./scripts/server-update.sh` |
| Runtime | **Lokal Mac: Kiri** (`kdev on` → `kdev up`). Contabo’da bu loyiha Docker stacki **yo‘q**. |
| Eski papka | `~/projects/wamemory` — o‘chirilgan |
| Env backup | `~/backups/wamemory-env-*` (faqat `.env` nusxa) |

Boshqa stacklar (TradeFlow, calculator, mycoffee) alohida — ularga tegilmaydi.

## Muhim tushuncha

| Nima | Qayerda ishlaydi |
|------|------------------|
| WAMemory **APK** | Faqat **Android telefon**da |
| NestJS / Evolution (dev) | Mac **Kiri** orqali (`kdev`) |
| Kod nusxasi | Contabo `git clone` — push → pull |
| WhatsApp arxiv | Telefonda Notification Access |

---

## 1. Birinchi marta (allaqachon qilingan)

```bash
ssh adminamirdev@13.140.202.159
# eski wamemory docker + papka tozalandi
git clone https://github.com/amirkhan-kh/wememory-mobile.git ~/projects/wememory-mobile
```

## 2. Mac — lokal ish (Kiri)

```bash
kdev on
kdev up          # compose → Kiri context
# kechqurun:
kdev night
```

Docker Desktop kerak emas. `DOCKER_CONTEXT=kiri` (`kdev` qo‘yadi).

## 3. Kodni serverga yangilash

```bash
# Mac
git push origin main

# Server
ssh adminamirdev@13.140.202.159
cd ~/projects/wememory-mobile
./scripts/server-update.sh
```

Yoki Mac’dan:

```bash
./scripts/deploy-contabo.sh adminamirdev@13.140.202.159
```

## 4. APK (ixtiyoriy)

APK git’da yo‘q. Kerak bo‘lsa:

```bash
./scripts/build-apk.sh
rsync -az deploy/web/download/wamemory-test.apk \
  adminamirdev@13.140.202.159:projects/wememory-mobile/deploy/web/download/
```

## Muammolar

| Belgi | Yechim |
|-------|--------|
| `git pull` reject | Serverda local edit bor — `git status` |
| Kiri ochilmaydi | `kdev on`, keyin `kdev status` |
| Eski `:8090` ochilmaydi | Kutilgan — Contabo wamemory Docker o‘chirilgan |
