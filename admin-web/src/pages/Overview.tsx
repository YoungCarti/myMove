import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, getDocs } from 'firebase/firestore';
import { db } from '../firebase';
import { DollarSign, Users, Car, TrendingUp, Activity, CreditCard, Calendar } from 'lucide-react';

export const Overview: React.FC = () => {
  const [bookings, setBookings] = useState<any[]>([]);
  const [totalSpots, setTotalSpots] = useState(0);
  const [directUserCount, setDirectUserCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [, setTime] = useState(new Date());

  useEffect(() => {
    // Listen to bookings
    const unsubscribeBookings = onSnapshot(collection(db, 'bookings'), (snapshot) => {
      const bookingsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setBookings(bookingsData);
    });

    // Listen to parking spots
    const unsubscribeSpots = onSnapshot(collection(db, 'parkingSpots'), (snapshot) => {
      setTotalSpots(snapshot.docs.length);
      setLoading(false);
    });

    // We can also fetch the actual users collection for a more accurate count if admin has access
    const fetchUsers = async () => {
      try {
        const usersSnap = await getDocs(collection(db, 'users'));
        setDirectUserCount(usersSnap.size);
      } catch (e) {
        // Admin might not have rules to read entire users list yet, fallback to booking users
        console.log("Could not fetch users directly, using booking data for user count.");
      }
    };
    fetchUsers();

    const interval = setInterval(() => {
      setTime(new Date());
    }, 30000); // refresh every 30s

    return () => {
      unsubscribeBookings();
      unsubscribeSpots();
      clearInterval(interval);
    };
  }, []);

  // Compute stats on the fly
  let totalRevenue = 0;
  let activeBookings = 0;
  const uniqueUsers = new Set<string>();

  bookings.forEach(booking => {
    if (booking.status !== 'canceled') {
      totalRevenue += (booking.totalPrice || booking.totalPaid || 0);
    }
    
    // Effective status check
    const now = new Date();
    const endDateTime = booking.endDateTime ? new Date(booking.endDateTime) : null;
    let isEffectiveActive = false;
    
    if (booking.status === 'pending') {
      isEffectiveActive = true;
    } else if (booking.status === 'active') {
      if (!endDateTime || endDateTime >= now) {
        isEffectiveActive = true;
      }
    }
    
    if (isEffectiveActive) {
      activeBookings++;
    }
    
    if (booking.userId) {
      uniqueUsers.add(booking.userId);
    }
  });

  const displayUsersCount = directUserCount !== null ? directUserCount : uniqueUsers.size;

  const stats = {
    totalRevenue,
    activeBookings,
    totalUsers: displayUsersCount,
    totalSpots
  };

  const getBookingDate = (b: any): Date => {
    if (b.createdAt) {
      if (typeof b.createdAt.toDate === 'function') {
        return b.createdAt.toDate();
      }
      if (b.createdAt.seconds) {
        return new Date(b.createdAt.seconds * 1000);
      }
      return new Date(b.createdAt);
    }
    return new Date(b.startDateTime || b.createdAt || Date.now());
  };

  const recentTransactions = bookings
    .filter(b => b.paymentStatus === 'paid')
    .sort((a, b) => getBookingDate(b).getTime() - getBookingDate(a).getTime())
    .slice(0, 5);

  // Calculate revenue for each day of the current week (Monday - Sunday)
  const getWeeklyRevenueData = () => {
    const now = new Date();
    const currentDay = now.getDay(); // 0 is Sunday, 1 is Monday, etc.
    
    // Calculate the date of Monday of this week
    const monday = new Date(now);
    // If today is Sunday (0), Monday was 6 days ago. Otherwise, it was (currentDay - 1) days ago.
    const daysSinceMonday = currentDay === 0 ? 6 : currentDay - 1;
    monday.setDate(now.getDate() - daysSinceMonday);
    monday.setHours(0, 0, 0, 0);

    // Initialize daily revenue array [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    const dailyRevenues = [0, 0, 0, 0, 0, 0, 0];

    bookings.forEach(booking => {
      if (booking.status !== 'canceled') {
        const price = booking.totalPaid ?? (booking.totalPrice ? booking.totalPrice * 1.02 : 0);
        const bookingDate = getBookingDate(booking);
        
        // Check if booking is in the current week
        const diffTime = bookingDate.getTime() - monday.getTime();
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays >= 0 && diffDays < 7) {
          dailyRevenues[diffDays] += price;
        }
      }
    });

    // To scale the heights in the chart (max height is 100%)
    const maxRevenue = Math.max(...dailyRevenues);
    const chartHeights = dailyRevenues.map(rev => {
      if (maxRevenue === 0 || rev === 0) return 0;
      return Math.max(5, Math.round((rev / maxRevenue) * 100));
    });

    return {
      dailyRevenues,
      chartHeights
    };
  };

  const { dailyRevenues, chartHeights } = getWeeklyRevenueData();

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center p-8">
        <Activity className="w-8 h-8 text-primary animate-spin" />
      </div>
    );
  }

  return (
    <div className="p-4 lg:p-8 space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-white mb-1">Dashboard Overview</h2>
        <p className="text-gray-400">Live statistics and metrics for your parking facilities.</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Revenue Card */}
        <div className="bg-gradient-to-br from-[#1A1D24] to-[#2A2E39] p-6 rounded-3xl border border-[#3A3F4B] shadow-xl relative overflow-hidden group">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <DollarSign className="w-24 h-24 text-green-500 transform rotate-12" />
          </div>
          <div className="relative z-10">
            <div className="w-12 h-12 bg-green-500/20 rounded-2xl flex items-center justify-center mb-4 border border-green-500/30">
              <DollarSign className="w-6 h-6 text-green-400" />
            </div>
            <p className="text-gray-400 text-sm font-medium mb-1">Total Revenue</p>
            <h3 className="text-3xl font-bold text-white tracking-tight">
              RM {stats.totalRevenue.toFixed(2)}
            </h3>
            <div className="flex items-center gap-1 mt-3 text-xs font-medium text-green-400">
              <TrendingUp className="w-3 h-3" />
              <span>Up to date</span>
            </div>
          </div>
        </div>

        {/* Active Bookings Card */}
        <div className="bg-gradient-to-br from-[#1A1D24] to-[#2A2E39] p-6 rounded-3xl border border-[#3A3F4B] shadow-xl relative overflow-hidden group">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <Calendar className="w-24 h-24 text-primary transform -rotate-12" />
          </div>
          <div className="relative z-10">
            <div className="w-12 h-12 bg-primary/20 rounded-2xl flex items-center justify-center mb-4 border border-primary/30">
              <Activity className="w-6 h-6 text-primary" />
            </div>
            <p className="text-gray-400 text-sm font-medium mb-1">Active Bookings</p>
            <h3 className="text-3xl font-bold text-white tracking-tight">
              {stats.activeBookings}
            </h3>
            <div className="flex items-center gap-1 mt-3 text-xs font-medium text-primary">
              <span>Currently active or pending</span>
            </div>
          </div>
        </div>

        {/* Total Users Card */}
        <div className="bg-gradient-to-br from-[#1A1D24] to-[#2A2E39] p-6 rounded-3xl border border-[#3A3F4B] shadow-xl relative overflow-hidden group">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <Users className="w-24 h-24 text-purple-500 transform rotate-6" />
          </div>
          <div className="relative z-10">
            <div className="w-12 h-12 bg-purple-500/20 rounded-2xl flex items-center justify-center mb-4 border border-purple-500/30">
              <Users className="w-6 h-6 text-purple-400" />
            </div>
            <p className="text-gray-400 text-sm font-medium mb-1">Total Users</p>
            <h3 className="text-3xl font-bold text-white tracking-tight">
              {stats.totalUsers}
            </h3>
            <div className="flex items-center gap-1 mt-3 text-xs font-medium text-purple-400">
              <span>Registered accounts</span>
            </div>
          </div>
        </div>

        {/* Total Spots Card */}
        <div className="bg-gradient-to-br from-[#1A1D24] to-[#2A2E39] p-6 rounded-3xl border border-[#3A3F4B] shadow-xl relative overflow-hidden group">
          <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <Car className="w-24 h-24 text-orange-500 transform -rotate-6" />
          </div>
          <div className="relative z-10">
            <div className="w-12 h-12 bg-orange-500/20 rounded-2xl flex items-center justify-center mb-4 border border-orange-500/30">
              <Car className="w-6 h-6 text-orange-400" />
            </div>
            <p className="text-gray-400 text-sm font-medium mb-1">Total Managed Spots</p>
            <h3 className="text-3xl font-bold text-white tracking-tight">
              {stats.totalSpots}
            </h3>
            <div className="flex items-center gap-1 mt-3 text-xs font-medium text-orange-400">
              <span>Across all locations</span>
            </div>
          </div>
        </div>
      </div>

      {/* Visual Chart Placeholder Area */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-8">
        <div className="lg:col-span-2 bg-[#1A1D24] border border-[#2A2E39] rounded-3xl p-6 shadow-lg">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-lg font-bold text-white">Revenue Overview</h3>
            <div className="bg-[#2A2E39] text-xs font-medium text-gray-300 px-3 py-1 rounded-full">This Week</div>
          </div>
          <div className="h-64 flex items-end justify-between gap-2 border-b border-[#2A2E39] pb-2 px-2">
            {/* CSS Bar Chart Simulation */}
            {chartHeights.map((height, i) => (
              <div key={i} className="w-full max-w-[40px] h-full flex flex-col justify-end items-center gap-2 group relative">
                {/* Tooltip */}
                <div className={`absolute -top-10 scale-0 ${dailyRevenues[i] > 0 ? 'group-hover:scale-100' : ''} transition-all bg-[#0F1115] text-white text-xs font-semibold px-2 py-1.5 rounded-lg border border-[#2A2E39] shadow-xl whitespace-nowrap z-20 pointer-events-none`}>
                  RM {dailyRevenues[i].toFixed(2)}
                </div>
                {height > 0 && (
                  <div 
                    className="w-full bg-gradient-to-t from-primary/20 to-primary rounded-t-xl transition-all duration-500 group-hover:opacity-80" 
                    style={{ height: `${height}%` }}
                  ></div>
                )}
              </div>
            ))}
          </div>
          <div className="flex justify-between mt-3 px-2 text-xs text-gray-500 font-medium">
            <span>Mon</span>
            <span>Tue</span>
            <span>Wed</span>
            <span>Thu</span>
            <span>Fri</span>
            <span>Sat</span>
            <span>Sun</span>
          </div>
        </div>

        <div className="bg-[#1A1D24] border border-[#2A2E39] rounded-3xl p-6 shadow-lg flex flex-col">
          <h3 className="text-lg font-bold text-white mb-6">Recent Transactions</h3>
          {recentTransactions.length === 0 ? (
            <div className="flex-1 flex flex-col justify-center items-center text-center opacity-50 space-y-3 py-8">
              <div className="w-16 h-16 bg-[#2A2E39] rounded-full flex items-center justify-center mb-2">
                <CreditCard className="w-8 h-8 text-gray-400" />
              </div>
              <p className="text-sm text-gray-400">Transaction history will populate as users complete bookings.</p>
            </div>
          ) : (
            <div className="flex-1 flex flex-col gap-4 overflow-y-auto max-h-72 pr-1 scrollbar-thin">
              {recentTransactions.map((booking) => {
                const price = booking.totalPaid ?? (booking.totalPrice ? booking.totalPrice * 1.02 : 0);
                const parsedSpotId = booking.spotId?.includes('_') ? booking.spotId.split('_').pop() : booking.spotId;
                const date = getBookingDate(booking);
                const formattedDate = new Intl.DateTimeFormat('en-MY', {
                  month: 'short',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                }).format(date);

                return (
                  <div key={booking.id} className="flex items-center justify-between p-4 bg-[#2A2E39]/30 rounded-2xl border border-[#2A2E39] hover:border-[#3A3F4B] transition-all">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-green-500/10 flex items-center justify-center border border-green-500/20 shrink-0">
                        <DollarSign className="w-5 h-5 text-green-400" />
                      </div>
                      <div className="text-left">
                        <p className="text-sm font-semibold text-white">{booking.locationName || 'Unknown Location'}</p>
                        <p className="text-xs text-gray-400">Spot: {parsedSpotId || 'N/A'} • {formattedDate}</p>
                      </div>
                    </div>
                    <div className="text-right shrink-0 ml-4">
                      <p className="text-sm font-bold text-white">RM {price.toFixed(2)}</p>
                      <span className="text-[10px] font-semibold text-green-400 bg-green-500/10 px-2 py-0.5 rounded-full border border-green-500/20 uppercase tracking-wider">
                        Paid
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
