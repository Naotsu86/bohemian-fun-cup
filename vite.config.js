import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'

const appVersion = '6.0.1-v1-test'
const basePath = '/bohemian-fun-cup/'

export default defineConfig({
  base: basePath,
  define: {
    __APP_VERSION__: JSON.stringify(appVersion)
  },
  plugins: [
    vue(),
    VitePWA({
      registerType: 'autoUpdate',
      injectRegister: false,
      workbox: {
        cleanupOutdatedCaches: true,
        clientsClaim: true,
        skipWaiting: true,
        navigateFallback: `${basePath}index.html`,
        globPatterns: ['**/*.*']
      },
      includeAssets: [
        'icons/icon-192.png',
        'icons/icon-512.png',
        'apple-touch-icon.png'
      ],
      manifest: {
        name: 'Bohemian Fun Cup',
        short_name: 'Fun Cup',
        description: 'Beachvolleyball-Turnier live verwalten.',
        theme_color: '#0f172a',
        background_color: '#f4f6f8',
        display: 'standalone',
        scope: basePath,
        start_url: basePath,
        id: `${basePath}?v=${appVersion}`,
        icons: [
          {
            src: 'icons/icon-192.png',
            sizes: '192x192',
            type: 'image/png',
            purpose: 'any'
          },
          {
            src: 'icons/icon-512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any'
          },
          {
            src: 'icons/icon-512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable'
          }
        ]
      }
    })
  ]
})
