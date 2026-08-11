# Phase 5 — Guest Management (review before applying)

Builds on Phases 2–4. Before writing this, I reconstructed your actual current project state (pristine originals + every diff from Phases 2, 3, and 4 applied in sequence) and generated + tested these against that — plus, as an extra check this time, replayed the *entire* chain from scratch end-to-end (Phase 2 → 3 → 4 → 5) to confirm everything still applies cleanly together. All green.

The data layer for all of this (`addEcardGuest`, `updateEcardGuest`, `deleteEcardGuest`) has been sitting ready since Phase 2 — this phase is purely the UI on top of it.

## 1. New files → `lideh_ecards_phase5_NEWFILES_ONLY.zip`

```
lib/features/e_cards/screens/guest_list_screen.dart    search + add/edit/delete list
lib/features/e_cards/widgets/guest_form_sheet.dart      the add/edit bottom sheet
```

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_phase5_NEWFILES_ONLY.zip" -DestinationPath "C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter" -Force
```

## 2. Modified files → `lideh_ecards_phase5_diffs.zip`

| File | What changed |
|---|---|
| `lib/features/e_cards/screens/ecard_detail_screen.dart` | The "Add & manage guests" row is no longer disabled — tapping it now navigates to the new guest list. |
| `lib/core/routing/app_router.dart` | Adds one import and one route: `/e-cards/:id/guests`. |

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_phase5_diffs.zip" -DestinationPath "C:\Users\uLikaYE\Downloads\phase5_diffs" -Force
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
git apply --check "C:\Users\uLikaYE\Downloads\phase5_diffs\ecard_detail_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\phase5_diffs\app_router.dart.diff"
```

Both silent → apply for real:

```powershell
git apply "C:\Users\uLikaYE\Downloads\phase5_diffs\ecard_detail_screen.dart.diff"
git apply "C:\Users\uLikaYE\Downloads\phase5_diffs\app_router.dart.diff"
```

Then `flutter analyze`.

## What you can do after this phase

- E-Card detail page → **Add & manage guests** → search by name or ID, add a guest (name required, phone optional, category — a dropdown for Wedding/Conference occasions, free text otherwise), edit, or remove.
- Each guest gets their sequential display ID (`WD-0001` etc.) automatically, scoped to that card, exactly as designed in Phase 2.
- Guest cards show a green check icon once checked in — but there's no way to actually check someone in yet from this screen (that's deliberately **Phase 6**, the scanner). Manually toggling check-in status here would blur the line between "guest management" and "attendance," so it's left out on purpose rather than added as a shortcut.

## Still open / not touched in this phase

- QR scan/check-in (Phase 6) — the "Scan & check in" row on the detail page is still disabled.
- Cascade-delete of a card's guest subcollection if you delete the whole E-Card — flagged since Phase 2, still open (unrelated to per-guest delete, which this phase does handle).
- No new Firestore rules/indexes needed — guest reads/writes were already covered by the `ecards/{ecardId}/guests/{guestId}` rule block from Phase 2.

Say the word for **Phase 6** (QR generation + scan/check-in) whenever you're ready — that's the one that finally uses the real QR corner on the card templates and lights up the last disabled row.
