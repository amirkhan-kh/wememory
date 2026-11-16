# WAMemory (Android MVP)

WhatsApp-like dark archive app. Deleted messages stay visible **inside WAMemory** (Option A).

## What was decided (from ChatGPT plan)

- Platform: **Android first** (Flutter)
- Capture: **Notification Listener** (no WhatsApp login / no QR for MVP mobile path)
- UI: WhatsApp Dark Mode style (Sarf Pearl / redesign refs)
- Local DB: SQLite
- Billing later: $5/mo · 7-day trial · EN/RU

## Screens

1. Onboarding  
2. Chats (list + stories row + FAB)  
3. Chat thread (bubbles, deleted badge, voice preview)  
4. Deleted messages  
5. Settings (notification access + limits)

## Setup

```bash
# 1) Install Flutter SDK (stable), then:
export PATH="$PATH:$HOME/development/flutter/bin"

# 2) Bootstrap Android/iOS folders if missing:
cd wamemory
flutter create . --project-name wamemory --org com.wamemory

# 3) Keep our Kotlin sources (MainActivity + NotificationListener)
# 4) Merge AndroidManifest service entry if flutter create overwrote it

flutter pub get
flutter run
```

On device: **Settings → Notification access → enable WAMemory**.

## Demo without WhatsApp

Use the FAB / menu **Simulate WhatsApp message**. Demo chats include already-deleted messages.

## Limits (show to users)

- Only text visible in notifications can be archived.
- Hidden / muted / “message” placeholders cannot be recovered.
- Not affiliated with WhatsApp / Meta.
- iOS cannot use the same notification listener API.

## Research notes

See `../docs/DECISIONS.md` and `../.research/`.
