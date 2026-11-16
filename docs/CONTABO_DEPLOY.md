# Contabo — test demo joylash

## Hozirgi server (test)

| Nima | Qiymat |
|------|--------|
| Host | `13.140.202.159` (Ubuntu 24.04, user `adminamirdev`) |
| Papka | `~/projects/wamemory` — boshqa stacklar: TradeFlow, calculator, mycoffe |
| Compose project | `wamemory` (`docker compose -p wamemory`) |
| Portlar | `8090` → Caddy HTTP, `8453` → Caddy HTTPS (80/443 ni TradeFlow caddy egallagan) |
| Landing | `http://13.140.202.159:8090/` |
| API health | `http://13.140.202.159:8090/api/health` |
| APK | `http://13.140.202.159:8090/download/wamemory-test.apk` |

Domen ulangach: `deploy/.env` da `SITE_ADDRESS=memory.example.com`, `HTTP_PORT`/`HTTPS_PORT` 80/443 bo‘lishi kerak — buning uchun TradeFlow caddy bilan bitta reverse proxy’ga birlashtirish rejalashtiriladi.

## Muhim tushuncha

| Nima | Qayerda ishlaydi |
|------|------------------|
| WAMemory **APK** | Faqat **Android telefon**da |
| NestJS **API** | Contabo VPS |
| **Download sahifa** | Contabo (`https://domain/`) |
| WhatsApp arxiv | Telefonda Notification Access |

Contabo’da “mobil ilovani serverda ochib ko‘rsatish” emas — **APK yuklab olib telefonga o‘rnatish** + API online.

---

## 1. Server tayyorgarligi (bir marta)

SSH bilan Contabo’ga kiring (Ubuntu 24.04):

```bash
ssh root@YOUR_SERVER_IP
```

Docker o‘rnating (agar yo‘q bo‘lsa):

```bash
apt update
apt install -y ca-certificates curl rsync
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
```

## 2. Domen

DNS’da A record:

```
memory.yourdomain.com  →  YOUR_SERVER_IP
```

## 3. Mac’dan birinchi deploy

1. APK yasang (Flutter tayyor bo‘lgach):

```bash
cd /Users/amirxon/Desktop/mobile
./scripts/build-apk.sh
```

2. Deploy:

```bash
./scripts/deploy-contabo.sh root@YOUR_SERVER_IP /opt/wamemory
```

3. Serverda `.env` ni to‘ldiring (birinchi marta skript to‘xtasa):

```bash
ssh root@YOUR_SERVER_IP
nano /opt/wamemory/deploy/.env
```

```
DOMAIN=memory.yourdomain.com
JWT_SECRET=uzun-random-sir
POSTGRES_PASSWORD=kuchli-parol
```

Qayta:

```bash
cd /opt/wamemory/deploy
docker compose up -d --build
```

## 4. Tekshirish

Brauzer:

- `https://memory.yourdomain.com/` — test landing  
- `https://memory.yourdomain.com/api/health` — `{"ok":true,...}`  
- `https://memory.yourdomain.com/download/wamemory-test.apk` — APK  

Telefonda APK o‘rnating → Notification Access → WhatsApp test.

## 5. Firewall

```bash
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw enable
```

Postgres **tashqariga ochilmasin** (faqat Docker ichki tarmoq).

## 6. Yangilash

Server `~/projects/wamemory` — GitHub repo `amirkhan-kh/wememory` ning `main` branchi (git clone). Kod o‘zgarsa:

```bash
# Mac
git push origin main

# Server
ssh adminamirdev@13.140.202.159
~/projects/wamemory/scripts/server-update.sh    # git pull + docker compose up -d --build + health
```

APK git’da yo‘q (48 MB, `.gitignore` da). Yangi APK chiqsa alohida yuboriladi:

```bash
./scripts/build-apk.sh
rsync -az deploy/web/download/wamemory-test.apk \
  adminamirdev@13.140.202.159:projects/wamemory/deploy/web/download/
```

## Muammolar

| Belgi | Yechim |
|-------|--------|
| HTTPS ishlamaydi | Domen A record + 80/443 ochiq |
| APK 404 | `deploy/web/download/wamemory-test.apk` yo‘q — `build-apk.sh` |
| API offline | `docker compose -f /opt/wamemory/deploy/docker-compose.yml ps` |
| Install blocked | Telefonda “Unknown sources” / browser install ruxsati |
