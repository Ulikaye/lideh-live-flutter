# Migration Guide: Django LiDeH → Flutter + Firebase

This guide walks through moving an existing Django-based LiDeH
deployment onto this Flutter + Firebase codebase, in the order that
minimizes downtime and risk.

## 1. Map your Django models to Firestore collections

| Django model (typical)      | Firestore collection      | Notes |
|------------------------------|---------------------------|-------|
| `auth.User` + `Profile`      | `users/{uid}`              | uid = Firebase Auth uid, not Django pk |
| `Musician`                   | `musicians/{uid}`          | same uid as the owning user |
| `Organizer` / `Church`       | `organizers/{uid}`         | same uid as the owning user |
| `Skill` (M2M on Musician)    | `skills/{autoId}` + `musicians.skills: string[]` | Firestore has no M2M — denormalize skill *names* directly onto the musician doc |
| `Booking`                    | `bookings/{autoId}`        | status field replaces any Django workflow/state machine |
| `Review`                     | `reviews/{bookingId}`      | keyed by booking id so it's naturally 1:1 |
| `Event`                      | `events/{autoId}`          | |
| `BlogCategory`                | `blogCategories/{autoId}` | |
| `BlogPost`                    | `blogPosts/{autoId}`     | |

Run `python manage.py dumpdata <app_label> --output=django_data.json`
per app to get exportable JSON, then adapt
`scripts/migrate_django_to_firestore.py` to your actual field names —
the script ships with realistic guesses but you must check them
against your `models.py`.

## 2. Users and passwords — the one genuinely hard part

Django password hashes cannot be converted into Firebase Auth
credentials directly (different hashing schemes), except in the narrow
case where you're using PBKDF2/bcrypt/scrypt AND import via Firebase's
[hash-import feature](https://firebase.google.com/docs/auth/admin/import-users).

Two practical options:

**Option A — hash import (best UX, more setup).**
If your Django `PASSWORD_HASHERS` uses a scheme Firebase Auth supports
for import (scrypt, bcrypt, or standard scrypt variants), export the
hash + salt per user and use `auth.import_users()` with the matching
`UserImportHash` configuration. Users log in with their existing
password, no reset required.

**Option B — forced password reset (simpler, some user friction).**
Create each Firebase Auth user with `auth.create_user()` (see the
migration script), leave the password unset, then call
`auth.generate_password_reset_link(email)` for every migrated user and
email it to them (or batch-send via your existing email provider).
Users set a new password on first login.

Most teams use Option B for a first migration and revisit Option A
only if login friction turns out to matter.

## 3. Media files

Django's `MEDIA_ROOT` (profile pictures, musician video thumbnails,
event images, blog images) needs to move into Firebase Storage. For
each file:

1. Read the file from Django's storage backend (local disk or S3).
2. Upload it to the matching Storage path (see `storage.rules` for the
   four folders: `profile_pictures/`, `musician_media/`,
   `event_images/`, `blog_images/`).
3. Get the resulting `getDownloadURL()` and write it into the
   corresponding Firestore document's `*_url` field.

This is intentionally left as `upload_media_placeholder()` in the
migration script — plug in `firebase_admin.storage` there once you've
confirmed your bucket layout.

## 4. Business logic that lived in Django views/forms

Server-side validation and workflow that used to live in Django forms
and view logic is now split two ways:

- **Client-side validation** — `lib/core/utils/validators.dart` and
  the `TextFormField.validator` callbacks in each screen mirror what
  Django's `forms.py` used to check (required fields, email format,
  password length, phone format, positive numbers, YouTube URL shape).
- **Server-side enforcement** — `firebase/firestore.rules` is the
  actual security boundary (client-side validation is just UX; rules
  are what's enforced). Anything that needs to run *transactionally*
  or *on a trigger* (e.g., recomputing a musician's average rating
  after a review, sending a notification when a booking's status
  changes) should become a **Cloud Function** rather than client code
  — the review-rating recompute in `firestore_service.dart` currently
  runs client-side as a simple average for MVP purposes, but moving it
  to a Firestore-triggered Cloud Function is recommended before scale.

## 5. Admin/staff tooling

Django's `/admin/` is not replicated here. Two paths forward:

- **Firebase console** works fine for occasional lookups/edits on
  small collections (`skills`, `blogCategories`).
  as your team, or the [Firestore Admin UI patterns](https://firebase.google.com/docs/firestore) for something more custom.

## 6. Cutover checklist

- [ ] Firestore rules and indexes deployed (`firebase deploy --only firestore,storage`)
- [ ] Skills and blog categories seeded
- [ ] Users migrated + password reset emails sent (or hash-import verified)
- [ ] Media files copied and URLs backfilled
- [ ] Bookings/events/blog posts migrated with FKs remapped to Firebase uids
- [ ] `flutterfire configure` run against the production Firebase project
- [ ] Old Django site put in read-only/maintenance mode during final data sync
- [ ] DNS/App Store links updated to point at the new app
