class MapConfig {
  // Replace with your MapTiler API key from cloud.maptiler.com
  // or provide via --dart-define=MAPTILER_API_KEY=your_key
  static const String mapTilerApiKey = String.fromEnvironment(
    'MAPTILER_API_KEY',
    defaultValue: 'YOUR_MAPTILER_API_KEY',
  );

  static String get mapStyleUrl =>
      'https://api.maptiler.com/maps/streets-v4-dark/style.json?key=$mapTilerApiKey';
}
