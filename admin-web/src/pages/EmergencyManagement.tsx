import React, { useState, useEffect, useRef } from 'react';
import { collection, query, where, onSnapshot, doc, setDoc, addDoc, serverTimestamp, orderBy, updateDoc } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '../firebase';
import { useAuth } from '../contexts/AuthContext';
import { AlertTriangle, Phone, PhoneOff, Mic, MicOff, Send, X, MessageSquare, Clock, MapPin, ShieldAlert, CheckCircle2 } from 'lucide-react';

// Make AgoraRTC available from the global window object (loaded via CDN)
declare global {
  interface Window {
    AgoraRTC: any;
  }
}

// Agora App ID loaded from environment variable
const AGORA_APP_ID = import.meta.env.VITE_AGORA_APP_ID || '';


interface Emergency {
  id: string;
  userId: string;
  userName: string;
  timestamp: any;
  status: string;
  location?: { latitude: number; longitude: number };
}

interface Message {
  id: string;
  senderId: string;
  receiverId: string;
  messageText: string;
  createdAt: any;
  isRead: boolean;
}

export const EmergencyManagement: React.FC = () => {
  const { user } = useAuth();
  const [emergencies, setEmergencies] = useState<Emergency[]>([]);
  const [selectedEmergency, setSelectedEmergency] = useState<Emergency | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Call states
  const [isInCall, setIsInCall] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [callDuration, setCallDuration] = useState(0);

  const clientRef = useRef<any>(null);
  const localAudioTrackRef = useRef<any>(null);
  const callTimerRef = useRef<any>(null);

  useEffect(() => {
    // Listen for active emergencies
    const q = query(collection(db, 'emergencies'), where('status', '==', 'active'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const ems: Emergency[] = [];
      snapshot.forEach((doc) => {
        ems.push({ id: doc.id, ...doc.data() } as Emergency);
      });
      // Sort by timestamp descending
      ems.sort((a, b) => {
        const timeA = a.timestamp?.toMillis?.() || 0;
        const timeB = b.timestamp?.toMillis?.() || 0;
        return timeB - timeA;
      });
      setEmergencies(ems);
      setLoading(false);

      // Update selected emergency if it was resolved
      if (selectedEmergency) {
        const stillActive = ems.find(e => e.id === selectedEmergency.id);
        if (!stillActive) {
          setSelectedEmergency(null);
        }
      }
    }, (error) => {
      console.error("Error fetching emergencies:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [selectedEmergency]);

  useEffect(() => {
    let unsubscribeMessages: () => void;

    if (selectedEmergency) {
      const participants = [selectedEmergency.userId, 'security_management'].sort();
      const chatId = participants.join('_');

      const messagesRef = collection(db, 'chats', chatId, 'messages');
      const q = query(messagesRef, orderBy('createdAt', 'asc'));

      unsubscribeMessages = onSnapshot(q, (snapshot) => {
        const msgs: Message[] = [];
        snapshot.forEach((doc) => {
          msgs.push({ id: doc.id, ...doc.data() } as Message);
        });
        setMessages(msgs);
        scrollToBottom();
      }, (error) => {
        console.error("Error fetching messages:", error);
      });
    }

    return () => {
      if (unsubscribeMessages) unsubscribeMessages();
    };
  }, [selectedEmergency, user]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedEmergency || !user) return;

    try {
      const participants = [selectedEmergency.userId, 'security_management'].sort();
      const chatId = participants.join('_');

      const messagesRef = collection(db, 'chats', chatId, 'messages');
      await addDoc(messagesRef, {
        senderId: 'security_management',
        receiverId: selectedEmergency.userId,
        messageText: newMessage.trim(),
        createdAt: serverTimestamp(),
        isRead: false,
      });

      // Update chat meta
      const chatDocRef = doc(db, 'chats', chatId);
      await setDoc(chatDocRef, {
        participants,
        lastMessage: newMessage.trim(),
        lastMessageTime: serverTimestamp(),
        unreadCount_user: 1, // trigger notification for mobile user
      }, { merge: true });

      setNewMessage('');
    } catch (err) {
      console.error("Error sending message:", err);
    }
  };

  const markResolved = async (id: string) => {
    try {
      if (isInCall) {
        endCall();
      }
      const emergencyRef = doc(db, 'emergencies', id);
      await updateDoc(emergencyRef, {
        status: 'resolved',
        resolvedAt: serverTimestamp(),
        resolvedBy: user?.email || 'security_management'
      });
    } catch (err) {
      console.error("Error resolving emergency", err);
    }
  };

  const initiateCall = async () => {
    if (!selectedEmergency) return;

    try {
      const channelName = selectedEmergency.id;

      // 1. Trigger Cloud Function to generate dynamic token and ring mobile user
      const initiateCallFunction = httpsCallable(functions, 'initiateCall');
      const callResult = await initiateCallFunction({
        targetUserId: selectedEmergency.userId,
        channelName: channelName,
        callerName: 'Security Management'
      });

      const callData = callResult.data as { success: boolean; token?: string };
      const token = callData?.token || null;

      // 2. Initialize Agora Client
      const client = window.AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });
      clientRef.current = client;

      // Setup event listeners for remote users
      client.on("user-published", async (user: any, mediaType: string) => {
        await client.subscribe(user, mediaType);
        console.log("Subscribed to user", user.uid);
        if (mediaType === "audio") {
          const remoteAudioTrack = user.audioTrack;
          remoteAudioTrack.play();
        }
      });

      client.on("user-unpublished", (user: any) => {
        console.log("User unpublished", user.uid);
      });

      // 3. Join the channel using dynamically generated token from backend
      await client.join(AGORA_APP_ID, channelName, token, null);

      // 4. Create and publish local audio track
      const localAudioTrack = await window.AgoraRTC.createMicrophoneAudioTrack();
      localAudioTrackRef.current = localAudioTrack;
      await client.publish([localAudioTrack]);

      // 5. Update UI State
      setIsInCall(true);
      setIsMuted(false);
      setCallDuration(0);

      callTimerRef.current = setInterval(() => {
        setCallDuration(prev => prev + 1);
      }, 1000);

    } catch (error) {
      console.error("Error initiating call:", error);
      alert("Failed to initiate call. Ensure microphone permissions are granted.");
      endCall();
    }
  };

  const endCall = async () => {
    try {
      if (localAudioTrackRef.current) {
        localAudioTrackRef.current.close();
        localAudioTrackRef.current = null;
      }
      if (clientRef.current) {
        await clientRef.current.leave();
        clientRef.current = null;
      }
    } catch (err) {
      console.error("Error ending call:", err);
    } finally {
      setIsInCall(false);
      setIsMuted(false);
      setCallDuration(0);
      if (callTimerRef.current) {
        clearInterval(callTimerRef.current);
        callTimerRef.current = null;
      }
    }
  };

  const toggleMute = () => {
    if (localAudioTrackRef.current) {
      const currentlyMuted = isMuted;
      localAudioTrackRef.current.setMuted(!currentlyMuted);
      setIsMuted(!currentlyMuted);
    }
  };

  const formatDuration = (seconds: number) => {
    const m = Math.floor(seconds / 60).toString().padStart(2, '0');
    const s = (seconds % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  // Cleanup on unmount or selected emergency change
  useEffect(() => {
    return () => {
      endCall();
    };
  }, [selectedEmergency?.id]);

  const formatTime = (timestamp: any) => {
    if (!timestamp) return '';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="p-6 h-full flex flex-col">
      <div className="mb-6 flex justify-between items-center shrink-0">
        <div>
          <h2 className="text-2xl font-bold text-white mb-2 flex items-center gap-2">
            <ShieldAlert className="w-8 h-8 text-red-500" />
            Emergency Management
          </h2>
          <p className="text-gray-400">Monitor and respond to active SOS alerts from users.</p>
        </div>
        {emergencies.length > 0 && (
          <div className="bg-red-500/20 border border-red-500/50 text-red-500 px-4 py-2 rounded-xl flex items-center gap-2 animate-pulse">
            <AlertTriangle className="w-5 h-5" />
            <span className="font-bold">{emergencies.length} Active SOS</span>
          </div>
        )}
      </div>

      <div className="flex-1 grid grid-cols-1 lg:grid-cols-3 gap-6 min-h-0">
        {/* Active Emergencies List */}
        <div className="bg-[#1A1D24] border border-[#2A2E39] rounded-2xl flex flex-col overflow-hidden">
          <div className="p-4 border-b border-[#2A2E39] shrink-0">
            <h3 className="text-lg font-semibold text-white">Active Alerts</h3>
          </div>
          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {loading ? (
              <div className="flex justify-center p-8">
                <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
              </div>
            ) : emergencies.length === 0 ? (
              <div className="text-center p-8 text-gray-500">
                <CheckCircle2 className="w-12 h-12 mx-auto mb-3 opacity-50" />
                <p>No active emergencies</p>
                <p className="text-sm mt-1">All clear</p>
              </div>
            ) : (
              emergencies.map(emergency => (
                <div
                  key={emergency.id}
                  onClick={() => setSelectedEmergency(emergency)}
                  className={`p-4 rounded-xl cursor-pointer transition-all border ${selectedEmergency?.id === emergency.id
                      ? 'bg-red-500/10 border-red-500/50'
                      : 'bg-[#2A2E39]/50 border-transparent hover:bg-[#2A2E39]'
                    }`}
                >
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-semibold text-white">{emergency.userName}</h4>
                    <span className="text-xs text-gray-400 flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {formatTime(emergency.timestamp)}
                    </span>
                  </div>
                  <div className="flex items-center gap-1 text-sm text-red-400 mb-2 font-medium">
                    <AlertTriangle className="w-4 h-4" />
                    SOS Activated
                  </div>
                  {emergency.location && (
                    <div className="flex items-center gap-1 text-xs text-gray-400">
                      <MapPin className="w-3 h-3" />
                      {emergency.location.latitude.toFixed(4)}, {emergency.location.longitude.toFixed(4)}
                    </div>
                  )}
                </div>
              ))
            )}
          </div>
        </div>

        {/* Chat / Action Interface */}
        <div className="lg:col-span-2 bg-[#1A1D24] border border-[#2A2E39] rounded-2xl flex flex-col overflow-hidden">
          {selectedEmergency ? (
            <>
              {/* Chat Header */}
              <div className="p-4 border-b border-[#2A2E39] shrink-0 flex justify-between items-center bg-[#2A2E39]/30">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-red-500/20 flex items-center justify-center border border-red-500/50">
                    <ShieldAlert className="w-5 h-5 text-red-500" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-white text-lg">{selectedEmergency.userName}</h3>
                    <p className="text-sm text-red-400 flex items-center gap-1">
                      <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></div>
                      Emergency Active
                    </p>
                  </div>
                </div>
                <div className="flex gap-2 items-center">
                  {isInCall ? (
                    <div className="flex items-center gap-2 bg-red-500/10 px-3 py-1.5 rounded-xl border border-red-500/30 mr-2">
                      <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></div>
                      <span className="text-red-500 font-medium text-sm w-12 text-center">
                        {formatDuration(callDuration)}
                      </span>
                      <button
                        onClick={toggleMute}
                        className={`p-1.5 rounded-lg transition-colors ${isMuted ? 'bg-red-500/20 text-red-500' : 'bg-gray-700 text-white hover:bg-gray-600'}`}
                        title={isMuted ? "Unmute" : "Mute"}
                      >
                        {isMuted ? <MicOff className="w-4 h-4" /> : <Mic className="w-4 h-4" />}
                      </button>
                      <button
                        onClick={endCall}
                        className="flex items-center gap-1 px-3 py-1.5 bg-red-500 text-white rounded-lg transition-colors hover:bg-red-600 font-medium text-sm ml-1"
                      >
                        <PhoneOff className="w-4 h-4" />
                        End Call
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={initiateCall}
                      className="flex items-center gap-2 px-4 py-2 bg-green-500/10 text-green-500 hover:bg-green-500/20 rounded-xl transition-colors font-medium border border-green-500/30"
                    >
                      <Phone className="w-4 h-4" />
                      Call User
                    </button>
                  )}
                  <button
                    onClick={() => markResolved(selectedEmergency.id)}
                    className="flex items-center gap-2 px-4 py-2 bg-gray-700/50 text-white hover:bg-gray-700 rounded-xl transition-colors font-medium"
                  >
                    <CheckCircle2 className="w-4 h-4" />
                    Resolve
                  </button>
                  <button
                    onClick={() => setSelectedEmergency(null)}
                    className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-xl transition-colors"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {/* Messages Area */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {messages.length === 0 ? (
                  <div className="h-full flex flex-col items-center justify-center text-gray-500">
                    <MessageSquare className="w-12 h-12 mb-3 opacity-20" />
                    <p>No messages yet.</p>
                    <p className="text-sm mt-1">Send a message to establish contact.</p>
                  </div>
                ) : (
                  messages.map(msg => {
                    const isMe = msg.senderId === 'security_management';
                    return (
                      <div key={msg.id} className={`flex flex-col ${isMe ? 'items-end' : 'items-start'}`}>
                        <div className={`max-w-[70%] px-4 py-2 rounded-2xl ${isMe
                            ? 'bg-primary text-white rounded-tr-sm'
                            : 'bg-[#2A2E39] text-white rounded-tl-sm'
                          }`}>
                          <p className="text-[15px]">{msg.messageText}</p>
                        </div>
                        <span className="text-[10px] text-gray-500 mt-1 px-1">
                          {formatTime(msg.createdAt)}
                        </span>
                      </div>
                    );
                  })
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Input Area */}
              <div className="p-4 border-t border-[#2A2E39] bg-[#1A1D24]">
                <form onSubmit={handleSendMessage} className="flex gap-2">
                  <input
                    type="text"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    placeholder="Type a message..."
                    className="flex-1 bg-[#0F1115] border border-[#2A2E39] rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  />
                  <button
                    type="submit"
                    disabled={!newMessage.trim()}
                    className="w-12 h-12 bg-primary text-white rounded-xl flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed hover:bg-primary/90 transition-colors"
                  >
                    <Send className="w-5 h-5 ml-1" />
                  </button>
                </form>
              </div>
            </>
          ) : (
            <div className="h-full flex flex-col items-center justify-center text-gray-500 p-8">
              <ShieldAlert className="w-16 h-16 mb-4 opacity-20" />
              <h3 className="text-xl font-semibold mb-2">No Emergency Selected</h3>
              <p className="text-center max-w-md">
                Select an active SOS alert from the list on the left to view details, communicate with the user, and resolve the situation.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
