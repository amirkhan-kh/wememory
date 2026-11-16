# Frontend

Next.js 16 App Router + TS + Tailwind v4. UI copy is written in **Uzbek (Latin)** and shown in 5 languages (`uz`, `uz-Cyrl`, `ru`, `en`, `ky`) — see "Languages" below. Read `frontend/AGENTS.md`: Next 16 has breaking changes — check `frontend/node_modules/next/dist/docs/` before using an API you remember from older Next (e.g. middleware is now `src/proxy.ts`).

```
frontend/src/
  app/                    thin routes: metadata + one feature component. Public: / , /login. Private: /dashboard/**
  features/<domain>/      screens, forms, modals (client components where interactive)
  features/landing/       public landing sections + DemoForm (→ POST /public/leads)
  features/shell/Shell    dashboard layout: sidebar nav, mobile menu, logout
  shared/ui/              Button, Field (Input/Select/Textarea), Modal, Page (PageHeader, KpiCard, SearchInput, Chips, Pagination, Table), Badge, States, Logo, motion, Aurora
  shared/lib/             api (fetch /api/v1, 401 → /login), useApi, usePaged (q debounce 300ms, status, page, limit 15), format, status
  proxy.ts                guards /dashboard/* by tf_token cookie
```

## Patterns to copy

- List screen = `PageHeader` (title + primary action) → `Chips` (status) + `SearchInput` → `Table` → `Pagination`, data via `usePaged("/domain")`.
- Create/edit = `Modal` + `<form onSubmit>` with `Field label="…"` inputs, `required`/`min`/`max` attributes, submit `Button disabled={saving}`, error text from `ApiError.message`.
- Detail screen = `/dashboard/<domain>/[id]` → `features/<domain>/<Domain>Detail.tsx`, back link to the list.
- Destructive / irreversible action = `confirm("…?")` before the call.
- Every async view handles **loading · empty · error** via `shared/ui/States`.

## Rules

- Server components by default; `"use client"` only for interactive leaves.
- One UI kit (`shared/ui`). No new component library. Icons: `lucide-react`. Charts: `recharts`. Motion: `motion` (respect `prefers-reduced-motion`).
- Landing look (futuristic glass + aurora, colours unchanged): `.glass` / `.glass-dark` surfaces, `Backdrop` (fixed aurora mist), `ZoomIn` (section grows on scroll), `SmartAgents` (pinned horizontal rail), `SmoothScroll` (inertial wheel scroll, no package). Palette balance: navy `#32536b` / sky `#9cc3dc` lead, green is a soft glow or status accent — no space/galaxy motifs (stars, orbits, planets). Hero = light glass "console" (`HeroScene` layers split in depth on scroll). Sections take `fx` → `Fx` background (`mesh` / `grid` / `beams` / `lattice`, paused off-screen via `data-on`); `GroupBlock` = sticky glass panel (zig-zag with `flip`) + scroll meter; `Drift` = card parallax; `ZoomIn tilt` = cards rise in perspective. Card grids must divide evenly at every breakpoint (no orphan card in the last row). Keep it Lighthouse 100: soft blobs are `radial-gradient`, never big `blur-*` filters; continuous motion is CSS transform/opacity only; hero text uses `animate-lift` (transform only, never opacity 0) so LCP is not delayed.
- **Testability = accessibility**: every input has a visible `Field label` or `aria-label`; icon-only buttons have `aria-label`; toggles use `aria-pressed`; dialogs have a title. Tests select by role/label, so missing labels are bugs.
- Formatting only via `shared/lib/format` (money `so'm`, dates). Status labels/colors only via `shared/lib/status`.
- Public pages (`/`, `/login`): `metadata` (title, description, canonical, OG), `next/image`, `next/font`, no CLS → Lighthouse 100 (`docs/skills/03-lighthouse.md`).
- Contrast ≥ 4.5:1, focus visible, keyboard reachable (Tab / Enter / Esc closes Modal).
- No Next ↔ other framework swap. No client-side data lib (SWR/React Query) — `useApi` is the one.

## Languages

- `shared/i18n`: the Uzbek (Latin) text **is** the key. Wrap every UI string: `const t = useT(); t("Buyurtmalar")`, slots `t("bugun: {n}", { n })`. Server components: `const { t } = await getI18n()`. Code outside React (`api`, `format`): `tr()`.
- New text → add it to `shared/i18n/messages/<area>.ts` with `ru`, `en`, `ky`. `uz-Cyrl` is transliterated automatically (`cy` overrides, e.g. loanwords like "Kuryer" → "Курьер"). Typecheck fails on a missing key.
- Language = `tf_lang` cookie, chosen with `LangSwitch` ("Til") in the shell and on `/login`; changing it reloads the page. The backend reads the same cookie, so API errors come back in that language.
- Default language is **`ru`** (frontend `DEFAULT_LANG`, backend `core/i18n`). Order: `tf_lang` cookie → `x-lang` header → default (the API also reads `Accept-Language`). `api()` always sends `x-lang`.
- Public site: one static page per language — `/` (ru, served by a proxy rewrite to `/ru`), `/uz`, `/uz-cyrl`, `/en`, `/ky` (`app/[lang]`, `generateStaticParams`, `dynamicParams = false`). Opening a language URL stores it in `tf_lang` (`proxy.ts`); `/` redirects to the stored language when it is not `ru`; `/ru` redirects to `/`. Each page has canonical = own URL + hreflang for all five + `x-default` = `/`; `sitemap.ts` lists them all. Picker: `SiteLangSwitch` (header, mobile menu) and language links in the footer.
- Site copy lives in `features/landing/copy.ts` (`SITE`, same key rules), separate from the dashboard dictionary. Server sections take `lang` and use `siteT(lang)`; client sections use `useCopy()` — the page passes only the current language through `SiteCopyProvider`, so the landing bundle carries no other language. Word order differs per language: highlighted fragments use `{accent}` templates rendered by `Accent`.
- No `app/layout.tsx`: root layouts are `app/[lang]`, `app/login`, `app/dashboard`, all rendering `shared/ui/Document` (`<html lang>` + fonts). Fonts: Plus Jakarta Sans (Latin) and Manrope (Cyrillic); `html:lang(ru|ky|uz-Cyrl)` switches `--font-sans` to Manrope in `globals.css`.
- Data (product, client, warehouse, region names) is not translated. Money, dates, compact numbers follow the language via `shared/lib/format`.

## UI change checklist

- [ ] Loading, empty, error states render.
- [ ] Labels / aria-labels on every new control.
- [ ] Mobile (375px) and desktop (1280px) layouts.
- [ ] New controls added to the matrix in `docs/TESTING.md`.
