import { useState, useEffect, useRef } from 'react';
import { auth, db } from './firebase';
import { signInAnonymously } from 'firebase/auth';
import { 
  collection, 
  doc, 
  setDoc, 
  onSnapshot, 
  query, 
  orderBy, 
  addDoc, 
  serverTimestamp, 
  getDoc,
  updateDoc,
  increment
} from 'firebase/firestore';
import { Send, ArrowLeft } from 'lucide-react';

interface Message {
  id: string;
  senderId: string;
  messageText: string;
  createdAt: any;
}

interface ChatProps {
  targetUserId: string;
  plate: string;
  onBack: () => void;
}

export default function Chat({ targetUserId, plate, onBack }: ChatProps) {
  const [uid, setUid] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const chatId = uid ? [uid, targetUserId].sort().join('_') : null;

  useEffect(() => {
    // 1. Sign in anonymously to get a UID
    signInAnonymously(auth).then((userCredential) => {
      setUid(userCredential.user.uid);
    }).catch((error) => {
      console.error("Anonymous auth failed:", error);
    });
  }, []);

  useEffect(() => {
    if (!uid || !chatId) return;

    // 2. Ensure Chat Document exists
    const initializeChat = async () => {
      const chatRef = doc(db, 'chats', chatId);
      const chatDoc = await getDoc(chatRef);
      if (!chatDoc.exists()) {
        await setDoc(chatRef, {
          participants: [uid, targetUserId].sort(),
          type: 'normal',
          status: 'active',
          updatedAt: serverTimestamp(),
          createdAt: serverTimestamp(),
          deletedFor: {}
        });
      }
    };

    initializeChat();

    // 3. Listen for messages
    const q = query(
      collection(db, 'chats', chatId, 'messages'),
      orderBy('createdAt', 'asc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const msgs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Message[];
      setMessages(msgs);
      setLoading(false);
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    });

    return () => unsubscribe();
  }, [uid, chatId, targetUserId]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !uid || !chatId) return;

    const textToSend = newMessage.trim();
    setNewMessage('');

    try {
      // Add message
      await addDoc(collection(db, 'chats', chatId, 'messages'), {
        senderId: uid,
        receiverId: targetUserId,
        messageText: textToSend,
        createdAt: serverTimestamp(),
        isRead: false,
      });

      // Update chat document
      await updateDoc(doc(db, 'chats', chatId), {
        lastMessage: textToSend,
        lastMessageAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        unreadCount: increment(1)
      });
    } catch (err) {
      console.error("Error sending message:", err);
    }
  };

  if (loading) {
    return (
      <div style={{ flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
        <div className="loading-spinner"></div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', width: '100%' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', padding: '16px', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', color: 'white', cursor: 'pointer', padding: 0, marginRight: '16px' }}>
          <ArrowLeft size={24} />
        </button>
        <div>
          <h3 style={{ margin: 0, fontSize: '16px' }}>Vehicle Owner</h3>
          <p style={{ margin: 0, fontSize: '12px', color: 'var(--text-secondary)' }}>{plate}</p>
        </div>
      </div>

      {/* Messages Area */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {messages.length === 0 ? (
          <div style={{ textAlign: 'center', color: 'var(--text-secondary)', marginTop: '20px', fontSize: '14px' }}>
            Send a message to the driver...
          </div>
        ) : (
          messages.map(msg => {
            const isMe = msg.senderId === uid;
            return (
              <div 
                key={msg.id} 
                style={{
                  alignSelf: isMe ? 'flex-end' : 'flex-start',
                  backgroundColor: isMe ? 'var(--primary-color)' : 'rgba(255,255,255,0.1)',
                  padding: '10px 14px',
                  borderRadius: '16px',
                  borderBottomRightRadius: isMe ? '4px' : '16px',
                  borderBottomLeftRadius: !isMe ? '4px' : '16px',
                  maxWidth: '80%',
                  wordBreak: 'break-word',
                  fontSize: '14px'
                }}
              >
                {msg.messageText}
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div style={{ padding: '16px', borderTop: '1px solid rgba(255,255,255,0.1)' }}>
        <form onSubmit={handleSend} style={{ display: 'flex', gap: '8px' }}>
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder="Type a message..."
            style={{
              flex: 1,
              padding: '12px 16px',
              borderRadius: '24px',
              border: 'none',
              backgroundColor: 'rgba(255,255,255,0.1)',
              color: 'white',
              outline: 'none',
              fontSize: '14px'
            }}
          />
          <button 
            type="submit" 
            disabled={!newMessage.trim()}
            style={{
              backgroundColor: newMessage.trim() ? 'var(--primary-color)' : 'rgba(255,255,255,0.1)',
              border: 'none',
              borderRadius: '50%',
              width: '42px',
              height: '42px',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              color: 'white',
              cursor: newMessage.trim() ? 'pointer' : 'default',
              transition: 'background-color 0.2s'
            }}
          >
            <Send size={18} style={{ marginLeft: '2px' }} />
          </button>
        </form>
      </div>
    </div>
  );
}
