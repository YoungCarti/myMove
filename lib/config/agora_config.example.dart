class AgoraConfig {
  // Replace these with your actual Agora credentials from console.agora.io
  // For production, RTC tokens are generated dynamically via Firebase Cloud Functions (initiateCall).
  static const String appId = 'YOUR_AGORA_APP_ID';
  
  // Optional temporary token for local testing without Cloud Functions
  static const String tempToken = 'YOUR_AGORA_TEMP_TOKEN';
}
