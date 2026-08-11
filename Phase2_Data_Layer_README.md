# Phase 2 — E-Card Data Layer (review before applying)

Nothing in `src.zip` / `lib.zip` / `firebase.zip` was applied to your project. Everything below is new content, packaged for you to diff and copy in yourself (or hand to me to apply once you've reviewed it). Still no UI — that's Phase 3.

## What's in `lideh_ecards_phase2_new_files.zip`

**Brand new files (nothing to diff — just drop them in):**
- `lib/models/ecard.dart`
- `lib/models/ecard_guest.dart`
- `lib/models/ecard_template.dart`
- `lib/providers/ecard_provider.dart`

**Modified files (full replacement — see `phase2_diffs/` for exactly what changed):**
- `lib/core/constants/strings.dart` — adds `ecardsCollection`, `ecardTemplatesCollection`, `ecardGuestsSubcollection`, `ecardMediaPath`, and the new `EcardOccasion` enum. Every existing constant/enum is untouched.
- `lib/firebase/firestore_service.dart` — adds one new `// ---- E-Cards ----` section at the end of the class (3 new imports at the top). Every existing method is untouched, byte-for-byte.
- `firebase/firestore.rules` — adds one new block for `ecards/{ecardId}`, its `guests/{guestId}` subcollection, and `ecard_templates/{templateId}`, inserted between the existing `events/` and `blogCategories/` blocks. Every existing rule is untouched.
- `firebase/firestore.indexes.json` — adds one composite index (`ecards`: `organizer_id` + `created_at`). Every existing index is untouched.

## How to verify that yourself

The `phase2_diffs/` files are standard unified diffs against the exact files you uploaded — open any of them and everything with a `-` in front is deleted (there shouldn't be any except blank-line-context) and everything with a `+` is new. That's the fastest way to confirm nothing existing moved.

## Design decisions baked into this data layer (recap from Phase 1)

- **Guests live under `ecards/{ecardId}/guests/{guestId}`**, not a flat collection — this is what makes per-organizer isolation possible and fixes the "single global counter" problem in the original Harusi Cards schema.
- **Display IDs (`WD-0001` etc.) are minted inside a Firestore transaction** scoped to one E-Card's `guest_counter`, so two organizers' events can never collide, and two devices adding a guest to the *same* card at the same time can't either.
- **Check-in (`checkInEcardGuest`) is a transaction**, not a read-then-write — closes the race condition that existed in `ScanGateFragment`.
- **QR payload is `ecardId:guestId` only** — no name, no amount, no date. The scan screen (Phase 3) will look everything else up live.
- **`Ecard.fields` and `EcardGuest.category` stay loosely typed** (`Map<String, dynamic>` / free-form string) on purpose — adding a 4th or 5th occasion later only means a new `ecard_templates` document, never a change to these files.
- **One open item, flagged in code, not decided for you:** `deleteEcard()` does not cascade-delete the `guests/` subcollection (Firestore doesn't do that automatically). Left as a comment in `firestore_service.dart` rather than guessed at — worth 30 seconds of your input in Phase 3: either a small Cloud Function, or a batched client-side subcollection delete before removing the parent doc.

## What's still not touched, and won't be until you confirm Phase 3

- `create_event_screen.dart` (the "Create an E-Card for this event?" prompt)
- `organizer_dashboard.dart` (the third Services tile)
- Any new screens under `lib/features/e_cards/`
- `firebase.json` hosting rewrites — no change needed unless you decide on public invitation links (still the one open question from Phase 1)

Say the word and I'll move to Phase 3 (the two dashboard touch points + the E-Card list/create screens), same format — additive files plus small, reviewable diffs on the two existing screens.
