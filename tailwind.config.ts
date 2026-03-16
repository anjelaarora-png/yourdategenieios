import type { Config } from "tailwindcss";

export default {
  darkMode: ["class"],
  content: ["./pages/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./app/**/*.{ts,tsx}", "./src/**/*.{ts,tsx}"],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: {
        DEFAULT: "1rem",
        sm: "1.5rem",
        lg: "2rem",
      },
      screens: {
        "2xl": "1400px",
      },
    },
    screens: {
      'xs': '475px',
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        sidebar: {
          DEFAULT: "hsl(var(--sidebar-background))",
          foreground: "hsl(var(--sidebar-foreground))",
          primary: "hsl(var(--sidebar-primary))",
          "primary-foreground": "hsl(var(--sidebar-primary-foreground))",
          accent: "hsl(var(--sidebar-accent))",
          "accent-foreground": "hsl(var(--sidebar-accent-foreground))",
          border: "hsl(var(--sidebar-border))",
          ring: "hsl(var(--sidebar-ring))",
        },
        gold: {
          DEFAULT: "hsl(var(--gold-start))",
          dark: "hsl(var(--gold-end))",
          glow: "hsl(var(--gold-glow))",
        },
        maroon: {
          DEFAULT: "hsl(var(--maroon-start))",
          dark: "hsl(var(--maroon-end))",
          glow: "hsl(var(--maroon-glow))",
        },
      },
      fontFamily: {
        display: ['Times New Roman', 'Times', 'Georgia', 'serif'],
        body: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
        "fade-in": {
          from: { opacity: "0", transform: "translateY(10px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        "shimmer": {
          from: { backgroundPosition: "200% 0" },
          to: { backgroundPosition: "-200% 0" },
        },
        "gift-reveal": {
          "0%": { opacity: "0", transform: "scale(0.96) translateY(8px)" },
          "100%": { opacity: "1", transform: "scale(1) translateY(0)" },
        },
        "gift-lid-lift": {
          "0%": { opacity: "1", transform: "translateY(0) scale(1)" },
          "60%": { opacity: "1", transform: "translateY(-6px) scale(1.02)" },
          "100%": { opacity: "0.4", transform: "translateY(-12px) scale(1.05)" },
        },
        "gift-bow-shine": {
          "0%": { opacity: "0.6", filter: "brightness(1)" },
          "50%": { opacity: "1", filter: "brightness(1.4)" },
          "100%": { opacity: "0.8", filter: "brightness(1.1)" },
        },
        "gift-ribbon-shine": {
          "0%": { backgroundPosition: "120% 0" },
          "100%": { backgroundPosition: "-20% 0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "fade-in": "fade-in 0.6s ease-out forwards",
        "shimmer": "shimmer 3s ease-in-out infinite",
        "gift-reveal": "gift-reveal 0.6s cubic-bezier(0.22, 1, 0.36, 1) forwards",
        "gift-lid-lift": "gift-lid-lift 0.7s cubic-bezier(0.22, 1, 0.36, 1) forwards",
        "gift-bow-shine": "gift-bow-shine 1s ease-out 0.3s forwards",
        "gift-ribbon-shine": "gift-ribbon-shine 0.8s ease-out 0.2s forwards",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config;
