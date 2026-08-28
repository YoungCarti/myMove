import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { Search, Calendar, MapPin, Clock, XCircle } from 'lucide-react';

interface Booking {
  id: string;
  userId: string;
  status: string; // 'pending', 'active', 'completed', 'canceled'
  locationName: string;
  locationAddress?: string;
  spotId: string;
  startDateTime: string;
  endDateTime: string;
  totalPrice?: number;
  totalPaid?: number;
  vehicleMake?: string;
  vehiclePlate?: string;
}

export const BookingManagement: React.FC = () => {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'pending' | 'completed' | 'canceled'>('all');
  const [, setTime] = useState(new Date());

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'bookings'), (snapshot) => {
      const bookingsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Booking[];

      // Sort by start date (newest first)
      bookingsData.sort((a, b) => new Date(b.startDateTime).getTime() - new Date(a.startDateTime).getTime());

      setBookings(bookingsData);
      setLoading(false);
      setError(null);
    }, (error) => {
      console.error("Error fetching bookings:", error);
      setError(error.message);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      setTime(new Date());
    }, 30000); // refresh every 30s
    return () => clearInterval(interval);
  }, []);

  const getEffectiveStatus = (booking: Booking): string => {
    if (booking.status === 'canceled') return 'canceled';
    if (booking.status === 'completed') return 'completed';
    if (booking.status === 'active') {
      const now = new Date();
      const end = new Date(booking.endDateTime);
      if (end < now) {
        return 'completed';
      }
      return 'active';
    }
    return booking.status;
  };

  const handleCancelBooking = async (bookingId: string) => {
    if (window.confirm('Are you sure you want to cancel this booking?')) {
      try {
        await updateDoc(doc(db, 'bookings', bookingId), {
          status: 'canceled'
        });
      } catch (error) {
        console.error("Error canceling booking:", error);
        alert("Failed to cancel booking.");
      }
    }
  };

  const filteredBookings = bookings.filter(booking => {
    const searchLower = searchTerm.toLowerCase();
    const effectiveStatus = getEffectiveStatus(booking);
    const matchesSearch = (
      booking.locationName?.toLowerCase().includes(searchLower) ||
      booking.spotId?.toLowerCase().includes(searchLower) ||
      effectiveStatus.toLowerCase().includes(searchLower) ||
      booking.userId?.toLowerCase().includes(searchLower) ||
      booking.vehiclePlate?.toLowerCase().includes(searchLower)
    );
    const matchesStatus = statusFilter === 'all' || effectiveStatus === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'active': return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
      case 'completed': return 'bg-green-500/20 text-green-400 border-green-500/30';
      case 'canceled': return 'bg-red-500/20 text-red-400 border-red-500/30';
      case 'pending': return 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30';
      default: return 'bg-gray-500/20 text-gray-400 border-gray-500/30';
    }
  };

  const formatDateTime = (dateString: string) => {
    if (!dateString) return 'N/A';
    try {
      const date = new Date(dateString);
      return new Intl.DateTimeFormat('en-MY', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      }).format(date);
    } catch (e) {
      return dateString;
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
            <h3 className="font-medium mb-1">Error Loading Bookings</h3>
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
            <h2 className="text-2xl font-bold text-white mb-1">Booking Management</h2>
            <p className="text-gray-400 text-sm">Monitor and manage all parking reservations.</p>
          </div>

          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search bookings..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full md:w-64 pl-9 pr-4 py-2 bg-[#2A2E39] border border-[#3A3F4C] rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-primary transition-colors"
            />
          </div>
        </div>

        {/* Status Filters */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none">
          {(['all', 'active', 'pending', 'completed', 'canceled'] as const).map((status) => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors ${statusFilter === status
                  ? 'bg-primary text-white'
                  : 'bg-[#2A2E39] text-gray-400 hover:text-white hover:bg-[#3A3F4C]'
                }`}
            >
              {status === 'all' ? 'All Bookings' : status.charAt(0).toUpperCase() + status.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-[#1A1D24] rounded-xl border border-[#2A2E39] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#2A2E39] bg-[#2A2E39]/30">
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Location & Spot</th>
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Date & Time</th>
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Vehicle</th>
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Amount</th>
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider">Status</th>
                <th className="p-4 text-xs font-semibold text-gray-400 uppercase tracking-wider text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A2E39]">
              {filteredBookings.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-gray-400">
                    <div className="flex flex-col items-center justify-center">
                      <Calendar className="w-12 h-12 mb-2 opacity-20" />
                      <p>No bookings found.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredBookings.map((booking) => {
                  const price = booking.totalPaid ?? (booking.totalPrice ? booking.totalPrice * 1.02 : 0);
                  const parsedSpotId = booking.spotId?.includes('_') ? booking.spotId.split('_').pop() : booking.spotId;
                  const effectiveStatus = getEffectiveStatus(booking);

                  return (
                    <tr key={booking.id} className="hover:bg-[#2A2E39]/20 transition-colors">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-lg bg-[#2A2E39] flex items-center justify-center shrink-0">
                            <MapPin className="w-5 h-5 text-gray-400" />
                          </div>
                          <div>
                            <p className="text-sm font-medium text-white">{booking.locationName || 'Unknown Location'}</p>
                            <p className="text-xs text-gray-400 mt-0.5">Spot: {parsedSpotId || 'N/A'}</p>
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col gap-1">
                          <div className="flex items-center gap-2 text-sm text-gray-300">
                            <Clock className="w-3.5 h-3.5 text-gray-500" />
                            {formatDateTime(booking.startDateTime)}
                          </div>
                          <div className="flex items-center gap-2 text-xs text-gray-500">
                            <span>to</span>
                            {formatDateTime(booking.endDateTime)}
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-col">
                          <span className="text-sm text-white font-medium">{booking.vehiclePlate || 'N/A'}</span>
                          <span className="text-xs text-gray-400">{booking.vehicleMake || 'N/A'}</span>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className="text-sm font-medium text-white">
                          RM {price.toFixed(2)}
                        </span>
                      </td>
                      <td className="p-4">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusColor(effectiveStatus)}`}>
                          {effectiveStatus.toUpperCase()}
                        </span>
                      </td>
                      <td className="p-4 text-right">
                        {(effectiveStatus === 'active' || effectiveStatus === 'pending') && (
                          <button
                            onClick={() => handleCancelBooking(booking.id)}
                            className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-red-500/10 text-red-400 hover:bg-red-500 hover:text-white transition-colors border border-red-500/20"
                            title="Cancel Booking"
                          >
                            <XCircle className="w-4 h-4" />
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
