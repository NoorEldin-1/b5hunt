import defaultTheme from 'tailwindcss/defaultTheme';
import forms from '@tailwindcss/forms';
import daisyui from 'daisyui';

/** @type {import('tailwindcss').Config} */
export default {
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/views/**/*.blade.php',
        './app/Livewire/**/*.php',
    ],

    theme: {
        extend: {
            fontFamily: {
                // Arabic-first. Cairo reads well in both AR and Latin.
                sans: ['Cairo', 'Figtree', ...defaultTheme.fontFamily.sans],
            },
        },
    },

    // DaisyUI v4 (Tailwind v3 compatible). RTL is handled via <html dir="rtl">.
    plugins: [forms, daisyui],

    daisyui: {
        logs: false,
        darkTheme: 'b5hunt',
        themes: [
            {
                // Brand dark theme — navy + gold, matching the pitch deck.
                b5hunt: {
                    'primary': '#c9a227',          // gold
                    'primary-content': '#1a1304',
                    'secondary': '#1d4e6f',        // deep teal/navy
                    'secondary-content': '#e6f0f6',
                    'accent': '#22d3ee',           // cyan accent
                    'accent-content': '#04212a',
                    'neutral': '#0e2336',
                    'neutral-content': '#cbd9e6',
                    'base-100': '#0b1726',         // page background
                    'base-200': '#0e2336',
                    'base-300': '#13314a',
                    'base-content': '#dbe7f1',
                    'info': '#38bdf8',
                    'success': '#22c55e',
                    'warning': '#f59e0b',
                    'error': '#ef4444',
                    '--rounded-box': '0.9rem',
                    '--rounded-btn': '0.6rem',
                },
            },
            'light',
        ],
    },
};
