import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db } from '../firebase';
import { Search, Star, MessageSquare, MapPin, Calendar, Clock, XCircle } from 'lucide-react';

interface Feedback {
  id: string;
  userId: string;
  bookingId: string;
  locationName: string;
  rating: number;
  comments: string;
  createdAt: any;
}

export const FeedbackManagement: React.FC = () => {
  const [feedbackList, setFeedbackList] = useState<Feedback[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [ratingFilter, setRatingFilter] = useState<'all' | '1' | '2' | '3' | '4' | '5'>('all');

  useEffect(() => {
    const q = query(collection(db, 'feedback'), orderBy('createdAt', 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Feedback[];

      setFeedbackList(data);
      setLoading(false);
      setError(null);
    }, (error) => {
      console.error("Error fetching feedback:", error);
      setError(error.message);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filteredFeedback = feedbackList.filter(feedback => {
    const searchLower = searchTerm.toLowerCase();
    const matchesSearch = (
      feedback.locationName?.toLowerCase().includes(searchLower) ||
      feedback.comments?.toLowerCase().includes(searchLower) ||
      feedback.bookingId?.toLowerCase().includes(searchLower)
    );
    const matchesRating = ratingFilter === 'all' || feedback.rating.toString() === ratingFilter;

    return matchesSearch && matchesRating;
  });

  const renderStars = (rating: number) => {
    return (
      <div className="flex items-center gap-1">
        {[1, 2, 3, 4, 5].map((star) => (
          <Star 
            key={star} 
            className={`w-4 h-4 ${star <= rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-600'}`} 
          />
        ))}
      </div>
    );
  };

  const formatDateTime = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    try {
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return new Intl.DateTimeFormat('en-MY', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      }).format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  };

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6 flex items-center justify-center h-full">
        <div className="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl flex items-start gap-3 max-w-md">
          <XCircle className="w-5 h-5 shrink-0 mt-0.5" />
          <div>
            <h3 className="font-medium mb-1">Error Loading Feedback</h3>
            <p className="text-sm opacity-80">{error}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="flex flex-col gap-6 mb-8">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-2xl font-bold text-white mb-1">User Feedback</h2>
            <p className="text-gray-400 text-sm">Monitor what users are saying about your parking locations.</p>
          </div>

          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search feedback..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full md:w-64 pl-9 pr-4 py-2 bg-[#2A2E39] border border-[#3A3F4C] rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-primary transition-colors"
            />
          </div>
        </div>

        {/* Rating Filters */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none">
          {(['all', '5', '4', '3', '2', '1'] as const).map((rating) => (
            <button
              key={rating}
              onClick={() => setRatingFilter(rating)}
              className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors flex items-center gap-2 ${
                ratingFilter === rating
                  ? 'bg-primary text-white'
                  : 'bg-[#2A2E39] text-gray-400 hover:text-white hover:bg-[#3A3F4C]'
              }`}
            >
              {rating === 'all' ? 'All Ratings' : (
                <>
                  {rating} <Star className="w-4 h-4 fill-current" />
                </>
              )}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-[#1A1D24] rounded-xl border border-[#2A2E39] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#2A2E39] bg-[#2A2E39]/30">
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Location</th>
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Rating</th>
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Comments</th>
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Date & Time</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A2E39]">
              {filteredFeedback.length === 0 ? (
                <tr>
                  <td colSpan={4} className="p-8 text-center text-gray-400">
                    <div className="flex flex-col items-center justify-center">
                      <MessageSquare className="w-12 h-12 mb-2 opacity-20" />
                      <p>No feedback found.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredFeedback.map((item) => (
                  <tr key={item.id} className="hover:bg-[#2A2E39]/20 transition-colors">
                    <td className="p-4 align-top">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-[#2A2E39] flex items-center justify-center shrink-0">
                          <MapPin className="w-5 h-5 text-gray-400" />
                        </div>
                        <div>
                          <p className="text-sm font-medium text-white">{item.locationName || 'Unknown Location'}</p>
                          <p className="text-xs text-gray-400 mt-0.5" title={item.bookingId}>Booking: {item.bookingId}</p>
                        </div>
                      </div>
                    </td>
                    <td className="p-4 align-top">
                      {renderStars(item.rating)}
                    </td>
                    <td className="p-4 align-top">
                      <p className="text-sm text-gray-300 max-w-md break-words">
                        {item.comments || <span className="italic text-gray-500">No comments provided</span>}
                      </p>
                    </td>
                    <td className="p-4 align-top whitespace-nowrap">
                      <div className="flex items-center gap-2 text-sm text-gray-300">
                        <Clock className="w-3.5 h-3.5 text-gray-500" />
                        {formatDateTime(item.createdAt)}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
