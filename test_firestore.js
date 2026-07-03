const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json'); // assuming it's here

initializeApp({
  credential: cert(serviceAccount)
});
const db = getFirestore();

async function run() {
  const snapshot = await db.collection('chats').limit(5).get();
  for (const doc of snapshot.docs) {
    console.log("Chat:", doc.id);
    const msgs = await db.collection('chats').doc(doc.id).collection('messages').get();
    msgs.forEach(msg => {
      console.log(" - msg:", msg.data());
    });
  }
}
run().catch(console.error);
