# Evolution API (Path B)

Unofficial WhatsApp Linked Device bridge. **Account ban risk — no immunity.**

## Local bring-up

```bash
cd deploy/evolution
cp .env.example .env
# edit AUTHENTICATION_API_KEY + EVOLUTION_PG_PASSWORD
docker compose up -d --build
```

This compose runs **Evolution + Nest (`wamemory-api`)** on one network so Colima/Mac port quirks do not break Nest→Evolution calls.

- Nest on Mac host: `:3100` (see `backend/.env`). Emulator → `http://10.0.2.2:3100/api`
- Real phone (same Wi‑Fi): `http://<Mac-LAN-IP>:3100/api` — `./scripts/build-apk.sh` injects LAN IP
- Set `CONFIG_SESSION_PHONE_VERSION` (see `.env.example`) or QR/pairing stays empty
- Flutter never holds `AUTHENTICATION_API_KEY`

## Connect flow (one number per subscriber)

1. `docker compose up -d --build`
2. WAMemory → Settings → Connect WhatsApp
3. Enter WhatsApp number with country code (e.g. `998901234567`)
4. Tap **Link this number** → pairing code (or QR)
5. Phone: WhatsApp → Linked devices → Link with phone number → enter code
6. Live messages: Evolution webhook → Nest store → app sync every 2s

Prefer a **dedicated test number** (ban risk).
