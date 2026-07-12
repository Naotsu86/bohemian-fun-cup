import { createApp } from 'vue'
import { registerSW } from 'virtual:pwa-register'
import App from './App.vue'
import './style.css'
import './styles/theme/font-theme.css'

registerSW({
  immediate: true,
  onNeedRefresh() {
    window.location.reload()
  },
  onOfflineReady() {
    console.info('Bohemian Fun Cup ist offline bereit.')
  },
  onRegisteredSW(_swUrl, registration) {
    if (!registration) return

    setInterval(() => {
      registration.update()
    }, 60 * 60 * 1000)
  }
})

createApp(App).mount('#app')
