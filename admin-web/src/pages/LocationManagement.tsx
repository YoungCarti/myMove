import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, doc, updateDoc, deleteDoc, addDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { Plus, Edit2, Trash2, MapPin, Search, RefreshCw, X, Navigation } from 'lucide-react';

export interface ParkingLocation {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  address?: string;
  imageUrl?: string;
  pricePerHour?: number;
  description?: string;
  operatingHours?: string;
  openTime?: string;
  closeTime?: string;
  parkingType?: string;
  availableSpots?: number;
}

export const LocationManagement: React.FC = () => {
  const [locations, setLocations] = useState<ParkingLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingLocation, setEditingLocation] = useState<ParkingLocation | null>(null);
  const [notification, setNotification] = useState<{message: string, type: 'success' | 'error'} | null>(null);

  const showNotification = (message: string, type: 'success' | 'error' = 'success') => {
    setNotification({ message, type });
    setTimeout(() => {
      setNotification(null);
    }, 3000);
  };

  // Form State
  const [name, setName] = useState('');
  const [coordinates, setCoordinates] = useState('');
  const [address, setAddress] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [pricePerHour, setPricePerHour] = useState('');
  const [description, setDescription] = useState('');
  const [openTime, setOpenTime] = useState('09:00');
  const [closeTime, setCloseTime] = useState('22:00');
  const [parkingType, setParkingType] = useState('Indoor Parking');
  const [availableSpots, setAvailableSpots] = useState('50');

  const formatTime = (time: string) => {
    if (!time) return '';
    const [h, m] = time.split(':');
    const hours = parseInt(h, 10);
    const suffix = hours >= 12 ? 'PM' : 'AM';
    const hour12 = hours % 12 || 12;
    return `${hour12}:${m} ${suffix}`;
  };

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'parking_locations'), (snapshot) => {
      const locationsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as ParkingLocation[];
      
      // Sort alphabetically by name
      locationsData.sort((a, b) => a.name.localeCompare(b.name));
      
      setLocations(locationsData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleOpenModal = (location?: ParkingLocation) => {
    if (location) {
      setEditingLocation(location);
      setName(location.name);
      setCoordinates(`${location.latitude}, ${location.longitude}`);
      setAddress(location.address || '');
      setImageUrl(location.imageUrl || '');
      setPricePerHour(location.pricePerHour !== undefined ? location.pricePerHour.toString() : '');
      setDescription(location.description || '');
      setOpenTime(location.openTime || '09:00');
      setCloseTime(location.closeTime || '22:00');
      setParkingType(location.parkingType || 'Indoor Parking');
      setAvailableSpots(location.availableSpots !== undefined ? location.availableSpots.toString() : '50');
    } else {
      setEditingLocation(null);
      setName('');
      setCoordinates('');
      setAddress('');
      setImageUrl('');
      setPricePerHour('');
      setDescription('');
      setOpenTime('09:00');
      setCloseTime('22:00');
      setParkingType('Indoor Parking');
      setAvailableSpots('50');
    }
    setIsModalOpen(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !coordinates.trim()) return;

    try {
      // Parse coordinates
      const parts = coordinates.split(',').map(p => p.trim());
      const lat = parseFloat(parts[0]);
      const lng = parseFloat(parts[1]);

      if (isNaN(lat) || isNaN(lng)) {
        showNotification("Invalid coordinates format. Please use 'latitude, longitude'.", 'error');
        return;
      }

      const data = {
        name: name.trim(),
        latitude: lat,
        longitude: lng,
        address: address.trim() || null,
        imageUrl: imageUrl.trim() || '',
        pricePerHour: parseFloat(pricePerHour) || 0,
        description: description.trim() || '',
        operatingHours: `${formatTime(openTime)} - ${formatTime(closeTime)}`,
        openTime: openTime,
        closeTime: closeTime,
        parkingType: parkingType,
        availableSpots: parseInt(availableSpots) || 0,
        updatedAt: new Date().toISOString()
      };

      if (editingLocation) {
        const locRef = doc(db, 'parking_locations', editingLocation.id);
        await updateDoc(locRef, data);
        showNotification('Location updated successfully!');
      } else {
        await addDoc(collection(db, 'parking_locations'), data);
        showNotification('Location created successfully!');
      }

      setIsModalOpen(false);
    } catch (error) {
      console.error("Error saving location:", error);
      showNotification("Failed to save location details.", 'error');
    }
  };

  const handleDelete = async (id: string, name: string) => {
    if (window.confirm(`Are you sure you want to delete parking location "${name}"?`)) {
      try {
        await deleteDoc(doc(db, 'parking_locations', id));
        showNotification('Location deleted successfully!');
      } catch (error) {
        console.error("Error deleting location:", error);
        showNotification('Failed to delete location.', 'error');
      }
    }
  };

  const filteredLocations = locations.filter(l => 
    l.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    `${l.latitude}, ${l.longitude}`.includes(searchTerm) ||
    (l.address && l.address.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  return (
    <div className="p-4 lg:p-8">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white mb-1">Parking Locations</h2>
          <p className="text-gray-400">Manage geographical locations for parking spots.</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-5 h-5 text-gray-500 absolute left-3 top-1/2 transform -translate-y-1/2" />
            <input 
              type="text" 
              placeholder="Search locations..."
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
            Add Location
          </button>
        </div>
      </div>

      {/* Locations Grid */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <RefreshCw className="w-8 h-8 text-primary animate-spin" />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filteredLocations.map((location) => (
            <div key={location.id} className="bg-[#1A1D24] border border-[#2A2E39] rounded-2xl p-5 hover:border-[#3A3F4B] transition-colors group">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-xl bg-blue-500/10 text-blue-400 border border-blue-500/20 flex items-center justify-center">
                    <MapPin className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="text-white font-medium text-lg">{location.name}</h3>
                  </div>
                </div>
                
                <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => handleOpenModal(location)} className="p-1.5 text-gray-400 hover:text-white bg-[#2A2E39] hover:bg-[#3A3F4B] rounded-lg transition-colors">
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button onClick={() => handleDelete(location.id, location.name)} className="p-1.5 text-gray-400 hover:text-red-400 bg-[#2A2E39] hover:bg-red-500/10 hover:border-red-500/20 rounded-lg transition-colors">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <div className="space-y-2">
                <div className="bg-[#0F1115] rounded-xl p-3 border border-[#2A2E39] flex items-center gap-3">
                  <div className="bg-[#1A1D24] p-2 rounded-lg">
                    <Navigation className="w-4 h-4 text-gray-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs text-gray-500 mb-0.5">Coordinates & Rate</p>
                    <p className="text-sm font-mono text-gray-300 truncate">
                      {location.latitude}, {location.longitude}
                    </p>
                    <p className="text-xs text-primary font-medium mt-0.5">
                      RM {location.pricePerHour || 0} / hour
                    </p>
                    <p className="text-xs text-green-500 font-medium mt-0.5">
                      {location.availableSpots || 0} spots available
                    </p>
                  </div>
                </div>
                {location.address && (
                  <div className="bg-[#0F1115] rounded-xl p-3 border border-[#2A2E39] flex items-center gap-3">
                    <div className="bg-[#1A1D24] p-2 rounded-lg">
                      <MapPin className="w-4 h-4 text-gray-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs text-gray-500 mb-0.5">Address</p>
                      <p className="text-sm text-gray-300 truncate">
                        {location.address}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}
          
          {filteredLocations.length === 0 && (
            <div className="col-span-full py-12 text-center border-2 border-dashed border-[#2A2E39] rounded-2xl">
              <MapPin className="w-12 h-12 text-gray-600 mx-auto mb-3" />
              <h3 className="text-lg font-medium text-white mb-1">No locations found</h3>
              <p className="text-gray-400">Add a new parking location to get started.</p>
            </div>
          )}
        </div>
      )}

      {/* Edit/Add Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm overflow-y-auto">
          <div className="bg-[#1A1D24] rounded-3xl w-full max-w-2xl border border-[#2A2E39] shadow-2xl my-8 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between p-6 border-b border-[#2A2E39]">
              <h3 className="text-xl font-bold text-white">
                {editingLocation ? 'Edit Location' : 'Add New Location'}
              </h3>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="text-gray-400 hover:text-white transition-colors p-1"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <form onSubmit={handleSave} className="p-6 space-y-5">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Location Name</label>
                  <input 
                    type="text" 
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors"
                    placeholder="e.g. Main Campus Parking"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Parking Type</label>
                  <select 
                    value={parkingType}
                    onChange={(e) => setParkingType(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white focus:outline-none focus:border-primary transition-colors appearance-none"
                  >
                    <option value="Indoor Parking">Indoor Parking</option>
                    <option value="Outdoor Parking">Outdoor Parking</option>
                    <option value="Multi-Level Parking">Multi-Level Parking</option>
                    <option value="Basement Parking">Basement Parking</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Coordinates (Latitude, Longitude)</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <Navigation className="w-5 h-5 text-gray-500" />
                    </div>
                    <input 
                      type="text" 
                      required
                      value={coordinates}
                      onChange={(e) => setCoordinates(e.target.value)}
                      className="w-full pl-10 pr-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors font-mono text-sm"
                      placeholder="2.99965, 101.78547"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Rate per Hour (RM)</label>
                  <input 
                    type="number" 
                    step="0.01"
                    min="0"
                    required
                    value={pricePerHour}
                    onChange={(e) => setPricePerHour(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors"
                    placeholder="e.g. 5.00"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Available Spots</label>
                  <input 
                    type="number" 
                    min="0"
                    required
                    value={availableSpots}
                    onChange={(e) => setAvailableSpots(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors"
                    placeholder="e.g. 50"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Opening Time</label>
                  <input 
                    type="time" 
                    required
                    value={openTime}
                    onChange={(e) => setOpenTime(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors style-time-input"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Closing Time</label>
                  <input 
                    type="time" 
                    required
                    value={closeTime}
                    onChange={(e) => setCloseTime(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors style-time-input"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1.5">Image URL</label>
                <input 
                  type="url" 
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors"
                  placeholder="https://example.com/parking.jpg"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Address (Optional)</label>
                  <textarea 
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors resize-none h-24"
                    placeholder="Full physical address..."
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-1.5">Description (Optional)</label>
                  <textarea 
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="w-full px-4 py-3 bg-[#0F1115] border border-[#2A2E39] rounded-xl text-white placeholder-gray-600 focus:outline-none focus:border-primary transition-colors resize-none h-24"
                    placeholder="Provide details about the parking location..."
                  />
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
                  Save Location
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Toast Notification */}
      {notification && (
        <div className={`fixed bottom-4 right-4 z-[60] flex items-center gap-2 px-4 py-3 rounded-xl shadow-lg border animate-in slide-in-from-bottom-4 fade-in duration-300 ${
          notification.type === 'success' 
            ? 'bg-green-500/10 border-green-500/20 text-green-400' 
            : 'bg-red-500/10 border-red-500/20 text-red-400'
        }`}>
          {notification.type === 'success' ? (
            <div className="w-5 h-5 rounded-full bg-green-500/20 flex items-center justify-center">
              <div className="w-2 h-2 rounded-full bg-green-500"></div>
            </div>
          ) : (
            <X className="w-5 h-5" />
          )}
          <span className="font-medium">{notification.message}</span>
        </div>
      )}
    </div>
  );
};
