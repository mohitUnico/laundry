export default {
  darkMode: 'class',
  content: [
    './index.html',
    './src/**/*.{ts,tsx,js,jsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          600: '#2563EB',
          700: '#1D4ED8',
          800: '#1E40AF',
        },
        graybg: '#F8FAFC',
      },
      fontFamily: {
        inter: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        poppins: ['Poppins', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        soft: '0 2px 12px rgba(0,0,0,0.06)',
      },
      borderRadius: {
        xl: '0.75rem',
        '2xl': '1rem',
      },
      backgroundImage: {
        'card-gradient': 'linear-gradient(180deg, rgba(37,99,235,0.1) 0%, rgba(37,99,235,0.02) 100%)',
      },
    },
  },
  plugins: [],
};


