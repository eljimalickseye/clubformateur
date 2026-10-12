/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,ts,scss}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#2D5BE3',
          hover: '#1A3BAA',
          light: '#EEF2FF',
        },
        primary: {
          DEFAULT: '#2D5BE3',
          50: '#F0F4FF',
          100: '#E1E9FF',
          200: '#C2D3FF',
          300: '#A3BDFF',
          400: '#6491FF',
          500: '#2D5BE3',
          600: '#1A3BAA',
          700: '#152F8B',
          800: '#0F2369',
          900: '#0A1747',
        },
        dark: {
          DEFAULT: '#F8FAFC',
          surface: '#FFFFFF',
          surface2: '#F1F5F9',
          surface3: '#E2E8F0',
          border: '#D9E2EC',
        },
        light: {
          DEFAULT: '#0F172A',
          muted: '#64748B',
          border: '#D9E2EC',
        }
      },
      fontFamily: {
        display: ['"Outfit"', '"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
        body: ['"Plus Jakarta Sans"', '"Inter"', 'system-ui', 'sans-serif'],
        sans: ['"Plus Jakarta Sans"', '"Inter"', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        DEFAULT: '12px',
        sm: '8px',
        lg: '16px',
        xl: '24px',
      },
      boxShadow: {
        'card': '0 1px 2px rgba(15,23,42,0.06), 0 6px 16px rgba(15,23,42,0.06)',
        'card-hover': '0 10px 26px rgba(37,99,235,0.14), 0 4px 10px rgba(15,23,42,0.06)',
        'glow': '0 0 20px rgba(37,99,235,0.3)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-up': 'slideUp 0.4s ease-out',
        'pulse-gold': 'pulseGold 2s infinite',
      },
      keyframes: {
        fadeIn: { '0%': { opacity: '0' }, '100%': { opacity: '1' } },
        slideUp: { '0%': { opacity: '0', transform: 'translateY(20px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        pulseGold: { '0%, 100%': { boxShadow: '0 0 0 0 rgba(37,99,235,0.35)' }, '50%': { boxShadow: '0 0 0 8px rgba(37,99,235,0)' } },
      }
    },
  },
  plugins: [],
};
