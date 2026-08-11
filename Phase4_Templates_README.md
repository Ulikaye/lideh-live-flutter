# Phase 4 — Templates & Card Rendering (review before applying)

Builds on Phase 2 + Phase 3. Unblocks the template picker that's been showing "no templates yet" since Phase 3, and adds real visual card previews in place of the plain field list.

## ⚠️ Check this before anything else: one new package dependency

`pubspec.yaml` wasn't in any of your uploads, so I can't see or edit it myself. The new template shell (`ecard_card_shell.dart`) renders the QR corner using **`qr_flutter`**, which I have no way to confirm is already in your project.

```powershell
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
flutter pub add qr_flutter
```

If it's already there, that command is a harmless no-op. `image_picker` is also used in Phase 4 (the wedding photo upload), but that one I *did* confirm is already a dependency (it's used in `edit_profile_screen.dart`), so nothing to add there.

## 1. New files → `lideh_ecards_phase4_NEWFILES_ONLY.zip`

```
lib/features/e_cards/templates/ecard_card_shell.dart     shared chrome (background, QR corner) every template reuses
lib/features/e_cards/templates/wedding_card_template.dart
lib/features/e_cards/templates/worship_card_template.dart
lib/features/e_cards/templates/conference_card_template.dart
lib/features/e_cards/templates/ecard_preview.dart        dispatcher — picks the right template by occasion, generic fallback for "Other"
```

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_phase4_NEWFILES_ONLY.zip" -DestinationPath "C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter" -Force
```

## 2. Modified files → `lideh_ecards_phase4_diffs.zip`

| File | What changed |
|---|---|
| `lib/features/e_cards/screens/ecard_detail_screen.dart` | Replaces the plain field-list card with the real `EcardPreview` visual card; the raw field list is kept underneath, collapsed into an `ExpansionTile`, so nothing is lost — just no longer the primary view. |
| `lib/features/e_cards/screens/create_ecard_screen.dart` | Any field key ending in `_image_url` (currently just the wedding template's bride/groom photos) now renders as a tap-to-upload photo picker instead of a text box, using the existing `StorageService` — same pattern as your profile photo upload, nothing new invented. Required before submit, same as a text field. |

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_phase4_diffs.zip" -DestinationPath "C:\Users\uLikaYE\Downloads\phase4_diffs" -Force
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
git apply --check "C:\Users\uLikaYE\Downloads\phase4_diffs\ecard_detail_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\phase4_diffs\create_ecard_screen.dart.diff"
```

Both `--check` silent → apply for real:

```powershell
git apply "C:\Users\uLikaYE\Downloads\phase4_diffs\ecard_detail_screen.dart.diff"
git apply "C:\Users\uLikaYE\Downloads\phase4_diffs\create_ecard_screen.dart.diff"
```

## 3. Seed script → `lideh_ecards_phase4_seed_script.zip`

This is **not** something the app can do for you — `ecard_templates/` has `allow write: if false` in your Firestore rules on purpose (Phase 2), so template documents only ever come from the Admin SDK or console, never the client. This is a small one-time Node script, not a Flutter file — it doesn't go in `lib/`, and it's not something you need to run more than once (or again later, if you add a new template).

```
scripts/seed_ecard_templates.js
```

To run it:
1. `npm install firebase-admin` (anywhere — doesn't need to be inside your Flutter project)
2. Firebase Console → Project settings → Service accounts → **Generate new private key**, save the downloaded file as `serviceAccountKey.json` next to the script. **Do not commit this file to git** — it's a full-access credential for your Firebase project.
3. `node seed_ecard_templates.js`

It creates 3 documents in `ecard_templates/` — `wedding_classic`, `worship_service`, `conference_professional` — matching the field schemas already used as fallbacks in `create_ecard_screen.dart`. It's safe to re-run (upserts by fixed id, won't duplicate).

## What changes for you after this phase

- The template-picker step in **Create E-Card** will show real templates once you've run the seed script — before that, it'll keep showing the "continue with defaults" fallback exactly as in Phase 3, nothing breaks either way.
- Wedding E-Cards now have an actual photo upload step for bride/groom images.
- The E-Card detail page shows a real designed card (rose-toned for weddings, your brand teal for worship, your gold accent for conferences) instead of a plain list — with a QR placeholder box (real per-guest QR codes come with Phase 6, once there's an actual guest to encode).

## Still open / not touched in this phase

- **Guest add/edit/search** (Phase 5) and **QR scan/check-in** (Phase 6) — the two disabled rows on the detail page are unchanged.
- Cascade-delete of a card's guest subcollection — still flagged since Phase 2, still open.
- `firestore.rules` / `firestore.indexes.json` — unchanged since Phase 2.

Let me know once `qr_flutter` is confirmed added and the diffs are applied, and whether you want Phase 5 (guest management) next — that's the one that lights up the first disabled row on the detail page.
