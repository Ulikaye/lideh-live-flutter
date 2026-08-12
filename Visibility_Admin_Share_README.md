# Visibility Control, Admin Moderation, Download/Share (review carefully before applying)

This is a bigger batch than usual and touches `firestore.rules` — your account-security file. I verified the **entire project history** replays cleanly from scratch through every phase including this one before sending anything, same as always, but please still read the "What changed in the rules" section below before deploying rules — that's the one file where I'd want you to understand the change, not just trust the diff.

## ⚠️ New package: `share_plus`

```powershell
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
flutter pub add share_plus
```
Used for the working "Share invitation" button (see below). I verified the exact API against current pub.dev docs (`SharePlus.instance.share(ShareParams(...))`) before writing the code — this is the current, non-deprecated API as of the latest release.

## 1. New files → `lideh_ecards_visibility_admin_NEWFILES.zip`

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_visibility_admin_NEWFILES.zip" -DestinationPath "C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter" -Force
```
- `public_ecards_screen.dart` — the public `/e-cards/public` listing (no login required)
- `public_ecard_screen.dart` — read-only single-card view for that listing (deliberately **not** the organizer's management screen — see design note below)
- `admin_ecard_list_screen.dart` — admin: see every E-Card, make public/private, delete
- `admin_user_list_screen.dart` — admin: see every user, deactivate/reactivate/delete
- `account_deactivated_screen.dart` — shown to a blocked user instead of the app

## 2. Guest card screen → full replacement (not a diff)

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_visibility_admin_GUESTCARD_REPLACE.zip" -DestinationPath "C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter" -Force
```
`guest_card_screen.dart` changed enough (StatelessWidget → StatefulWidget, to hold the image-capture key) that a direct overwrite is safer than a diff here — same approach as the wedding template rewrite earlier.

## 3. Diffs → `lideh_ecards_visibility_admin_diffs.zip`

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_visibility_admin_diffs.zip" -DestinationPath "C:\Users\uLikaYE\Downloads\visibility_admin_diffs" -Force
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
```
Check all ten first:
```powershell
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\ecard.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\user_profile.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\musician.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\firestore_service.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\ecard_provider.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\app_router.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\profile_menu_button.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\ecard_detail_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\firestore.rules.diff"
git apply --check "C:\Users\uLikaYE\Downloads\visibility_admin_diffs\firestore.indexes.json.diff"
```
All silent → apply for real (same ten, drop `--check`), then `flutter analyze`.

**Deploy the rules and indexes separately, deliberately, once you've read the section below:**
```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

---

## What changed in `firestore.rules` — read this part

Two genuinely new capabilities, both narrowly scoped:

1. **Public E-Card visibility.** `ecards/{ecardId}` read access now also allows `resource.data.visibility == 'public'` — meaning **anyone, signed in or not**, can read a card the organizer explicitly marked public. Nothing else about that rule changed: private cards are exactly as locked down as before, and the guest list subcollection is **untouched** — a public card never exposes its guest names/phones, regardless of the card's own visibility.

2. **Admin account moderation — the sensitive one.** Previously, admin had **zero write access** to any other user's `users/{uid}` or `musicians/{uid}` document — only read. Now, admin can flip exactly one field (`disabled`) on either, enforced by `affectedKeys().hasOnly(['disabled'])` in the rule itself — not "admin can write to user docs," but "admin can write *this one field* and nothing else." Even if I made a mistake somewhere else in the app code, the rule itself is the actual backstop: a request touching any other field from an admin account gets rejected server-side, regardless of what the client sends.

Both of these were built with the answers you gave me:
- **Deactivate** (reversible) is the everyday action — blocks dashboard access immediately (the router re-checks the moment the profile document changes, not just on next login) and hides a musician from the public directory immediately.
- **Delete** is separated behind a second, more explicit confirmation dialog, and is honest about its real limit: it removes the Firestore profile (so the account is functionally dead — no dashboard, not listed anywhere), but it **cannot** remove the actual Firebase Auth login credential. Only a Cloud Function (Admin SDK) can do that for someone else's account — client code never can, for any app, by design of how Firebase works. I flagged this in the in-app confirmation dialog itself, not just buried here. Let me know if you want that Cloud Function built as a follow-up — deactivate should cover the practical need in the meantime.

## Design note: why there's a separate public card screen

The public listing does **not** route into `EcardDetailScreen` (the organizer's management page). Reusing it would have meant a random visitor from the public listing could technically see the visibility toggle, guest-management link, and scanner entry point for someone else's card — the underlying data rule would still block them from actually doing anything, but showing those controls at all would be misleading and bad practice. `public_ecard_screen.dart` is a genuinely separate, read-only view built specifically for that purpose.

## Download/Share — how it actually works

No server round-trip, no screenshot package: the rendered card widget itself is captured via `RepaintBoundary` → PNG bytes, in memory, then handed to the platform share sheet via `share_plus`. On a phone that opens the native share sheet (WhatsApp, email, Save to Photos, anything else registered) exactly like sharing a photo from the gallery. This replaces the "Coming in the next phase" placeholder that's been sitting there since Phase 6.

## A bug I caught myself this time before sending it

While auditing this batch the same way I fixed the earlier import bugs, I found the exact same class of mistake in two **new** files — `public_ecards_screen.dart` and `admin_ecard_list_screen.dart` both used `EcardOccasion`/`.label` without importing `core/constants/strings.dart` (they only imported `models/ecard.dart`, which doesn't re-export it). I caught these with a systematic sweep before packaging anything, not after you ran `flutter analyze` this time — but flagging it so you know I'm actively checking for that specific failure mode now, not just hoping it doesn't recur.

## What's still open

- Cascade-delete of a card's guest subcollection when the card itself is deleted — flagged since Phase 2, still open, unrelated to this batch.
- The Auth-credential-deletion Cloud Function mentioned above, if you want true full deletion later.
- Organizer accounts don't have an equivalent "public directory" the way musicians do, so deactivating an organizer only blocks their dashboard — there's no separate listing to hide them from. If that's wrong (i.e., organizers do appear somewhere publicly that I haven't seen), tell me and I'll extend the same mirroring pattern used for musicians.

Take your time with this one, especially the rules deploy — ask if anything in the rules section isn't clear before you run `firebase deploy`.
