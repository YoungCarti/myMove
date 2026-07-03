import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, doc, updateDoc, setDoc, deleteDoc, getDocs, query, where } from 'firebase/firestore';
import { db } from '../firebase';
import { Plus, Edit2, Trash2, Cpu, CheckCircle2, XCircle, Search, RefreshCw, X, Car } from 'lucide-react';

interface ParkingSpot {
  id: string;
  isAvailable: boolean;
  type: string;
  hardwareSensorId?: string;
  pricePerHour?: number;
  locationId?: string;
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
  const [locationId, setLocationId] = useState('');
  const [locations, setLocations] = useState<{id: string, name: string}[]>([]);

  useEffect(() => {
    const unsubscribeSpots = onSnapshot(collection(db, 'parkingSpots'), (snapshot) => {
      const spotsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as ParkingSpot[];
      
      // Sort alphabetically by ID
      spotsData.sort((a, b) => a.id.localeCompare(b.id));
      
      setSpots(spotsData);
      setLoading(false);
    });

    const unsubscribeLocations = onSnapshot(collection(db, 'parking_locations'), (snapshot) => {
      const locationsData = snapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name
      }));
      setLocations(locationsData);
    });

    return () => {
      unsubscribeSpots();
      unsubscribeLocations();
    };
  }, []);

  const handleOpenModal = (spot?: ParkingSpot) => {
    if (spot) {
      setEditingSpot(spot);
      setSpotId((spot as any).name || spot.id);
      setSensorId(spot.hardwareSensorId || '');
      setSpotType(spot.type || 'regular');
      setIsAvailable(spot.isAvailable ?? true);
      setLocationId(spot.locationId || '');
    } else {
      setEditingSpot(null);
      setSpotId('');
      setSensorId('');
      setSpotType('regular');
      setIsAvailable(true);
      setLocationId('');
    }
    setIsModalOpen(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!spotId.trim() || !locationId) return;

    try {
      const spotName = spotId.trim().toUpperCase();
      const actualId = `${locationId}_${spotName}`;
      const spotRef = doc(db, 'parkingSpots', actualId);
      const data = {
        name: spotName,
        isAvailable,
        type: spotType,
        hardwareSensorId: sensorId.trim() || null,
        locationId: locationId || null,
        updatedAt: new Date().toISOString()
      };

      if (editingSpot && editingSpot.id !== actualId) {
        // If ID changed, delete old doc and create new (simplified approach)
        await deleteDoc(doc(db, 'parkingSpots', editingSpot.id));
      }

      await setDoc(spotRef, data, { merge: true });
      
      // Update availableSpots for the location
      if (locationId) {
        // Get all spots for this location
        const spotsQuery = await getDocs(query(collection(db, 'parkingSpots'), where('locationId', '==', locationId)));
        let availableCount = 0;
        spotsQuery.forEach((doc) => {
          if (doc.data().isAvailable) availableCount++;
        });
        
        await updateDoc(doc(db, 'parking_locations', locationId), {
          availableSpots: availableCount
        });
      }

      setIsModalOpen(false);
    } catch (error) {
      console.error("Error saving spot:", error);
      alert("Failed to save spot details.");
    }
  };

  const handleDelete = async (id: string, locId?: string) => {
    if (window.confirm(`Are you sure you want to delete parking spot ${id}?`)) {
      try {
        await deleteDoc(doc(db, 'parkingSpots', id));
        
        if (locId) {
          const spotsQuery = await getDocs(query(collection(db, 'parkingSpots'), where('locationId', '==', locId)));
          let availableCount = 0;
          spotsQuery.forEach((doc) => {
            if (doc.data().isAvailable) availableCount++;
          });
          
          await updateDoc(doc(db, 'parking_locations', locId), {
            availableSpots: availableCount
          });
        }
      } catch (error) {
        console.error("Error deleting spot:", error);
      }
    }
  };

  const filteredSpots = spots.filter(s => {
    const locName = locations.find(l => l.id === s.locationId)?.name || '';
    const term = searchTerm.toLowerCase();
    
    // Get actual display name to search against
    let displayName = (s as any).name || '';
    if (!displayName || displayName.length > 10 || displayName.includes('_')) {
      const parts = s.id.split('_');
      if (parts.length >= 2) {
        displayName = parts[0].length > 10 ? parts[1] : parts[0];
      } else {
        displayName = s.id;
      }
    }

    return s.id.toLowerCase().includes(term) || 
           s.hardwareSensorId?.toLowerCase().includes(term) ||
           displayName.toLowerCase().includes(term) ||
           locName.toLowerCase().includes(term);
  });

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
            onClick={async () => {
              if (!window.confirm("Run spot maintenance? This will generate missing spots and fix legacy data.")) return;
              
              try {
                // First, fix existing spots that might be missing the name field or using old formats
                const spotsQuery = await getDocs(collection(db, 'parkingSpots'));
                for (const docSnap of spotsQuery.docs) {
                  const data = docSnap.data();
                  if (!data.name) {
                    // Try to guess the name from the ID (e.g., A1_locationId or locationId_A1)
                    const parts = docSnap.id.split('_');
                    let guessedName = docSnap.id;
                    if (parts.length === 2) {
                      // If one part is long (location ID), the other is the spot name
                      guessedName = parts[0].length > 10 ? parts[1] : parts[0];
                    }
                    await updateDoc(docSnap.ref, { name: guessedName });
                  }
                }

                // Generate missing spots for locations that have none
                for (const loc of locations) {
                  const locSpotsQuery = await getDocs(query(collection(db, 'parkingSpots'), where('locationId', '==', loc.id)));
                  if (locSpotsQuery.empty) {
                    // Generate A1-A7
                    for (let i = 1; i <= 7; i++) {
                      const spotName = `A${i}`;
                      const spotRef = doc(db, 'parkingSpots', `${loc.id}_${spotName}`);
                      await setDoc(spotRef, {
                        name: spotName,
                        isAvailable: true,
                        type: 'regular',
                        hardwareSensorId: null,
                        locationId: loc.id,
                        updatedAt: new Date().toISOString()
                      });
                    }
                    // Generate B1-B7
                    for (let i = 1; i <= 7; i++) {
                      const spotName = `B${i}`;
                      const spotRef = doc(db, 'parkingSpots', `${loc.id}_${spotName}`);
                      await setDoc(spotRef, {
                        name: spotName,
                        isAvailable: true,
                        type: 'regular',
                        hardwareSensorId: null,
                        locationId: loc.id,
                        updatedAt: new Date().toISOString()
                      });
                    }
                    
                    await updateDoc(doc(db, 'parking_locations', loc.id), {
                      availableSpots: 14
                    });
                  }
                }
                alert("Spot maintenance completed successfully!");
              } catch (e) {
                console.error("Error during spot maintenance:", e);
                alert("Error during spot maintenance.");
              }
            }}
            className="flex items-center gap-2 bg-[#2A2E39] hover:bg-[#3A3F4B] text-white py-2.5 px-4 rounded-xl font-medium transition-colors whitespace-nowrap"
          >
            <RefreshCw className="w-5 h-5" />
            Migrate Legacy Spots
          </button>
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
          {filteredSpots.map((spot) => {
            // Safe fallback for name display
            let displayName = (spot as any).name || '';
            if (!displayName || displayName.length > 10 || displayName.includes('_')) {
              // Extract from ID if name is missing or looks like a composite ID
              const parts = spot.id.split('_');
              if (parts.length >= 2) {
                displayName = parts[0].length > 10 ? parts[1] : parts[0];
              } else {
                displayName = spot.id;
              }
            }

            return (
              <div key={spot.id} className="bg-[#1A1D24] border border-[#2A2E39] rounded-2xl p-5 hover:border-[#3A3F4B] transition-colors group">
                <div className="flex justify-between items-start mb-4">
                  <div className="flex items-center gap-3">
                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center text-xl font-bold ${
                      spot.isAvailable 
                        ? 'bg-green-500/10 text-green-400 border border-green-500/20' 
                        : 'bg-red-500/10 text-red-400 border border-red-500/20'
                    }`}>
                      {displayName}
                    </div>
                    <div>
                      <h3 className="text-white font-medium capitalize">{spot.type} Spot</h3>
                      <p className="text-xs text-gray-400 mt-0.5">
                        {locations.find(l => l.id === spot.locationId)?.name || 'No Location'}
                      </p>
                      <div className="flex items-center gap-1.5 mt-1">
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
                    <button onClick={() => handleDelete(spot.id, spot.locationId)} className="p-1.5 text-gray-400 hover:text-red-400 bg-[#2A2E39] hover:bg-red-500/10 hover:border-red-500/20 rounded-lg transition-colors">
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
            );
          })}
          
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

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1.5">Location</label>
                <select 
                  value={locationId}
                  onChange={(e) => setLocationId(e.target.value)}
                  className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white focus:outline-none focus:border-primary transition-colors appearance-none"
                  required
                >
                  <option value="" disabled>Select a location</option>
                  {locations.map(loc => (
                    <option key={loc.id} value={loc.id}>{loc.name}</option>
                  ))}
                </select>
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
