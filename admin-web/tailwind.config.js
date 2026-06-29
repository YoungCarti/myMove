/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: '#0F1115',
        surface: '#1A1D24',
        surfaceHighlight: '#2A2E39',
        primary: '#3B82F6', // Blue
        primaryHover: '#2563EB',
        accent: '#10B981', // Emerald
        accentHover: '#059669',
        textMain: '#F3F4F6',
        textMuted: '#9CA3AF',
        danger: '#EF4444',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}

