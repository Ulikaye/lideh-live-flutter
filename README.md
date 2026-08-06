# LiDeH Live — Flutter + Firebase

A gospel-musician & event-booking platform connecting churches/organizers
with musicians, rebuilt on Flutter + Firebase (originally a Django app).
Runs on Android, iOS, and web from a single codebase.

## Stack

| Concern         | Choice                                   |
|-----------------|-------------------------------------------|
| UI              | Flutter (Material 3)                      |
| State           | flutter_riverpod                          |
| Routing         | go_router (with auth-aware redirects)     |
| Auth            | Firebase Authentication (email/password)  |
| Database        | Cloud Firestore                           |
| File storage    | Firebase Storage                          |
| Push            | Firebase Cloud Messaging                  |

## Project structure

```
lib/
  core/            theme, colors, strings/constants, responsive & validation helpers, router
  firebase/        thin service wrappers: auth, firestore, storage, fcm
  models/          plain Dart data classes with fromMap/toMap
  providers/       Riverpod providers (one file per domain area)
  features/        one folder per screen area (authentication, home,
                    musicians, bookings, events, blog, dashboard, profile, static)
  shared/widgets/  loading/error/empty states, star rating, responsive app scaffold
firebase/          firestore.rules, storage.rules, firestore.indexes.json
scripts/           Django -> Firestore data migration starting template
```

## Getting started

### 1. Install Flutter
https://docs.flutter.dev/get-started/install — this project targets Flutter 3.22+ / Dart 3.3+.

```
flutter pub get
```

### 2. Create a Firebase project
In the [Firebase console](https://console.firebase.google.com):
1. Create a new project.
2. Enable **Authentication → Email/Password**.
3. Enable **Firestore Database** (start in production mode — the rules
   in `firebase/firestore.rules` already lock it down).
4. Enable **Storage**.
5. (Optional) Enable **Cloud Messaging** for push notifications.

### 3. Connect the app to your project
```
dart pub global activate flutterfire_cli
flutterfire configure
```
This overwrites the placeholder `lib/firebase_options.dart` with real
values and drops `google-services.json` / `GoogleService-Info.plist`
into the native folders automatically. **Do not skip this step** — the
app will throw on launch until you do.

### 4. Deploy security rules and indexes
```
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### 5. Seed reference data
The `skills` and `blogCategories` collections are admin-managed (no
client write access — see `firestore.rules`). Add a few documents by
hand in the Firebase console, or write a one-off Admin SDK script, e.g.:

```js
// seed_skills.js — run with `node seed_skills.js` after `npm i firebase-admin`
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) });
const db = admin.firestore();
const skills = ['Piano', 'Vocals', 'Drums', 'Guitar', 'Bass', 'Choir Direction'];
Promise.all(skills.map(name => db.collection('skills').add({ name, slug: name.toLowerCase() })))
  .then(() => console.log('Seeded skills'));
```

### 6. Run it
```
flutter run                 # mobile/desktop, whatever device is attached
flutter run -d chrome        # web
```

## Data model

All collections are documented inline in `lib/models/*.dart` and
`lib/firebase/firestore_service.dart`. Summary:

- `users/{uid}` — base profile + role (`musician` | `organizer`)
- `musicians/{uid}` — stage name, skills, price, rating (uid-keyed, 1:1 with users)
- `organizers/{uid}` — organization name, church affiliation (uid-keyed)
- `skills/{autoId}` — admin-managed lookup list
- `bookings/{autoId}` — the core entity connecting an organizer + musician + event
- `reviews/{bookingId}` — one review per completed booking
- `events/{autoId}` — organizer-published events, discoverable by musicians
- `blogCategories/{autoId}`, `blogPosts/{autoId}` — content hub

## Migrating existing Django data

See `MIGRATION_GUIDE.md` and `scripts/migrate_django_to_firestore.py`.

## Known placeholders to replace before launch

- `lib/firebase_options.dart` — regenerate with `flutterfire configure`
- `lib/features/static/static_pages.dart` — replace placeholder Terms/Privacy text with your real policies
- App icon / splash screen — not included; add via `flutter_launcher_icons` / `flutter_native_splash` if desired
- Cloud Functions for push notifications on booking events are referenced by `lib/firebase/fcm_service.dart`'s token registration, but the functions themselves aren't included — they're a natural next step (trigger on `bookings/{id}` writes, look up the other party's `fcm_token`, send via `admin.messaging()`)
