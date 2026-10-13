/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,ts,scss}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#13C7A3',
          hover: '#0EA88A',
          light: '#E9F7F1',
          dark: '#062C32',
        },
        primary: {
          DEFAULT: '#13C7A3',
          50: '#F0FDF9',
          100: '#E9F7F1',
          200: '#C6F6E5',
          300: '#86EFAC',
          400: '#35D3A3',
          500: '#13C7A3',
          600: '#12A57A',
          700: '#0D6B4D',
          800: '#0A4D38',
          900: '#062C32',
        },
        forest: {
          DEFAULT: '#062C32',
          50: '#E9F7F1',
          100: '#D5ECE5',
          600: '#0D4852',
          700: '#083940',
          800: '#062C32',
          900: '#041D21',
        },
        dark: {
          DEFAULT: '#F8FAFC',
          surface: '#FFFFFF',
          surface2: '#F1F5F9',
          surface3: '#E2E8F0',
          border: '#E2E8E5',
        },
        light: {
          DEFAULT: '#10233F',
          muted: '#65748B',
          border: '#E2E8E5',
        }
      },
      fontFamily: {
        display: ['"Plus Jakarta Sans"', '"Inter"', 'system-ui', 'sans-serif'],
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
        'card-hover': '0 10px 26px rgba(19,199,163,0.18), 0 4px 10px rgba(15,23,42,0.06)',
        'glow': '0 0 20px rgba(19,199,163,0.35)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-up': 'slideUp 0.4s ease-out',
        'pulse-gold': 'pulseGold 2s infinite',
      },
      keyframes: {
        fadeIn: { '0%': { opacity: '0' }, '100%': { opacity: '1' } },
        slideUp: { '0%': { opacity: '0', transform: 'translateY(20px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        pulseGold: { '0%, 100%': { boxShadow: '0 0 0 0 rgba(19,199,163,0.35)' }, '50%': { boxShadow: '0 0 0 8px rgba(19,199,163,0)' } },
      }
    },
  },
  plugins: [],
};
