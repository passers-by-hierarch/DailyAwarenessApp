/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // 主色板
        'bg-primary': '#F5F5F7',
        'bg-secondary': '#FFFFFF',
        'bg-tertiary': '#F0F0F2',
        'text-primary': '#1D1D1F',
        'text-secondary': '#86868B',
        'text-tertiary': '#AEAEB2',
        'border': '#E5E5EA',
        'divider': '#D1D1D6',
        
        // 功能色
        'accent': '#3D8B7A',
        'accent-light': '#E8F5F2',
        'success': '#34C759',
        'success-light': '#E5F9E9',
        'warning': '#FF9500',
        'warning-light': '#FFF4E5',
        'danger': '#FF3B30',
        'danger-light': '#FFECEA',
        'info': '#007AFF',
        'info-light': '#E5F3FF',

        // 渐变
        'voice-start': '#5BAE94',
        'voice-end': '#3D8B7A',
      },
      fontFamily: {
        'mono': ['SF Mono', 'Menlo', 'Monaco', 'Courier New', 'monospace'],
      },
      borderRadius: {
        'sm': '6px',
        'md': '10px',
        'lg': '14px',
        'xl': '20px',
      },
      fontSize: {
        'title-large': ['28px', { lineHeight: '36px', fontWeight: '600' }],
        'title-medium': ['22px', { lineHeight: '28px', fontWeight: '600' }],
        'title-small': ['18px', { lineHeight: '24px', fontWeight: '600' }],
        'body-large': ['17px', { lineHeight: '24px', fontWeight: '400' }],
        'body': ['15px', { lineHeight: '22px', fontWeight: '400' }],
        'body-small': ['13px', { lineHeight: '18px', fontWeight: '400' }],
        'caption': ['12px', { lineHeight: '16px', fontWeight: '400' }],
        'time': ['14px', { lineHeight: '18px', fontWeight: '500' }],
        'stat-large': ['48px', { lineHeight: '56px', fontWeight: '600' }],
      },
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
      },
      boxShadow: {
        'sm': '0 1px 3px rgba(0,0,0,0.04)',
        'md': '0 2px 8px rgba(0,0,0,0.06)',
        'lg': '0 4px 16px rgba(0,0,0,0.08)',
        'xl': '0 8px 32px rgba(0,0,0,0.12)',
      },
    },
  },
  plugins: [],
}