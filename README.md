# LideH Live

Static site (HTML, CSS, JS) + Firebase (Firestore, Auth, Hosting). Only the `public/` folder is published.

## 1. Firebase (once)
1. console.firebase.google.com > Add project > Build > **Firestore Database** (create, production mode).
2. Build > **Authentication** > Sign-in method > enable **Email/Password** > Users > Add user (your admin login). Copy that user's **UID**.
3. In Firestore create collection **admins**, document ID = your UID, any field (e.g. `role: "admin"`).
4. Project settings > Your apps > Web (</>) > copy `firebaseConfig` into `public/js/config.js`.
5. Publish the rules: paste `firestore.rules` into Firestore > Rules > Publish (or `firebase deploy --only firestore:rules`).

## 2. Enter data
Open `/admin.html` (file: `public/admin.html`), sign in, press **Load sample data** once, then edit or add items per tab. Prices are entered per crop, region and month. The site shows the last 6 months and calculates the outlook from them.

## 3. Map key
Create a free key at cloud.maptiler.com, put it in `MAPTILER_KEY` in `public/js/config.js`, and restrict it to your domain in the MapTiler dashboard.

## 4. GitHub then Firebase Hosting
```
git init && git add . && git commit -m "LideH Live"
git branch -M main && git remote add origin https://github.com/YOU/lideh-live.git && git push -u origin main
npm i -g firebase-tools && firebase login
firebase init hosting:github      # choose your repo; it adds the GitHub Action that deploys on every push
```
Public directory: `public`. Single-page app rewrite: **No**. Do not overwrite `public/index.html`.

## 5. Custom domain
Firebase Console > Hosting > Add custom domain > add the DNS records it shows at your registrar. SSL is automatic.
Then Authentication > Settings > **Authorized domains** > add your domain. Also add it to the MapTiler key restriction.
