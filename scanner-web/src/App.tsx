import { useEffect, useState, useRef } from 'react';
import { httpsCallable } from 'firebase/functions';
import { signInAnonymously, onAuthStateChanged, type User } from 'firebase/auth';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { Car, Bell, Smartphone, AlertCircle, CheckCircle2, Loader2, MessageSquare, Camera } from 'lucide-react';
import { functions, auth, storage } from './firebase';
import Chat from './Chat';

function App() {
  const [targetId, setTargetId] = useState<string | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [plate, setPlate] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [requestStatus, setRequestStatus] = useState<'idle' | 'sending' | 'success' | 'error'>('idle');
  const [showChat, setShowChat] = useState<boolean>(false);
  
  // Anti-spam features
  const [photoFile, setPhotoFile] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    // 1. Get ID from URL
    const params = new URLSearchParams(window.location.search);
    const id = params.get('id');
    
    if (!id) {
      setError('Invalid QR Code. No vehicle ID found.');
      setLoading(false);
      return;
    }
    setTargetId(id);

    // 2. Auth for storage & chat
    const unsubscribe = onAuthStateChanged(auth, (u) => {
      if (u) {
        setUser(u);
      } else {
        signInAnonymously(auth).catch(console.error);
      }
    });

    // 3. Fetch Vehicle Info
    const fetchVehicleInfo = async () => {
      try {
        const getVehiclePublicInfo = httpsCallable(functions, 'getVehiclePublicInfo');
        const result = await getVehiclePublicInfo({ targetUserId: id }) as any;
        if (result.data.success) {
          setPlate(result.data.plateNumber);
        } else {
          setError('Could not retrieve vehicle information.');
        }
      } catch (err: any) {
        console.error('Error fetching vehicle info:', err);
        setError(err.code === 'functions/not-found' ? 'Vehicle not found or inactive.' : 'Failed to connect to the server.');
      } finally {
        setLoading(false);
      }
    };

    fetchVehicleInfo();
    return () => unsubscribe();
  }, []);

  const handlePhotoCapture = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setPhotoFile(file);
      const reader = new FileReader();
      reader.onload = (e) => setPhotoPreview(e.target?.result as string);
      reader.readAsDataURL(file);
    }
  };

  const getLocation = (): Promise<{lat: number, lng: number} | null> => {
    return new Promise((resolve) => {
      if (!navigator.geolocation) {
        resolve(null);
        return;
      }
      navigator.geolocation.getCurrentPosition(
        (position) => resolve({ lat: position.coords.latitude, lng: position.coords.longitude }),
        (error) => {
          console.warn("Location permission denied or failed:", error);
          resolve(null); // Proceed even without location to prevent getting stuck
        },
        { timeout: 5000, enableHighAccuracy: true }
      );
    });
  };

  const handleRequestMove = async () => {
    if (!targetId || requestStatus === 'sending' || !user || !photoFile) return;

    setRequestStatus('sending');
    try {
      // 1. Get Location
      const location = await getLocation();

      // 2. Upload Photo
      const photoRef = ref(storage, `move_requests/${user.uid}_${Date.now()}.jpg`);
      const metadata = { contentType: photoFile.type || 'image/jpeg' };
      await uploadBytes(photoRef, photoFile, metadata);
      const photoUrl = await getDownloadURL(photoRef);

      // 3. Send Request
      const requestWebMoveCar = httpsCallable(functions, 'requestWebMoveCar');
      await requestWebMoveCar({ 
        targetUserId: targetId,
        photoUrl,
        location
      });
      setRequestStatus('success');
    } catch (err: any) {
      console.error('Error requesting move:', err);
      setRequestStatus('error');
      
      if (err.code === 'functions/resource-exhausted') {
        setError('Please wait a moment before sending another notification to prevent spam.');
      } else {
        setError('Failed to send notification. Please try again.');
      }
      setTimeout(() => setRequestStatus('idle'), 5000);
    }
  };

  if (loading) {
    return (
      <div className="app-container" style={{ justifyContent: 'center', alignItems: 'center' }}>
        <div className="loading-spinner"></div>
      </div>
    );
  }

  return (
    <div className="app-container">
      {targetId && (
        <a href={`mymove://user/${targetId}`} className="open-app-banner">
          <div className="banner-content">
            <div className="banner-icon">
              <Smartphone size={20} color="white" />
            </div>
            <div className="banner-text">
              <h4>Open in myMove App</h4>
              <p>For a faster and better experience</p>
            </div>
          </div>
          <span style={{ color: 'var(--primary-color)', fontWeight: 600 }}>Open</span>
        </a>
      )}

      <div className="glass-card" style={showChat ? { padding: 0, height: '600px', maxHeight: '80vh', display: 'flex' } : {}}>
        {showChat && targetId ? (
          <Chat targetUserId={targetId} plate={plate} onBack={() => setShowChat(false)} />
        ) : error && requestStatus !== 'error' ? (
          <>
            <div className="car-icon-wrapper" style={{ background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger-color)' }}>
              <AlertCircle size={40} />
            </div>
            <h2 className="title" style={{ color: 'var(--danger-color)' }}>Error</h2>
            <p className="subtitle">{error}</p>
          </>
        ) : (
          <>
            <div className="car-icon-wrapper">
              <Car size={40} />
            </div>
            
            <h2 className="title">Vehicle Blocked?</h2>
            <p className="subtitle">
              You are about to notify the owner of this vehicle to come and move it.
            </p>

            {plate && (
              <div className="plate-display">
                <div className="plate-label">License Plate</div>
                <div className="plate-number">{plate}</div>
              </div>
            )}

            {requestStatus === 'success' ? (
              <div style={{ textAlign: 'center', width: '100%' }}>
                <CheckCircle2 size={64} color="#10b981" style={{ margin: '0 auto 16px' }} />
                <h3 style={{ fontSize: '20px', fontWeight: 'bold', marginBottom: '8px' }}>Notification Sent!</h3>
                <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '24px' }}>
                  The owner has been notified and should be here shortly.
                </p>
                
                <button 
                  className="action-btn"
                  onClick={() => setShowChat(true)}
                  style={{ backgroundColor: 'rgba(255,255,255,0.1)', color: 'white', marginTop: '8px' }}
                >
                  <MessageSquare size={20} />
                  Start messaging the driver
                </button>
              </div>
            ) : (
              <div style={{ width: '100%' }}>
                {/* Photo Upload UI */}
                <div style={{ marginBottom: '20px', textAlign: 'center' }}>
                  {!photoFile ? (
                    <button 
                      onClick={() => fileInputRef.current?.click()}
                      className="action-btn"
                      style={{ backgroundColor: 'rgba(255,255,255,0.1)', color: 'white', padding: '24px 16px', flexDirection: 'column', gap: '12px' }}
                    >
                      <Camera size={32} />
                      <span>Take a photo of the blocked car</span>
                    </button>
                  ) : (
                    <div style={{ position: 'relative', display: 'inline-block', width: '100%' }}>
                      <img 
                        src={photoPreview!} 
                        alt="Blocked Car" 
                        style={{ width: '100%', height: '160px', objectFit: 'cover', borderRadius: '12px', border: '2px solid rgba(255,255,255,0.2)' }} 
                      />
                      <button 
                        onClick={() => setPhotoFile(null)}
                        style={{ position: 'absolute', top: 8, right: 8, background: 'rgba(0,0,0,0.6)', border: 'none', borderRadius: '50%', color: 'white', width: 32, height: 32, cursor: 'pointer' }}
                      >
                        ✕
                      </button>
                    </div>
                  )}
                  <input 
                    type="file" 
                    accept="image/*" 
                    capture="environment" 
                    ref={fileInputRef} 
                    onChange={handlePhotoCapture}
                    style={{ display: 'none' }}
                  />
                  <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '8px' }}>
                    * Required to prove the car is actually blocked. Your location will also be verified.
                  </p>
                </div>

                <button 
                  className="action-btn primary"
                  onClick={handleRequestMove}
                  disabled={requestStatus === 'sending' || !photoFile}
                  style={{ opacity: !photoFile ? 0.5 : 1 }}
                >
                  {requestStatus === 'sending' ? (
                    <>
                      <Loader2 className="loading-spinner" style={{ width: 18, height: 18, borderTopColor: 'transparent', borderRightColor: 'white' }} />
                      Processing & Sending...
                    </>
                  ) : (
                    <>
                      <Bell size={20} />
                      Request to Move Car
                    </>
                  )}
                </button>
                
                {requestStatus === 'error' && (
                  <p style={{ color: 'var(--danger-color)', fontSize: '12px', textAlign: 'center', marginTop: '12px' }}>
                    {error}
                  </p>
                )}
              </div>
            )}
          </>
        )}
      </div>
      
      <p style={{ textAlign: 'center', color: 'var(--text-secondary)', fontSize: '12px', marginTop: 'auto', paddingTop: '24px' }}>
        Powered by myMove
      </p>
    </div>
  );
}

export default App;
