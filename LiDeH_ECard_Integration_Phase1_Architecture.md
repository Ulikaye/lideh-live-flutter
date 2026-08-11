# LiDeH Live + E-Card Service — Phase 1 Architecture Analysis

**Status:** Analysis only. No code has been changed. `lidehtz.co.tz` and its Firebase project are untouched.

This document is the Phase 1 deliverable from your proposal: an inspection of both codebases, a schema comparison, and a proposed design — reviewed before any implementation begins.

---

## 1. Existing LiDeH Live Architecture (as found in `lib.zip` / `firebase.zip`)

**Stack:** Flutter + Riverpod (StreamProvider-based) + GoRouter + Firebase (Auth, Firestore, Storage, Hosting w/ SSR Cloud Function).

**Structure:**
```
lib/
  core/            routing (GoRouter + auth redirect), theme, constants, validators, responsive utils
  features/        one folder per domain: authentication, home, musicians, bookings,
                    events, dashboard, blog, admin, notifications, profile, static
  firebase/        auth_service, firestore_service, storage_service, fcm_service — single
                    gateway classes; screens never touch FirebaseFirestore.instance directly
  models/          plain Dart classes with fromMap/toMap, mirroring Firestore documents
  providers/       Riverpod StreamProvider/Provider wrappers around firestore_service + auth
  shared/widgets/  AppScaffold, loading/error widgets, buttons, etc.
```

**Key patterns worth preserving exactly:**
- **One `FirestoreService` class** is the single point of contact with Firestore (collection names come from `AppStrings`, not hardcoded). Every existing feature follows this — E-Cards must too.
- **Riverpod `StreamProvider.family`** pattern for per-id/per-owner live queries (e.g. `eventsForOrganizerProvider(organizerId)`).
- **GoRouter** with a `_publicRoutes` set + `_isPublic()` path-prefix check driving a single `redirect:` callback; a `ShellRoute` wraps authenticated app pages in `AppScaffold`. `/admin/**` gets an extra role check inside the same redirect function.
- **Role model:** `users/{uid}` holds `user_type` (`musician | organizer | admin`), immutable after creation (enforced in both the client model and Firestore rules). Role-specific profile data lives in a parallel `musicians/{uid}` or `organizers/{uid}` doc keyed by the same UID.
- **Firestore documents use snake_case field names** (`organizer_id`, `is_cancelled`, `created_at`) — this is the project's actual convention, not the camelCase shown in the original proposal's example schema.
- **Ownership rules pattern:** `allow create/update: if request.resource.data.organizer_id == request.auth.uid` — direct field comparison, no role-claims/custom-claims mechanism in use.
- **Hosting:** `build/web` output, SSR Cloud Function (`ssrRouter`) rewrites `/`, `/musicians/**`, `/blog/**`, `/events/**` for SEO; everything else falls through to `index.html`. A `sitemap` function handles `/sitemap.xml`. **Any new public route needs an explicit rewrite rule or it will just get the SPA shell (no SSR/SEO) — that's fine for E-Cards unless you want indexable public invitation pages.**

**Existing Events domain (what E-Cards must attach to, not replace):**
- `models/event.dart` — `Event { id, organizerId, title, date, time, location, description, imageUrl, isCancelled, createdAt }`, stored at `events/{autoId}`.
- `providers/event_provider.dart` — `upcomingEventsProvider`, `eventByIdProvider(id)`, `eventsForOrganizerProvider(organizerId)`.
- `firestore_service.dart` — `createEvent`, `watchUpcomingEvents`, `watchEvent`, `watchEventsForOrganizer`.
- `features/events/create_event_screen.dart` — simple form (title/date/time/location/description) → `createEvent()` → navigates to `/events/:id`.
- `features/dashboard/organizer_dashboard.dart` — two-tab `TabBarView` (My Bookings / My Events) inside a `Scaffold` with an "add event" AppBar action.
- **Firestore rule:** `events/{eventId}` — public read, create/update/delete gated on `organizer_id == request.auth.uid`.

This is a clean, small surface. E-Cards should be a **new sibling domain that references `events/{eventId}` by ID**, not a modification of the Event model itself.

---

## 2. Existing Harusi Cards Functionality (as found in `src.zip`, Java/Android)

**Architecture:** Single-Activity-ish, Fragment-based, a singleton `FirebaseRepository` as the sole Firebase gateway (same "one gateway class" philosophy LiDeH Live already uses — good sign, this translates cleanly).

**Data model (current, wedding-only, to be generalized — not copied):**
- `event/main` — **one single shared document**, not scoped to any organizer or event: `brideName, groomName, weddingDate, venue, singleAmount, doubleAmount, brideImage (base64 data URL), groomImage (base64 data URL)`.
- `contributors/{id}` — flat collection, doc ID **is** the human-readable ID: `fullName, cardType (Single|Double), amount, date, phone, checkedIn, checkedInTime`.
- `meta/counter` — single global counter document, incremented inside a Firestore `runTransaction` to mint sequential `WC-0001` style IDs.

**Functional pieces to carry forward (translate the *behavior*, not the code):**
| Capability | Where | Notes for Flutter port |
|---|---|---|
| Guest add/edit/delete | `AddContributorFragment`, `FirebaseRepository` | Amount pre-fills from event's single/double pricing — generalize as "template default fields" |
| Guest search | `RecordsFragment` | Pure client-side substring filter over an already-small in-memory list (name/ID contains). Fine to reuse this pattern for small guest lists; add a Firestore query fallback if lists grow large. |
| Sequential human-readable ID | `FirebaseRepository.nextContributorId()` | Uses a **single global counter doc** — this only works because there was one wedding. Must be re-scoped per E-Card event or you'll get ID collisions/leaks across organizers. See §4. |
| QR payload | `QrUtil.buildPayload()` | `id|fullName|cardType|amount|date` pipe-delimited string, scanner reads only the segment before the first `|`. Leaks name/amount into the QR image itself (scannable by anyone with the physical/digital card) — proposal correctly flags this as something to *not* carry forward as-is. |
| Card rendering | `CardRenderer` | Inflates a native layout, binds text + two images (base64 decoded) + generated QR bitmap, then rasterizes the whole view to a `Bitmap` for export. In Flutter this becomes a template `Widget` tree captured via `RepaintBoundary` → PNG, or (cleaner, cross-platform) an HTML/canvas or `pdf` package-rendered card. |
| Check-in / scanning | `ScanGateFragment.handleScanResult()` | ML Kit barcode scan → parse ID → **read-then-write** (`getContributor` then `updateContributor`) to set `checkedIn/checkedInTime`. **This is a race condition**: two devices scanning the same code within milliseconds could both read `checkedIn: false` and both "succeed." Low-probability in a single-door wedding scenario, but worth fixing with a Firestore transaction in the new design. |
| Image handling | `ImageUtils` | Center-crop → resize to 500×500 → JPEG 85% → **base64 data URL stored directly in the Firestore document.** This works but bloats documents and isn't how LiDeH Live already handles images (LiDeH uses Firebase Storage + `image_url` string fields, per `storage_service.dart` / `AppStrings.eventImagesPath` etc.). New E-Card photos should go through the **existing** `StorageService`, not be re-implemented as base64-in-Firestore. |
| CSV export | `CsvExporter` | Simple, portable — same header shape reusable in Dart via `csv`/manual string building. |
| XLSX export | `XlsxExporter` | Same idea, portable via a Dart xlsx package if you want to keep this; otherwise CSV alone may be sufficient for v1. |
| Auth | `LoginActivity` | Firebase email/password — **fully superseded** by LiDeH Live's existing `AuthService`/`authStateProvider`. Nothing to port here except "an authenticated organizer" as the precondition. |

**Nothing here requires an Android-only API that has no Flutter equivalent** — camera scanning (`mobile_scanner` or `google_mlkit_barcode_scanning` plugin), QR generation (`qr_flutter`), image capture/crop (`image_picker` + `image` package), CSV/PDF export are all standard cross-platform Flutter packages. Good — confirms the "no embedded Java, no Android-only path" constraint is achievable.

---

## 3. Firestore Schema Comparison

| Concern | LiDeH Live (current) | Harusi Cards (current) | Conflict? |
|---|---|---|---|
| Field naming | snake_case | camelCase | Yes — new E-Card collections should follow **LiDeH's snake_case convention** for consistency with the rest of the project, not Harusi's camelCase. |
| Event scope | `events/{eventId}`, one per organizer-published event | `event/main`, one single global doc | Total mismatch by design — Harusi was single-tenant (one wedding), LiDeH is multi-tenant (many organizers, many events). The generalized model **must** be per-event, per-organizer. |
| Guest/contributor scope | n/a | `contributors/{id}` flat global collection | Must become scoped under a specific E-Card event, not global, or organizer A's guest list becomes visible/collidable with organizer B's. |
| ID scheme | Firestore auto-IDs everywhere | Global sequential counter (`meta/counter`) | Must be re-scoped to per-E-Card-event counters (see §4) — a single global counter across all organizers is a functional bug in the new multi-tenant context, not just a naming issue. |
| Images | Storage bucket + URL field | Base64 data URL inline in Firestore doc | Must switch to Storage — reuse `StorageService`/`AppStrings` path constants. |
| Security | Per-collection Firestore rules, ownership via `organizer_id == auth.uid` | None shown in the Java source (presumably permissive/shared-admin rules on the original small project) | New rules must follow LiDeH's existing ownership pattern exactly. |

---

## 4. Proposed New E-Card Data Model

Extends the existing `events/{eventId}` domain rather than replacing it, per the constraint. Collection names in **snake_case** to match `AppStrings` convention.

```
events/{eventId}                              ← existing, untouched

ecard_templates/{templateId}                  ← small, admin/seed-managed reference data
  - occasion: "wedding" | "worship" | "conference" | "other"
  - name, preview_image_url, field_schema (list of field keys this template renders)
  - is_active

ecards/{ecardId}                               ← ONE per organizer's event that opts into E-Cards
  - event_id            (references events/{eventId})
  - organizer_id         (== events/{eventId}.organizer_id, duplicated for direct rule checks)
  - occasion             "wedding" | "worship" | "conference" | "other"
  - template_id
  - fields: { ... occasion-specific fields, see below }
  - guest_counter: 0      (per-ecard sequential counter, NOT global — fixes the Harusi bug)
  - created_at, updated_at

ecards/{ecardId}/guests/{guestId}              ← subcollection, doc ID = Firestore auto-ID
  - display_id            e.g. "WD-0001" / "WS-0001" / "CF-0001" (prefix by occasion), generated
                           via a transaction on ecards/{ecardId}.guest_counter — scoped per card,
                           not global
  - full_name
  - phone
  - category              (occasion-specific: "Single"/"Double" for weddings, "VIP"/"General" etc.)
  - checked_in: false
  - checked_in_time: null
  - created_at
```

**`fields` per occasion (matches your proposal's field lists):**
- `wedding`: bride_name, groom_name, wedding_date, venue, bride_image_url, groom_image_url, single_amount, double_amount
- `worship`: church_name, service_title, date, time, venue, theme, scripture, organizer_name
- `conference`: title, organizer_name, date, time, venue, description, registration_category

**QR payload — generalized and less leaky than the original:**
Instead of embedding name/amount/date in plaintext (`id|fullName|cardType|amount|date`), encode only what's needed to look the record up, and look everything else up server-side at scan time:
```
ecardId:guestId
```
The scanner already needs a Firestore round-trip to check/set `checked_in` — no reason to also leak the guest's name and contribution amount into a code that could be photographed or shared. This directly satisfies your proposal's "do not expose unnecessary sensitive information inside the QR code."

**Check-in — use a transaction, not read-then-write:**
```dart
await db.runTransaction((tx) async {
  final snap = await tx.get(guestRef);
  if (snap.data()!['checked_in'] == true) throw AlreadyCheckedInException(...);
  tx.update(guestRef, {'checked_in': true, 'checked_in_time': FieldValue.serverTimestamp()});
});
```
This closes the race condition present in the original Java `getContributor()` → `updateContributor()` pattern.

---

## 5. Proposed Firestore Security Rules (additive block)

Follows the exact ownership pattern already used for `events/{eventId}`:

```
match /ecard_templates/{templateId} {
  allow read: if true;         // public reference data, like skills/
  allow write: if false;       // seeded via Admin SDK / console
}

match /ecards/{ecardId} {
  allow read: if isSignedIn() && resource.data.organizer_id == request.auth.uid;
  // (or `if true` for a subset of fields if you want public invitation pages — see routing below)

  allow create: if isSignedIn()
    && request.resource.data.organizer_id == request.auth.uid
    && get(/databases/$(database)/documents/events/$(request.resource.data.event_id)).data.organizer_id == request.auth.uid;

  allow update: if isSignedIn() && resource.data.organizer_id == request.auth.uid;
  allow delete: if isSignedIn() && resource.data.organizer_id == request.auth.uid;

  match /guests/{guestId} {
    allow read, write: if isSignedIn()
      && get(/databases/$(database)/documents/ecards/$(ecardId)).data.organizer_id == request.auth.uid;
  }
}
```

No changes to any existing rule block. No new admin/role mechanism needed — reuses `isOwner`-style direct-field checks already in the file.

**Public invitation pages** (if wanted): a specific, narrow rule for `allow get` on individual guest docs by *anyone with the link* is possible (`allow get: if true` scoped only to `guests/{guestId}` single-doc reads, never `list`), but this is a deliberate decision to review with you before writing it — it's the one place where "public" and "private guest data" tension actually shows up.

---

## 6. Proposed Routing

Additive to `app_router.dart`, inside the existing authenticated `ShellRoute`:

```
/dashboard                      (existing — organizer sees new "E-Cards" service tile)
/e-cards                         list of the organizer's E-Card events
/e-cards/create?eventId=...      occasion picker → template → field form (pre-fills event_id if
                                  coming from "Create E-Card for this event?" prompt)
/e-cards/:id                     management dashboard (guests, stats, QR scan entry point)
/e-cards/:id/guests/:guestId     guest detail / card preview
/e-cards/:id/scan                check-in scanner screen
```

Public invitation view (only if you decide to allow it — see §5):
```
/e-cards/:id/invite/:guestId     public-readable single card view, NOT added to Hosting SSR
                                  rewrites unless you want it indexed (you likely don't, for
                                  privacy — leave it to fall through to the SPA shell)
```
No changes to `_publicRoutes`, `_isPublic()`, or the SSR rewrite list are required unless you want a public route added.

---

## 7. Proposed Provider Structure

Mirrors `event_provider.dart` exactly:

```
lib/
  models/
    ecard.dart
    ecard_guest.dart
    ecard_template.dart
  firebase/
    firestore_service.dart        (extend with e-card methods, same class, same pattern —
                                    do NOT create a second FirestoreService)
  providers/
    ecard_provider.dart
      - ecardsForOrganizerProvider(organizerId)
      - ecardByIdProvider(ecardId)
      - ecardTemplatesProvider()
      - guestsForEcardProvider(ecardId)
  features/
    e_cards/
      screens/   (list, create, detail/management, scan, guest_detail)
      widgets/   (guest_list_tile, stat_chip, occasion_picker, card_preview)
      templates/ (wedding_card_widget.dart, worship_card_widget.dart, conference_card_widget.dart)
```

---

## 8. Proposed UI Flow

1. Organizer creates an event via the **existing, unmodified** `create_event_screen.dart`.
2. On success (currently `context.go('/events/$id')`), show a one-time prompt: *"Create an E-Card for this event?"* → Yes routes to `/e-cards/create?eventId=$id`; No proceeds as today. This is a single additive branch at the end of `_submit()`, not a rewrite of the screen.
3. Alternatively, `organizer_dashboard.dart` gets a third tile/tab — **Services** section with Musician Booking / Events / E-Cards — per your mockup. Implementation: add a third `Tab` to the existing `TabController(length: 2, ...)` → `length: 3`, or a small services row above the tabs; either is a minimal, additive change to a file that currently has exactly two tabs.
4. `/e-cards/create` → occasion picker (Wedding / Worship / Conference / Other) → dynamic form driven by `ecard_templates` field schema → `createEcard()`.
5. `/e-cards/:id` management screen: guest count, checked-in count, add/search/edit/delete guest, generate card, share, scan entry point — matches your "E-Card Management Dashboard" section directly.

---

## 9. Risks Specific to Migrating a Live Production App

Since `lidehtz.co.tz` has real users right now, these are the guardrails I'd hold myself to across every later phase:

1. **Every phase after this one ships as additive-only code** — new files, new collections, new routes, one new tab. No existing file's public behavior changes except the two narrow, explicitly-called-out touch points (`create_event_screen.dart`'s post-submit branch, `organizer_dashboard.dart`'s tab count).
2. **New Firestore rule blocks only** — nothing in the existing `users/`, `musicians/`, `organizers/`, `bookings/`, `events/`, `blogPosts/`, `notifications/` blocks needs to change. Rules deploys are additive.
3. **New Storage paths only** (e.g. `ecard_media/`) — existing `profile_pictures/`, `musician_media/`, `event_images/`, `blog_images/` rules untouched.
4. **No Hosting rewrite changes required** unless you opt into public invitation pages — and even then it's one new rewrite entry, not a change to existing ones.
5. **Rollout order that lets you verify safety at each step before the next:** ship Phase 2 (data layer + rules, no UI) to a staging build first, confirm existing screens still build/run untouched, then Phase 3 (the two dashboard touch points) behind what's effectively a no-op until an organizer actually taps into E-Cards.
6. **Firestore composite indexes**: new queries (e.g. `guests` by `checked_in`, `ecards` by `organizer_id`) will need entries added to `firestore.indexes.json` — additive, same file, no existing index touched.

---

## What I need from you to move to Phase 2

Nothing blocking — I have what's needed to start the data layer. Two things worth a quick decision from you before Phase 3 (UI), not urgent right now:

- **Public invitation links**: do you want a shareable web page per guest (`/e-cards/:id/invite/:guestId`), or should invitations only be viewed inside the app by the organizer (share as an image/PDF instead)? This only affects one rule and one route — doesn't block Phase 2.
- Everything else in your proposal (occasions, template count, field lists, phased rollout) I'm taking as-is.

I have not modified `src.zip`, `lib.zip`, `firebase.zip`, or `firebase.json`. Ready to start Phase 2 (models, `FirestoreService` extension, rules diff, indexes diff) whenever you confirm — I'd suggest doing that as a diff you can review against the current files before anything is applied.
