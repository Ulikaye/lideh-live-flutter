# Event Flow, Admin Approval, CSV Export (review before applying)

Before the diffs — one important clarification, because it affects how you'll actually use this.

## The "thousands of personalized contributor cards" scenario — this already works

Walk through it exactly as you described it: wedding event → E-Card → add contributor "Lewis Emmanuel", category "Single", (the amount fields are part of the wedding template's fields) → that guest gets their own sequential ID (`WD-0001`) → tap into their card → it's rendered with **their** name, **their** category, and **their own unique QR code** → **Share invitation** button generates that exact card as an image and opens WhatsApp/email/Save-to-Photos → repeat for guest #2, #3... #1000, all under the same one E-Card/event. On the day, **Scan & check-in** reads each person's individual QR and confirms them against your event specifically. This has been in place since Phase 2–6.

What I believe actually happened: the block you hit was the **event-picker step** in "Create E-Card" correctly refusing to create a **second, separate** E-Card for an event that already has one (shows "E-Card already exists — View" instead of letting you pick it again) — which is intentional, one E-Card *design* per event, many *guest cards* under it. But there wasn't an obvious, calm path back to that existing E-Card once you'd moved on from the create flow. That's the actual gap, and it's fixed in this batch: **every event's own detail page now has a permanent "E-Card" card** — "Create E-Card" if none exists yet, or "View, add guests, or scan check-ins" if one does — reachable any time, not just right after creating the event.

If I've misunderstood and you genuinely need multiple *separate* E-Card designs attached to one event, tell me and I'll build that instead — but I wanted to explain the reasoning rather than silently build something that might conflict with the guest system already in place.

## 1. New files → `lideh_ecards_flow_admin_NEWFILES.zip`

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_flow_admin_NEWFILES.zip" -DestinationPath "C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter" -Force
```
- `models/ecard_request.dart` — the approval-request record
- `features/admin/admin_ecard_requests_screen.dart` — admin's review queue

## 2. Diffs → `lideh_ecards_flow_admin_diffs.zip`

```powershell
Expand-Archive -Path "C:\Users\uLikaYE\Downloads\lideh_ecards_flow_admin_diffs.zip" -DestinationPath "C:\Users\uLikaYE\Downloads\flow_admin_diffs" -Force
cd C:\Users\uLikaYE\Desktop\lideh_live_flutter\lideh_live_flutter
```
Check all twelve first:
```powershell
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\event.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\strings.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\firestore_service.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\ecard_provider.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\app_router.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\profile_menu_button.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\create_event_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\event_detail_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\create_ecard_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\guest_list_screen.dart.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\firestore.rules.diff"
git apply --check "C:\Users\uLikaYE\Downloads\flow_admin_diffs\firestore.indexes.json.diff"
```
All silent → apply for real (same twelve, drop `--check`), then `flutter analyze`, then deploy rules/indexes separately once you're satisfied:
```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

## What changed, piece by piece

**1. Events default to draft, no popup.** New events are created with `is_published: false` — nothing goes live automatically. The "Create an E-Card for this event?" popup after creation is gone entirely; you land straight on the event's own page instead, where a **Published/Draft toggle** and the **E-Card** card both live permanently, not as a one-time prompt.

Migration safety: **every event that already exists on your live site keeps showing exactly as it does today.** A missing `is_published` field (i.e. every event created before this update) is treated as published, both in the security rule and in the app — only a *new* event explicitly starts as a draft. No backfill needed, nothing on your current live site changes visibility.

**2. Admin approval workflow for E-Card creation.** Per your answer: this gates *creating* a new E-Card for a specific event, scoped per (organizer, event) — not a one-time account-level switch. The organizer sees "This needs admin approval" → **Send request** → **Waiting for admin approval** (this updates itself the instant an admin acts, no refresh needed) → either unlocks straight into the occasion picker, or shows the rejection reason with a **Send request** button to try again.

Admin sees a **live badge count** next to "E-Card Requests" in the profile menu, and a review screen showing the organizer's actual name/email/phone (not just an internal ID) alongside the event, with **Approve** / **Reject** and an optional short reply.

**One deliberate architecture choice, worth knowing:** I built this as its own small collection with a live count query, **not** through your existing `notifications` collection — that collection is Cloud-Function-only by design (`allow create: if false` in your rules), so using it here would have required deploying new backend code. This achieves the same practical result — an admin badge that updates immediately — without needing a Cloud Function deploy. If you'd specifically like this to also appear in your actual notification inbox alongside bookings/reviews, that's a small follow-up (a Cloud Function trigger), not a rebuild.

**3. CSV export.** "Guests" screen now has a download icon in the app bar — exports name/phone/category/check-in status/time for every guest as a CSV, through the same share sheet as the invitation images (WhatsApp, email, Save to Files, or straight download on web).

## What's still open

- The Cloud Function to also surface E-Card requests in the notification inbox (optional, mentioned above).
- Cascade-delete of a card's guest subcollection on E-Card delete — flagged since Phase 2, still open, unrelated to this batch.
- True Firebase Auth account deletion for admin's "delete user" action — flagged since the last batch, still open.

Take your time on this one too — the rules change here is smaller than last time, but the migration-safety reasoning for events (point 1 above) is worth actually reading before you deploy, same spirit as before.
