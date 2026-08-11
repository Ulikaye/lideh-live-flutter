# Phase 3 — Organizer Integration (review before applying)

Builds on Phase 2 (make sure those 8 files are already in place — models, provider, and the 4 diffs). Still no guest add/edit/search (Phase 5) and no QR scanning (Phase 6) — this phase wires E-Cards into the existing organizer UI and gets a create → view flow working end-to-end.

## 1. New files → `lideh_ecards_phase3_NEWFILES_ONLY.zip`

```
lib/features/e_cards/screens/ecard_list_screen.dart
lib/features/e_cards/screens/create_ecard_screen.dart
lib/features/e_cards/screens/ecard_detail_screen.dart
```

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_phase3_NEWFILES_ONLY.zip" -DestinationPath "C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter" -Force
```

Safe to `-Force` — none of these paths exist yet.

## 2. Modified files → `lideh_ecards_phase3_diffs.zip`

Three files, each a small, additive change (tested against your real uploaded files before I sent this — same process as Phase 2):

| File | What changed |
|---|---|
| `lib/features/dashboard/organizer_dashboard.dart` | Adds a "Services" row (Musician Booking / Events / E-Cards tiles) above the existing My Bookings / My Events tabs. The `TabController` and its two tabs are untouched — "Events" tile just calls `_tabController.animateTo(1)`. |
| `lib/features/events/create_event_screen.dart` | After an event is published, shows "Create an E-Card for this event?" instead of navigating straight to `/events/$id`. Declining behaves exactly as before. |
| `lib/core/routing/app_router.dart` | Adds 3 imports and 3 routes (`/e-cards`, `/e-cards/create`, `/e-cards/:id`) inside the existing `ShellRoute`, right after `/dashboard`. No existing route changed. |

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_phase3_diffs.zip" -DestinationPath "C:\Users\uLikaYE\Downloads\phase3_diffs" -Force
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
git apply --check "C:\Users\uLikaYE\Downloads\phase3_diffs\organizer_dashboard.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\phase3_diffs\create_event_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\phase3_diffs\app_router.dart.diff"
```

If all three `--check` calls succeed silently, apply for real (drop `--check`):

```powershell
git apply "C:\Users\uLikaYE\Downloads\phase3_diffs\organizer_dashboard.dart.diff"
git apply "C:\Users\uLikaYE\Downloads\phase3_diffs\create_event_screen.dart.diff"
git apply "C:\Users\uLikaYE\Downloads\phase3_diffs\app_router.dart.diff"
```

Then `flutter analyze` before running.

## What you'll be able to do after this phase

- From the Organizer Dashboard, tap the **E-Cards** tile → see your E-Card list (empty at first).
- Tap **+** or **Create E-Card** → pick one of your existing events → pick an occasion (Wedding / Worship / Conference / Other) → pick a template (or continue with default fields, since no templates are seeded yet — that's Phase 4) → fill in the fields → creates the `ecards/{id}` document and takes you to its detail page.
- From **Create Event**, after publishing you'll now be asked whether to create an E-Card for it.
- The E-Card detail page shows the occasion, fields, and live guest/check-in counts (0/0/0 for now) with two disabled rows ("Add & manage guests", "Scan & check in") labeled "Coming in the next phase" — so you can see where Phase 5 and 6 attach, nothing is silently missing.

## One thing worth knowing before you click around

There are no `ecard_templates` documents in Firestore yet — that's intentional, they're admin/seed-managed data per the security rules, and seeding them is Phase 4. Until then, the template-picker step will always show "No templates yet for this occasion — you can continue with the default fields," and the create form falls back to a small hardcoded field list per occasion (defined in `create_ecard_screen.dart`, `_fallbackFields`). This is a deliberate stopgap so the flow works end-to-end now rather than being blocked on Phase 4 — nothing to fix, just don't be surprised the template step is always empty until then.

## Not touched in this phase

- No image upload fields yet (bride/groom photos etc.) — needs a Storage-backed upload flow, folded into Phase 4 with the real templates.
- No cascade-delete of a card's guest subcollection — flagged in `firestore_service.dart` since Phase 2, still open.
- `firestore.rules` / `firestore.indexes.json` — unchanged since Phase 2, nothing new needed for this phase.

Ready for Phase 4 (seed real templates + card preview rendering) or Phase 5 (guest add/edit/search) whenever you say go — Phase 4 unblocks the template picker you'll see is currently empty, Phase 5 lights up the two disabled rows on the detail page. Your call which comes first.
