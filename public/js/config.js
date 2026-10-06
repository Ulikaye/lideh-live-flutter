/* ===== LideH Live configuration. Fill these in, then commit. =====
   Firebase: Console > Project settings > Your apps > Web app > "firebaseConfig".
   These web keys are meant to be public. Your data is protected by firestore.rules, not by hiding the key. */
const FIREBASE_CONFIG={
   apiKey: "AIzaSyC1bFhsiCSvuUwGJ2Y5gAlezOMk-j8b6qM",
  authDomain: "lideh-live.firebaseapp.com",
  projectId: "lideh-live",
  storageBucket: "lideh-live.firebasestorage.app",
  messagingSenderId: "57278783513",
  appId: "1:57278783513:web:0fb5f009b728091b034a88",
  measurementId: "G-E722N55CRS"
};

// Initialize Firebase
const app = initializeApp(FIREBASE_CONFIG);
const analytics = getAnalytics(app);

FIREBASE_CONFIG.enabled = true;
/* Map: free key from cloud.maptiler.com (restrict it to your domain there). Leave empty to use OpenStreetMap tiles. */
const MAPTILER_KEY="vixedC7CNd4zl39g0nxj";
