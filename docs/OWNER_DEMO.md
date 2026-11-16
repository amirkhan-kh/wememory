# WAMemory — egaga ko‘rsatish

## Hozir lokal (darhol)

| Nima | URL |
|------|-----|
| Flutter web UI | http://localhost:8080 |
| Contabo landing (+ APK) | http://localhost:8081 |
| Web app (landing orqali) | http://localhost:8081/app/ |
| APK | http://localhost:8081/download/wamemory-test.apk |

Brauzerda oching. Demo chatlar + Deleted badge + glass UI.

## Contabo’ga joylash (domen + SSH)

1. Serverda Docker borligini tekshiring (`docs/CONTABO_DEPLOY.md`).
2. Mac’da:

```bash
cd /Users/amirxon/Desktop/mobile
./scripts/deploy-contabo.sh root@YOUR_SERVER_IP /opt/wamemory
```

3. `deploy/.env` da `DOMAIN`, `JWT_SECRET`, `POSTGRES_PASSWORD`.
4. Oching:

- `https://DOMAIN/` — landing  
- `https://DOMAIN/app/` — Flutter web UI  
- `https://DOMAIN/download/wamemory-test.apk` — APK (build qilingandan keyin)  

## Android APK (telefon)

JDK 17 o‘rnatilgach:

```bash
cd /Users/amirxon/Desktop/mobile
./scripts/build-apk.sh
./scripts/deploy-contabo.sh root@YOUR_SERVER_IP
```

Telefonda: APK o‘rnatish → Notification Access → WhatsApp test.

## Demo skript (2 daqiqa)

1. Web app oching → Chats → Flor Camden  
2. O‘chirilgan xabar badge’ini ko‘rsating  
3. Deleted tab  
4. (Telefon bo‘lsa) Notification Access + kelgan xabar  

## Chegaralar (egaga ochiq ayting)

- Web demo = UI + demo data (haqiqiy WhatsApp yo‘q)  
- Real arxiv = Android APK + Notification Access  
- WhatsApp ban kafolati yo‘q  
