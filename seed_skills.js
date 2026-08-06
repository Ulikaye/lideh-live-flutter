const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(require('./serviceAccountKey.json')),
});

const db = getFirestore();

const skills = ['Piano', 'Vocals', 'Drums', 'Guitar', 'Bass', 'Choir Direction'];

Promise.all(
  skills.map((name) => db.collection('skills').add({ name, slug: name.toLowerCase() }))
)
  .then(() => {
    console.log(`Seeded ${skills.length} skills.`);
    process.exit(0);
  })
  .catch((err) => {
    console.error('Seeding failed:', err);
    process.exit(1);
  });
