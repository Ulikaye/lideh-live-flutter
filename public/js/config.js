/* ===== LideH Live configuration. Fill these in, then commit. =====
   Firebase: Console > Project settings > Your apps > Web app > "firebaseConfig".
   These web keys are meant to be public. Your data is protected by firestore.rules, not by hiding the key. */
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyC1bFhsiCSvuUwGJ2Y5gAlezOMk-j8b6qM",
  authDomain: "lideh-live.firebaseapp.com",
  projectId: "lideh-live",
  storageBucket: "lideh-live.firebasestorage.app",
  messagingSenderId: "57278783513",
  appId: "1:57278783513:web:0fb5f009b728091b034a88",
  measurementId: "G-E722N55CRS"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);


/* Map: free key from cloud.maptiler.com (restrict it to your domain there). Leave empty to use OpenStreetMap tiles. */
const MAPTILER_KEY="https://api.maptiler.com/maps/base-v4/?key=vixedC7CNd4zl39g0nxj#2.4/1.37845/13.32978";
