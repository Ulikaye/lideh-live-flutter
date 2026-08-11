# Phase 6 — QR Generation & Scan/Check-in (review before applying)

This is the last phase from the original roadmap. Builds on Phases 2–5. Before writing this, I reconstructed your actual current project state from the full diff chain and, as usual now, replayed the whole thing from scratch (Phase 2 → 3 → 4 → 5 → 6, pristine files only) to confirm it all still applies together cleanly. All green.

## ⚠️ Another new package dependency — check this first

The scanner screen uses **`mobile_scanner`** for camera-based QR reading (cross-platform: Android/iOS/Web). Same situation as `qr_flutter` in Phase 4 — I can't see your `pubspec.yaml`, so I can't confirm it's already there.

```powershell
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
flutter pub add mobile_scanner
```

Harmless no-op if already present. If your web build targets older browsers, `mobile_scanner`'s web support uses the browser's native barcode detector where available and falls back reasonably elsewhere — worth a quick manual test on your actual deployed web build once this is in, since camera permissions behave differently in a browser than on-device.

## 1. New files → `lideh_ecards_phase6_NEWFILES_ONLY.zip`

```
lib/features/e_cards/screens/guest_card_screen.dart    one guest's invitation, with their real QR
lib/features/e_cards/screens/scan_ecard_screen.dart     camera scanner + check-in
```

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_phase6_NEWFILES_ONLY.zip" -DestinationPath "C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter" -Force
```

## 2. Modified files → `lideh_ecards_phase6_diffs.zip`

| File | What changed |
|---|---|
| `lib/firebase/firestore_service.dart` | One new method, `watchEcardGuest(ecardId, guestId)` — a single-guest read for the card view, so it doesn't have to load the whole guest list just to show one invitation. |
| `lib/providers/ecard_provider.dart` | One new provider, `ecardGuestProvider`, keyed by a `(String, String)` record. |
| `lib/features/e_cards/screens/ecard_detail_screen.dart` | "Scan & check in" is no longer disabled — every row on this page is now live. |
| `lib/features/e_cards/screens/guest_list_screen.dart` | Tapping a guest (or the new "View card" menu option) opens their invitation with their real QR code. |
| `lib/core/routing/app_router.dart` | Adds 2 imports and 2 routes: `/e-cards/:id/guests/:guestId` and `/e-cards/:id/scan`. |

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_phase6_diffs.zip" -DestinationPath "C:\Users\uLikaYE\Downloads\phase6_diffs" -Force
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
git apply --check "C:\Users\uLikaYE\Downloads\phase6_diffs\firestore_service.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\phase6_diffs\ecard_provider.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\phase6_diffs\ecard_detail_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\phase6_diffs\guest_list_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\phase6_diffs\app_router.dart.diff"
```

All five silent → apply for real (same 5 commands, drop `--check`), then `flutter analyze`.

## How check-in actually works now

- Every guest's QR encodes `ecardId:guestId` — nothing else (see Phase 2's design decision to not leak name/amount into the code itself).
- The scanner checks the `ecardId` half **before** touching Firestore — scanning a QR from a different E-Card (right shape, wrong card) is rejected client-side with a clear message, rather than silently doing nothing or, worse, checking someone into the wrong event.
- The actual check-in (`checkInEcardGuest`) is the transaction built back in Phase 2 — read-verify-write as one atomic step, so two devices scanning the same code at the same moment can't both succeed. Scanning an already-checked-in guest shows their original check-in time instead of just failing silently.
- The result banner (green/amber/red) stays on screen until dismissed, so an organizer running the door isn't left guessing whether a scan landed.

## What's on Android/iOS you'll want to check once

`mobile_scanner` needs camera permission entries in your platform manifests — this is standard for any Flutter camera package and isn't something I can add for you since those files weren't part of your upload:
- **Android**: `<uses-permission android:name="android.permission.CAMERA" />` in `android/app/src/main/AndroidManifest.xml`
- **iOS**: `NSCameraUsageDescription` key in `ios/Runner/Info.plist`

If either is missing, the scan screen will still build, but tapping into it will either crash or silently show a black camera view depending on platform — worth testing on a real device before you consider this phase done, not just on web/emulator.

## What's still open (by design, not oversight)

- **Sharing/exporting** a guest's invitation (image/PDF/link) — the "Share / export invitation" row on the guest card screen is disabled with the same "coming in the next phase" pattern used throughout. This was Phase 7 in the original roadmap; nothing here blocks it.
- **Cascade-delete of a card's guest subcollection** — flagged since Phase 2, still open, unrelated to anything in this phase.
- No new Firestore rules/indexes needed this phase — check-in writes were already covered by the guest subcollection rule from Phase 2.

With this phase, every row on the E-Card detail page now does something real: view card, add & manage guests, scan & check in. That closes out the original 8-phase roadmap's core functionality (Phases 1–6); Phase 7 (sharing/export) and Phase 8 (testing pass) are what's left if you want to keep going.
