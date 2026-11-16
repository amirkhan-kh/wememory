# Frontend (Flutter)

Flutter dark archive UI. Copy languages: **EN** + **RU** (`lib/l10n/`). Design is WhatsApp-familiar **layout**, but **creative surface**: surreal aurora + glassmorphism + scroll-linked 3D.

```
wamemory/lib/
  main.dart
  core/theme/          AppColors, AppTheme, GlassTokens
  core/models/         Chat, Message
  core/db/             AppDatabase
  core/services/       ArchiveService
  features/<screen>/   onboarding, chats, chat_detail, deleted, settings, home
  widgets/             avatar, bubble, glass surfaces, perspective list
  l10n/                app_en.arb, app_ru.arb
```

## Design system

| Token | Value | Role |
|---|---|---|
| `--bg` | `#070B10` → `#0B141A` | Night void |
| `--panel` | `#1F2C34` @ 0.55–0.72 + blur | Glass body |
| `--accent` | `#00A884` | Primary actions |
| `--accentBright` | `#25D366` | Unread / brand |
| `--auroraTeal` | `#1DE0C4` soft | Surreal mist |
| `--auroraViolet` | `#7C6CFF` soft | Surreal mist (low opacity) |
| `--bubbleOut` | `#005C4B` glass-tint | Outgoing |
| `--bubbleIn` | `#1F2C34` | Incoming |
| `--deleted` | `#3A2A1F` + warn edge | Deleted archive |

### Glass rules

- Use `BackdropFilter` blur **8–18** only on small surfaces (tiles, composer, nav) — never fullscreen heavy blur stacks.
- Glass fill: white 6–12% or panel 55% opacity + 1px border `Colors.white.withOpacity(0.08)`.
- Top edge specular highlight (linear gradient) for “frosted” read.
- Prefer CSS-like soft radial aurora in a static `CustomPainter` / stacked `Container` gradients over animated huge blurs.

### Surreal rules

- Background = layered aurora blobs (teal + violet) drifting slowly (opacity/transform only).
- No space/galaxy clichés (stars, planets) unless product marketing asks.
- Brand **WAMemory** stays the strongest text on the chats header.

### Scroll 3D

- Chat list / deleted list: each row maps scroll distance → `Matrix4` perspective tilt (`rotateX` small, scale 0.96–1.0).
- Max tilt ~6–10°; clamp; idle rows settle.
- Respect reduced motion: if accessibility disable animations → identity transform.
- Thread bubbles: gentle parallax (incoming left drift / outgoing right) on scroll — subtle, not dizzy.

## Patterns to copy

- Screen = `SurrealScaffold` (aurora bg) → glass app chrome → content.
- List = `PerspectiveScrollView` wrapping glass tiles.
- Async views: loading · empty · error.
- Destructive: confirm before clear-archive.

## Rules

- One visual kit under `widgets/` + `core/theme`. Icons = custom `WaIcon` / `WaIcons` (`widgets/wa_icons.dart`) — dual-tone stroke set. No Material default icons in product UI. No emoji as UI icons. No third-party UI kit without permit.
- Motion: Flutter `Animation` / scroll notifications — no web GSAP.
- Testability: Semantics / labels on icon-only controls.
- Mobile widths 375 and 390 first; keep bottom nav reachable.
- Do not clone WhatsApp trademark logos; WAMemory wordmark only.

## UI change checklist

- [ ] Loading / empty / error
- [ ] Glass contrast readable (≥ ~4.5:1 text on frosted panels)
- [ ] Reduced-motion path
- [ ] EN string exists; RU string exists for user-visible copy
- [ ] Scroll 3D does not clip unread badges oddly
