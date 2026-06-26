import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'
export default defineConfig({base:'/bohemian-fun-cup/',plugins:[vue(),VitePWA({registerType:'autoUpdate',includeAssets:['icons/icon-192.png','icons/icon-512.png'],manifest:{name:'Bohemian Fun Cup',short_name:'Fun Cup',description:'Beachvolleyball-Turnier live verwalten.',theme_color:'#0f172a',background_color:'#f4f6f8',display:'standalone',start_url:'/bohemian-fun-cup/',icons:[{src:'icons/icon-192.png',sizes:'192x192',type:'image/png'},{src:'icons/icon-512.png',sizes:'512x512',type:'image/png'}]}})]})
