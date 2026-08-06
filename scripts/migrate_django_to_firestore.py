"""
Migrate data out of a Django LiDeH database into Firestore.

This is a STARTING TEMPLATE, not a turnkey script — the exact field
names below are guesses based on typical Django app conventions
(User/Profile/Musician/Organizer/Booking/Event/BlogPost models) and
must be checked against your actual models.py before running.

Usage:
    1. Export your Django data:
         python manage.py dumpdata app_name --output=django_data.json
    2. Fill in FIREBASE_CREDENTIALS_PATH below.
    3. pip install firebase-admin
    4. python migrate_django_to_firestore.py django_data.json

What this script does NOT do (do these separately, see README):
  - Migrate Django's password hashes into Firebase Auth (passwords
    can't be reversed; either import users with a temporary/random
    password and send a "reset your password" email via
    auth.generate_password_reset_link, or use Firebase Auth's
    hash-import feature at https://firebase.google.com/docs/auth/admin/import-users
    if your Django hasher is compatible).
  - Copy uploaded media files from Django's MEDIA_ROOT into Firebase
    Storage — see upload_media_placeholder() below for where that
    logic belongs.
"""

import sys
import json
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore, auth

FIREBASE_CREDENTIALS_PATH = "serviceAccountKey.json"  # download from Firebase console


def init_firebase():
    cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)
    return firestore.client()


def load_dumpdata(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def group_by_model(records):
    grouped = {}
    for record in records:
        grouped.setdefault(record["model"], []).append(record["fields"] | {"pk": record["pk"]})
    return grouped


def migrate_users(db, users):
    """Creates Firebase Auth accounts + users/{uid} Firestore docs.

    Each Django user gets a temporary random password and should be
    sent a password-reset email afterwards (see README migration_guide).
    """
    uid_map = {}  # django pk -> firebase uid, needed to remap foreign keys below
    for user in users:
        try:
            fb_user = auth.create_user(
                email=user["email"],
                email_verified=False,
                password=None,  # Firebase generates one; user resets via emailed link
                display_name=user.get("display_name") or user.get("username", ""),
            )
        except auth.EmailAlreadyExistsError:
            fb_user = auth.get_user_by_email(user["email"])

        uid_map[user["pk"]] = fb_user.uid
        db.collection("users").document(fb_user.uid).set({
            "email": user["email"],
            "user_type": user.get("user_type", "organizer"),
            "display_name": user.get("display_name") or user.get("username", ""),
            "phone": user.get("phone"),
            "location": user.get("location"),
            "bio": user.get("bio"),
            "profile_picture_url": None,  # backfilled by media migration step
            "verified": bool(user.get("verified", False)),
            "created_at": firestore.SERVER_TIMESTAMP,
        })
    return uid_map


def migrate_musicians(db, musicians, uid_map):
    for m in musicians:
        uid = uid_map.get(m["user_id"] or m.get("pk"))
        if not uid:
            continue
        db.collection("musicians").document(uid).set({
            "stage_name": m.get("stage_name", ""),
            "skills": m.get("skills", []),  # remap from Django M2M ids to name strings first
            "availability_notes": m.get("availability_notes"),
            "video_url": m.get("video_url"),
            "youtube_video_id": m.get("youtube_video_id"),
            "starting_price": m.get("starting_price"),
            "years_of_experience": m.get("years_of_experience"),
            "location": m.get("location"),
            "avg_rating": 0,
            "review_count": 0,
            "joined_at": firestore.SERVER_TIMESTAMP,
        })


def migrate_organizers(db, organizers, uid_map):
    for o in organizers:
        uid = uid_map.get(o["user_id"] or o.get("pk"))
        if not uid:
            continue
        db.collection("organizers").document(uid).set({
            "organization_name": o.get("organization_name", ""),
            "church_affiliation": o.get("church_affiliation"),
            "location": o.get("location"),
        })


def migrate_skills(db, skills):
    """Populates the shared skills/ lookup collection used by the
    profile-setup skill picker."""
    for s in skills:
        db.collection("skills").document(str(s["pk"])).set({
            "name": s.get("name", ""),
            "slug": s.get("slug", ""),
        })


def upload_media_placeholder(local_path: str, storage_folder: str) -> str:
    """Wire this up with firebase_admin.storage to actually push files
    from Django's MEDIA_ROOT and return the public download URL. Left
    unimplemented here since it depends on your Storage bucket layout
    and whether files should be re-encoded/resized on the way in."""
    raise NotImplementedError("Hook up firebase_admin.storage() here for your MEDIA_ROOT")


def main():
    if len(sys.argv) < 2:
        print("Usage: python migrate_django_to_firestore.py <dumpdata.json>")
        sys.exit(1)

    db = init_firebase()
    grouped = group_by_model(load_dumpdata(sys.argv[1]))

    # Adjust these model-label strings to match your Django app name,
    # e.g. "accounts.user", "musicians.musician", etc.
    uid_map = migrate_users(db, grouped.get("accounts.user", []))
    migrate_musicians(db, grouped.get("musicians.musician", []), uid_map)
    migrate_organizers(db, grouped.get("organizers.organizer", []), uid_map)
    migrate_skills(db, grouped.get("musicians.skill", []))

    print(f"Migrated {len(uid_map)} users. Remember to:")
    print("  1. Send password-reset emails to all migrated users.")
    print("  2. Migrate uploaded media via upload_media_placeholder().")
    print("  3. Migrate bookings/events/blog posts with the same pattern, remapping FKs through uid_map.")


if __name__ == "__main__":
    main()
