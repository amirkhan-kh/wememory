# Evolution API (Path B)

Unofficial WhatsApp Linked Device bridge. **Account ban risk — no immunity.**

## Contabo (with WAMemory Nest)

```bash
# Network wamemory_internal must exist (WAMemory stack -p wamemory).
cd ~/projects/wamemory/deploy/evolution
cp .env.example .env
# AUTHENTICATION_API_KEY + EVOLUTION_PG_PASSWORD = strong random
# EVOLUTION_PORT=18080 (8080 often taken)

docker compose -p wamemory-evo -f docker-compose.yml -f docker-compose.contabo.yml up -d

# Wire Nest deploy/.env:
#   EVOLUTION_BASE_URL=http://evolution-api:8080
#   EVOLUTION_API_KEY=<same as AUTHENTICATION_API_KEY>
cd ~/projects/wamemory/deploy
docker compose -p wamemory up -d --build api
```

Phone Connect API: `http://SERVER_IP:8090/api`

## Local (Mac / Colima)

```bash
cd deploy/evolution
cp .env.example .env
# WEBHOOK_GLOBAL_URL=http://host.docker.internal:3100/api/evolution/webhook
docker compose up -d
```

- Nest `:3100`. Emulator `http://10.0.2.2:3100/api`
- Real phone same Wi‑Fi: `http://<Mac-LAN>:3100/api`
- Flutter never holds `AUTHENTICATION_API_KEY`

Prefer a **dedicated test number**.
