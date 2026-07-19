import { initializeApp } from "firebase/app";
import { getFunctions } from "firebase/functions";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
    projectId: "mymove-cb624",
    appId: "1:340854856075:web:3ef57aaa2a165054e2778e",
    databaseURL: "https://mymove-cb624-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "mymove-cb624.firebasestorage.app",
    apiKey: "AIzaSyDCRH7SlxvklhEqPWWBL2CPbZ9MgtOJXNQ",
    authDomain: "mymove-cb624.firebaseapp.com",
    messagingSenderId: "340854856075",
};

export const app = initializeApp(firebaseConfig);
export const functions = getFunctions(app);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
