const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');

async function run() {
  const testEnv = await initializeTestEnvironment({
    projectId: 'demo-test',
    firestore: {
      rules: fs.readFileSync('firestore.rules', 'utf8')
    }
  });
  
  const db = testEnv.authenticatedContext('UEv3sB1xymOR3Bd6NTWMtONC2Sx1').firestore();
  try {
    const p = await db.collection('chats').doc('UEv3sB1xymOR3Bd6NTWMtONC2Sx1_ojkXYdNTMDhLrboZemmiFqBrpUV2').collection('messages').get();
    console.log("SUCCESS Messages");
  } catch(e) {
    console.log("ERROR Messages", e);
  }

  try {
    const p2 = await db.collection('publicVehicles').doc('ojkXYdNTMDhLrboZemmiFqBrpUV2').get();
    console.log("SUCCESS Vehicles");
  } catch(e) {
    console.log("ERROR Vehicles", e);
  }
}
run();
