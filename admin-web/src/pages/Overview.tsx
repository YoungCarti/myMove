import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, where, getDocs } from 'firebase/firestore';
import { db } from '../firebase';
import { DollarSign, Users, Car, TrendingUp, Activity, CreditCard, Calendar } from 'lucide-react';

interface Stats {
  totalRevenue: number;
  activeBookings: number;
  totalUsers: number;
  totalSpots: number;
}

export const Overview: React.FC = () => {
  const [stats, setStats] = useState<Stats>({
    totalRevenue: 0,
    activeBookings: 0,
    totalUsers: 0,
    totalSpots: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Listen to bookings
    const unsubscribeBookings = onSnapshot(collection(db, 'bookings'), (snapshot) => {
      let revenue = 0;
      let active = 0;
      const uniqueUsers = new Set<string>();

      snapshot.docs.forEach(doc => {
        const data = doc.data();
        if (data.status !== 'canceled') {
          revenue += (data.totalPrice || data.totalPaid || 0);
        }
        if (data.status === 'active' || data.status === 'pending') {
          active++;
        }
        if (data.userId) {
          uniqueUsers.add(data.userId);
        }
      });

      setStats(prev => ({
        ...prev,
        totalRevenue: revenue,
        activeBookings: active,
        totalUsers: uniqueUsers.size // Fallback metric for users
      }));
    });

    // Listen to parking spots
    const unsubscribeSpots = onSnapshot(collection(db, 'parkingSpots'), (snapshot) => {
      setStats(prev => ({
        ...prev,
        totalSpots: snapshot.docs.length
      }));
      setLoading(false);
    });

    // We can also fetch the actual users collection for a more accurate count if admin has access
    const fetchUsers = async () => {
      try {
        const usersSnap = await getDocs(collection(db, 'users'));
        setStats(prev => ({ ...prev, totalUsers: usersSnap.size }));
      } catch (e) {
        // Admin might not have rules to read entire users list yet, fallback to booking users
        console.log("Could not fetch users directly, using booking data for user count.");
      }
    };
    fetchUsers();

    return () => {
      unsubscribeBookings();
      unsubscribeSpots();
    };
  }, []);

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
            {[40, 70, 45, 90, 65, 85, 100].map((height, i) => (
              <div key={i} className="w-full max-w-[40px] flex flex-col items-center gap-2 group">
                <div className="w-full bg-gradient-to-t from-primary/20 to-primary rounded-t-xl transition-all duration-500 group-hover:opacity-80" style={{ height: `${height}%` }}></div>
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
          <div className="flex-1 flex flex-col justify-center items-center text-center opacity-50 space-y-3">
            <div className="w-16 h-16 bg-[#2A2E39] rounded-full flex items-center justify-center mb-2">
              <CreditCard className="w-8 h-8 text-gray-400" />
            </div>
            <p className="text-sm text-gray-400">Transaction history will populate as users complete bookings.</p>
          </div>
        </div>
      </div>
    </div>
  );
};
