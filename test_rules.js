const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');

async function runTest() {
  let testEnv = await initializeTestEnvironment({
    projectId: 'mymove-cb624',
    firestore: {
      rules: fs.readFileSync('firestore.rules', 'utf8'),
    },
  });

  const authUser = { uid: 'userA', email: 'a@example.com' };
  const db = testEnv.authenticatedContext('userA').firestore();

  const chatId = 'userA_userB';
  const chatRef = db.collection('chats').doc(chatId);

  // Try creating the chat (like the flutter app does)
  const chatData = {
    participants: ['userA', 'userB'],
    lastMessage: 'hello',
    lastMessageAt: require('firebase/firestore').serverTimestamp(),
    updatedAt: require('firebase/firestore').serverTimestamp(),
    status: 'active',
    deletedFor: { userA: require('firebase/firestore').deleteField() },
    createdAt: require('firebase/firestore').serverTimestamp(),
    type: 'blocked',
    blockedDriverId: 'userA',
    vehicleOwnerId: 'userB'
  };

  try {
    await assertSucceeds(chatRef.set(chatData, { merge: true }));
    console.log("Chat set SUCCEEDED!");
  } catch (e) {
    console.error("Chat set FAILED:", e.message);
  }

  // Try creating message
  const msgRef = chatRef.collection('messages').doc();
  const msgData = {
    senderId: 'userA',
    receiverId: 'userB',
    messageText: 'hello',
    createdAt: require('firebase/firestore').serverTimestamp(),
    isRead: false
  };

  try {
    await assertSucceeds(msgRef.set(msgData));
    console.log("Msg set SUCCEEDED!");
  } catch (e) {
    console.error("Msg set FAILED:", e.message);
  }

  await testEnv.cleanup();
}

runTest();
