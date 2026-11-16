# 00 router

Map request → **one** domain file + **≤ 1** skill.

| Request smells like | Domain file | Skill | Scope |
|---|---|---|---|
| Nest endpoint, JWT, billing | `BACKEND.md` | `02-architect` if new | `backend/src/**` |
| Flutter screen, glass, scroll 3D, bubble | `FRONTEND.md` | `03-motion-glass` if look/motion | `wamemory/lib/**` |
| notification listener, MethodChannel | `ARCHITECTURE.md` | `02-architect` | `wamemory/android/**`, `core/services` |
| product / tariff / Option A | `DECISIONS.md` | — | docs only |
| test, checklist, QA | `TESTING.md` | `04-ui-testing` | tests / checklist |
| deploy, VPS, store | `DEPLOY.md` | — | deploy files |
| stack / framework switch | `STACK.md` | — | read-only |
| tone | `CAVEMAN.md` | `01-caveman` | — |

1. Pick row. 2. `Scope: … · Check: …`. 3. Work. 4. Report. 5. Stop.
