import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { 
  LayoutDashboard, 
  Car, 
  CalendarDays, 
  Settings, 
  LogOut, 
  Menu,
  X
} from 'lucide-react';
import { SpotManagement } from './SpotManagement';

// Placeholder for other pages
const Overview = () => (
  <div className="p-6">
    <h2 className="text-2xl font-bold text-white mb-4">Dashboard Overview</h2>
    <p className="text-gray-400">Live statistics and metrics will appear here.</p>
  </div>
);

const Bookings = () => (
  <div className="p-6">
    <h2 className="text-2xl font-bold text-white mb-4">Manage Bookings</h2>
    <p className="text-gray-400">Active and upcoming bookings will be listed here.</p>
  </div>
);

export const Dashboard: React.FC = () => {
  const { user, signOut } = useAuth();
  const [activeTab, setActiveTab] = useState<'overview' | 'spots' | 'bookings'>('spots');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const navigation = [
    { id: 'overview', name: 'Overview', icon: LayoutDashboard },
    { id: 'spots', name: 'Spot Management', icon: Car },
    { id: 'bookings', name: 'Bookings', icon: CalendarDays },
  ] as const;

  const renderContent = () => {
    switch (activeTab) {
      case 'overview':
        return <Overview />;
      case 'spots':
        return <SpotManagement />;
      case 'bookings':
        return <Bookings />;
      default:
        return <Overview />;
    }
  };

  return (
    <div className="min-h-screen bg-[#0F1115] flex">
      {/* Mobile Sidebar Overlay */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/60 z-20 lg:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside 
        className={`fixed lg:static inset-y-0 left-0 w-64 bg-[#1A1D24] border-r border-[#2A2E39] z-30 transform transition-transform duration-300 ease-in-out flex flex-col ${
          isSidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        }`}
      >
        <div className="p-6 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-lg shadow-primary/20">
              <Car className="w-6 h-6 text-white" />
            </div>
            <span className="text-xl font-bold text-white tracking-tight">myMove</span>
          </div>
          <button 
            className="lg:hidden text-gray-400 hover:text-white"
            onClick={() => setIsSidebarOpen(false)}
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <nav className="flex-1 px-4 space-y-2 mt-4">
          {navigation.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            
            return (
              <button
                key={item.id}
                onClick={() => {
                  setActiveTab(item.id);
                  setIsSidebarOpen(false);
                }}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                  isActive 
                    ? 'bg-primary/10 text-primary font-medium border border-primary/20' 
                    : 'text-gray-400 hover:text-white hover:bg-[#2A2E39]/50'
                }`}
              >
                <Icon className={`w-5 h-5 ${isActive ? 'text-primary' : 'text-gray-400'}`} />
                {item.name}
              </button>
            );
          })}
        </nav>

        <div className="p-4 border-t border-[#2A2E39]">
          <div className="flex items-center gap-3 px-4 py-3 mb-2">
            <div className="w-8 h-8 rounded-full bg-[#2A2E39] flex items-center justify-center">
              <span className="text-sm font-medium text-white">
                {user?.email?.charAt(0).toUpperCase() || 'A'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-white truncate">{user?.email}</p>
              <p className="text-xs text-gray-500">Administrator</p>
            </div>
          </div>
          <button
            onClick={signOut}
            className="w-full flex items-center gap-3 px-4 py-3 text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-xl transition-all"
          >
            <LogOut className="w-5 h-5" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-w-0 h-screen overflow-hidden">
        {/* Header */}
        <header className="h-16 border-b border-[#2A2E39] bg-[#1A1D24]/80 backdrop-blur-md flex items-center px-4 lg:px-8 shrink-0 z-10 sticky top-0">
          <button
            className="lg:hidden p-2 text-gray-400 hover:text-white mr-4 bg-[#2A2E39] rounded-lg"
            onClick={() => setIsSidebarOpen(true)}
          >
            <Menu className="w-5 h-5" />
          </button>
          
          <h1 className="text-lg font-semibold text-white capitalize">
            {navigation.find(n => n.id === activeTab)?.name}
          </h1>
        </header>

        {/* Scrollable Content Area */}
        <div className="flex-1 overflow-auto">
          {renderContent()}
        </div>
      </main>
    </div>
  );
};
