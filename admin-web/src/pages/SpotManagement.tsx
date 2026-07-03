import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, doc, updateDoc, setDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { Plus, Edit2, Trash2, Cpu, CheckCircle2, XCircle, Search, RefreshCw, X } from 'lucide-react';

interface ParkingSpot {
  id: string;
  isAvailable: boolean;
  type: string;
  hardwareSensorId?: string;
  pricePerHour?: number;
}

export const SpotManagement: React.FC = () => {
  const [spots, setSpots] = useState<ParkingSpot[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingSpot, setEditingSpot] = useState<ParkingSpot | null>(null);

  // Form State
  const [spotId, setSpotId] = useState('');
  const [sensorId, setSensorId] = useState('');
  const [spotType, setSpotType] = useState('regular');
  const [isAvailable, setIsAvailable] = useState(true);

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'parkingSpots'), (snapshot) => {
      const spotsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as ParkingSpot[];
      
      // Sort alphabetically by ID
      spotsData.sort((a, b) => a.id.localeCompare(b.id));
      
      setSpots(spotsData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleOpenModal = (spot?: ParkingSpot) => {
    if (spot) {
      setEditingSpot(spot);
      setSpotId(spot.id);
      setSensorId(spot.hardwareSensorId || '');
      setSpotType(spot.type || 'regular');
      setIsAvailable(spot.isAvailable ?? true);
    } else {
      setEditingSpot(null);
      setSpotId('');
      setSensorId('');
      setSpotType('regular');
      setIsAvailable(true);
    }
    setIsModalOpen(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!spotId.trim()) return;

    try {
      const spotRef = doc(db, 'parkingSpots', spotId.toUpperCase());
      const data = {
        isAvailable,
        type: spotType,
        hardwareSensorId: sensorId.trim() || null,
        updatedAt: new Date().toISOString()
      };

      if (editingSpot && editingSpot.id !== spotId.toUpperCase()) {
        // If ID changed, delete old doc and create new (simplified approach)
        await deleteDoc(doc(db, 'parkingSpots', editingSpot.id));
      }

      await setDoc(spotRef, data, { merge: true });
      setIsModalOpen(false);
    } catch (error) {
      console.error("Error saving spot:", error);
      alert("Failed to save spot details.");
    }
  };

  const handleDelete = async (id: string) => {
    if (window.confirm(`Are you sure you want to delete parking spot ${id}?`)) {
      try {
        await deleteDoc(doc(db, 'parkingSpots', id));
      } catch (error) {
        console.error("Error deleting spot:", error);
      }
    }
  };

  const filteredSpots = spots.filter(s => 
    s.id.toLowerCase().includes(searchTerm.toLowerCase()) || 
    s.hardwareSensorId?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="p-4 lg:p-8">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white mb-1">Spot Management</h2>
          <p className="text-gray-400">Map hardware sensors to physical parking slots.</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-5 h-5 text-gray-500 absolute left-3 top-1/2 transform -translate-y-1/2" />
            <input 
              type="text" 
              placeholder="Search spots or sensors..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10 pr-4 py-2.5 bg-[#1A1D24] border border-[#2A2E39] rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-primary transition-colors w-full md:w-64"
            />
          </div>
          <button 
            onClick={() => handleOpenModal()}
            className="flex items-center gap-2 bg-primary hover:bg-primary/90 text-white py-2.5 px-4 rounded-xl font-medium transition-colors whitespace-nowrap"
          >
            <Plus className="w-5 h-5" />
            Add Spot
          </button>
        </div>
      </div>

      {/* Spots Grid */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <RefreshCw className="w-8 h-8 text-primary animate-spin" />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-4">
          {filteredSpots.map((spot) => (
            <div key={spot.id} className="bg-[#1A1D24] border border-[#2A2E39] rounded-2xl p-5 hover:border-[#3A3F4B] transition-colors group">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-3">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center text-xl font-bold ${
                    spot.isAvailable 
                      ? 'bg-green-500/10 text-green-400 border border-green-500/20' 
                      : 'bg-red-500/10 text-red-400 border border-red-500/20'
                  }`}>
                    {spot.id}
                  </div>
                  <div>
                    <h3 className="text-white font-medium capitalize">{spot.type} Spot</h3>
                    <div className="flex items-center gap-1.5 mt-0.5">
                      {spot.isAvailable ? (
                        <><CheckCircle2 className="w-4 h-4 text-green-400" /><span className="text-sm text-green-400">Available</span></>
                      ) : (
                        <><XCircle className="w-4 h-4 text-red-400" /><span className="text-sm text-red-400">Occupied</span></>
                      )}
                    </div>
                  </div>
                </div>
                
                <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => handleOpenModal(spot)} className="p-1.5 text-gray-400 hover:text-white bg-[#2A2E39] hover:bg-[#3A3F4B] rounded-lg transition-colors">
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button onClick={() => handleDelete(spot.id)} className="p-1.5 text-gray-400 hover:text-red-400 bg-[#2A2E39] hover:bg-red-500/10 hover:border-red-500/20 rounded-lg transition-colors">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <div className="bg-[#0F1115] rounded-xl p-3 border border-[#2A2E39] flex items-center gap-3">
                <div className="bg-[#1A1D24] p-2 rounded-lg">
                  <Cpu className="w-5 h-5 text-gray-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-gray-500 mb-0.5">Linked Sensor ID</p>
                  <p className="text-sm font-mono text-gray-300 truncate">
                    {spot.hardwareSensorId || <span className="text-yellow-500 italic">Unassigned</span>}
                  </p>
                </div>
              </div>
            </div>
          ))}
          
          {filteredSpots.length === 0 && (
            <div className="col-span-full py-12 text-center border-2 border-dashed border-[#2A2E39] rounded-2xl">
              <Car className="w-12 h-12 text-gray-600 mx-auto mb-3" />
              <h3 className="text-lg font-medium text-white mb-1">No parking spots found</h3>
              <p className="text-gray-400">Add a new spot to get started or adjust your search.</p>
            </div>
          )}
        </div>
      )}

      {/* Edit/Add Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
          <div className="bg-[#1A1D24] rounded-3xl w-full max-w-md border border-[#2A2E39] shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between p-6 border-b border-[#2A2E39]">
              <h3 className="text-xl font-bold text-white">
                {editingSpot ? 'Edit Parking Spot' : 'Add New Spot'}
              </h3>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-white transition-colors p-1"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <form onSubmit={handleSave} className="p-6 space-y-5">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1.5">Spot ID (e.g. A1)</label>
                <input 
                  type="text" 
                  required
                  value={spotId}
                  onChange={(e) => setSpotId(e.target.value.toUpperCase())}
                  className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors font-mono"
                  placeholder="A1"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1.5">Hardware Sensor ID</label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Cpu className="w-5 h-5 text-gray-500" />
                  </div>
                  <input 
                    type="text" 
                    value={sensorId}
                    onChange={(e) => setSensorId(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors font-mono"
                    placeholder="esp32_node_01"
                  />
                </div>
                <p className="text-xs text-gray-500 mt-1.5">Leave blank if no sensor is installed yet.</p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Spot Type</label>
                  <select 
                    value={spotType}
                    onChange={(e) => setSpotType(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white focus:outline-none focus:border-primary transition-colors appearance-none"
                  >
                    <option value="regular">Regular</option>
                    <option value="ev">EV Charging</option>
                    <option value="handicap">Handicap</option>
                    <option value="vip">VIP</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Initial Status</label>
                  <select 
                    value={isAvailable ? 'true' : 'false'}
                    onChange={(e) => setIsAvailable(e.target.value === 'true')}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white focus:outline-none focus:border-primary transition-colors appearance-none"
                  >
                    <option value="true">Available</option>
                    <option value="false">Occupied</option>
                  </select>
                </div>
              </div>

              <div className="pt-4 mt-6 border-t border-[#2A2E39] flex gap-3">
                <button 
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 px-4 py-3 bg-[#2A2E39] hover:bg-[#3A3F4B] text-white rounded-xl font-medium transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="flex-1 px-4 py-3 bg-primary hover:bg-primary/90 text-white rounded-xl font-medium shadow-lg shadow-primary/20 transition-colors"
                >
                  Save Spot
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
