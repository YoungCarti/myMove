import React, { useState } from 'react';
import { Send, Megaphone, BellRing, AlertCircle, CheckCircle2, Users, Car } from 'lucide-react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '../firebase';

export const BroadcastNotifications: React.FC = () => {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [status, setStatus] = useState<{type: 'success' | 'error' | null, message: string}>({ type: null, message: '' });

  const handleSendBroadcast = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) {
      setStatus({ type: 'error', message: 'Title and body are required.' });
      return;
    }

    if (!window.confirm('Are you sure you want to send this push notification to ALL registered users?')) {
      return;
    }

    setIsSending(true);
    setStatus({ type: null, message: '' });

    try {
      const broadcastNotification = httpsCallable(functions, 'broadcastNotification');
      const result = await broadcastNotification({ title: title.trim(), body: body.trim() });
      const data = result.data as { success: boolean, sentCount: number };
      
      setStatus({ 
        type: 'success', 
        message: `Successfully broadcasted to ${data.sentCount} users!` 
      });
      setTitle('');
      setBody('');
    } catch (error: any) {
      console.error("Broadcast failed:", error);
      setStatus({ type: 'error', message: error.message || 'Failed to send broadcast.' });
    } finally {
      setIsSending(false);
    }
  };

  return (
    <div className="p-4 lg:p-8 space-y-6 max-w-4xl mx-auto">
      <div>
        <h2 className="text-2xl font-bold text-white mb-1">Broadcast Notifications</h2>
        <p className="text-gray-400">Send instant push notifications to all users on the mobile app.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="md:col-span-2 bg-[#1A1D24] border border-[#2A2E39] rounded-3xl p-6 shadow-xl relative overflow-hidden">
          {/* Decorative background element */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-3xl -mr-20 -mt-20 pointer-events-none"></div>
          
          <form onSubmit={handleSendBroadcast} className="relative z-10 space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1.5">Notification Title</label>
              <input 
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Holiday Discount!"
                maxLength={50}
                required
                className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1.5">Notification Message</label>
              <textarea 
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="e.g. Enjoy 20% off all parking this weekend."
                rows={4}
                maxLength={200}
                required
                className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors resize-none"
              />
              <p className="text-xs text-gray-500 mt-2 text-right">
                {body.length}/200 characters
              </p>
            </div>

            {status.type && (
              <div className={`p-4 rounded-xl flex items-start gap-3 border ${
                status.type === 'success' 
                  ? 'bg-green-500/10 border-green-500/20 text-green-400' 
                  : 'bg-red-500/10 border-red-500/20 text-red-400'
              }`}>
                {status.type === 'success' ? <CheckCircle2 className="w-5 h-5 mt-0.5 shrink-0" /> : <AlertCircle className="w-5 h-5 mt-0.5 shrink-0" />}
                <p className="text-sm font-medium">{status.message}</p>
              </div>
            )}

            <button 
              type="submit"
              disabled={isSending || !title.trim() || !body.trim()}
              className="w-full flex items-center justify-center gap-2 bg-primary hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed text-white py-3.5 px-4 rounded-xl font-bold shadow-lg shadow-primary/20 transition-all"
            >
              {isSending ? (
                <>
                  <div className="w-5 h-5 border-2 border-white/20 border-t-white rounded-full animate-spin" />
                  Sending Broadcast...
                </>
              ) : (
                <>
                  <Send className="w-5 h-5" />
                  Broadcast to All Users
                </>
              )}
            </button>
          </form>
        </div>

        {/* Live Preview & Tips Panel */}
        <div className="space-y-6">
          <div className="bg-gradient-to-br from-[#1A1D24] to-[#2A2E39] border border-[#3A3F4B] rounded-3xl p-6 shadow-xl">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-xl bg-purple-500/20 flex items-center justify-center border border-purple-500/30">
                <BellRing className="w-5 h-5 text-purple-400" />
              </div>
              <h3 className="text-white font-bold">Mobile Preview</h3>
            </div>
            
            {/* Fake phone notification block */}
            <div className="bg-[#0F1115]/80 backdrop-blur-md border border-white/10 rounded-2xl p-4 shadow-2xl">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className="w-5 h-5 rounded bg-primary flex items-center justify-center">
                    <Car className="w-3 h-3 text-white" />
                  </div>
                  <span className="text-[10px] uppercase font-bold text-gray-400 tracking-wider">myMove</span>
                </div>
                <span className="text-[10px] text-gray-500">now</span>
              </div>
              <h4 className="text-white text-sm font-bold truncate">
                {title || 'Notification Title'}
              </h4>
              <p className="text-gray-400 text-xs mt-1 line-clamp-2 leading-relaxed">
                {body || 'Your message preview will appear right here as you type.'}
              </p>
            </div>
          </div>

          <div className="bg-[#1A1D24] border border-[#2A2E39] rounded-3xl p-6">
            <div className="flex items-center gap-3 mb-3">
              <Megaphone className="w-5 h-5 text-yellow-400" />
              <h3 className="text-white font-bold">Best Practices</h3>
            </div>
            <ul className="text-sm text-gray-400 space-y-3">
              <li className="flex items-start gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-yellow-400 mt-1.5 shrink-0" />
                Keep titles short and punchy (under 30 characters).
              </li>
              <li className="flex items-start gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-yellow-400 mt-1.5 shrink-0" />
                Include a clear call to action if you want users to open the app.
              </li>
              <li className="flex items-start gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-yellow-400 mt-1.5 shrink-0" />
                Don't over-communicate. Save broadcasts for important announcements.
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};
