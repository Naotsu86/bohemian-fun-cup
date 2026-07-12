<template>
  <div class="avatar-preview-wrap" :class="{ 'avatar-preview-compact': compact }">
    <div class="avatar-stage">
      <template v-if="!compact">
        <div class="avatar-sun"></div>
        <div class="avatar-cloud cloud-a"></div>
        <div class="avatar-cloud cloud-b"></div>
      </template>

      <img class="avatar-layer layer-shadow" :src="shadowSrc" alt="" />
      <img class="avatar-layer layer-body" :src="baseAvatar" alt="Avatar" />
      <img class="avatar-layer layer-belly" :src="bellySrc" alt="" />
      <img class="avatar-layer layer-eyes" :src="eyesSrc" alt="" />
      <img class="avatar-layer layer-beak" :src="beakSrc" alt="" />
      <img class="avatar-layer layer-feet" :src="feetSrc" alt="" />
      <img v-if="shortsSrc" class="avatar-layer layer-shorts" :src="shortsSrc" alt="" />
      <img v-if="headSrc" class="avatar-layer layer-head" :src="headSrc" alt="" />
      <img v-if="accessorySrc" class="avatar-layer layer-accessory" :src="accessorySrc" alt="" />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { getOptionFile } from '../../services/avatarOptions'

const props = defineProps({
  avatar: {
    type: Object,
    required: true
  },
  compact: {
    type: Boolean,
    default: false
  }
})

const base = import.meta.env.BASE_URL

// Body ist der einzige einfärbbare Layer (mehrere Dateien je Farbe).
const baseAvatar = computed(() => {
  const file = getOptionFile('bodyColor', props.avatar.body_color || 'black') || 'body_black.png'
  const url = `${base}avatar/${file}`
  return url
})

// Belly, Eyes, Beak, Feet, Shadow sind aktuell feste Einzeldateien (keine Farbvarianten).
const bellySrc = computed(() => `${base}avatar/belly.png`)
const eyesSrc = computed(() => `${base}avatar/eyes.png`)
const beakSrc = computed(() => `${base}avatar/beak.png`)
const feetSrc = computed(() => `${base}avatar/feet.png`)
const shadowSrc = computed(() => `${base}avatar/shadow.png`)

const headSrc = computed(() => layerSrc('headItem', 'head', props.avatar.head_item))
const shortsSrc = computed(() => layerSrc('shortsItem', 'shorts', props.avatar.shorts_item))
const accessorySrc = computed(() => layerSrc('accessoryItem', 'accessory', props.avatar.accessory_item))

function layerSrc(optionGroup, folder, id) {
  const file = getOptionFile(optionGroup, id || 'none')
  if (!file || file === 'none.svg' || id === 'none' || !id) return ''
  return `${base}avatar/${folder}/${file}`
}
</script>

<style scoped>
.avatar-preview-wrap{width:100%;display:grid;place-items:center}
.avatar-stage{position:relative;width:230px;height:230px;overflow:hidden;border:3px solid #2b2115;background:linear-gradient(#7bd3ff 0 42%,#2f9bd1 42% 47%,#f8d98a 47% 68%,#e7b861 68%);box-shadow:4px 4px 0 rgba(0,0,0,.22)}
.avatar-layer{position:absolute;inset:0;width:100%;height:100%;object-fit:contain;image-rendering:pixelated;user-select:none;pointer-events:none}
.layer-shadow{z-index:1}
.layer-body{z-index:2}
.layer-belly{z-index:3}
.layer-eyes{z-index:4}
.layer-beak{z-index:5}
.layer-feet{z-index:6}
.layer-shorts{z-index:7}
.layer-head{z-index:8}
.layer-accessory{z-index:9}
.avatar-sun{position:absolute;right:20px;top:16px;width:22px;height:22px;background:#ffd65a;border:3px solid #b97819;border-radius:50%;z-index:0}
.avatar-cloud{position:absolute;height:10px;background:#fff;border-radius:8px;opacity:.8;z-index:0}
.cloud-a{left:22px;top:30px;width:46px}.cloud-b{left:92px;top:20px;width:34px}

.avatar-preview-compact{
  width:100%;
  height:100%;
  display:block;
}
.avatar-preview-compact .avatar-stage{
  width:100%;
  height:100%;
  border:none;
  box-shadow:none;
  background:transparent;
}
</style>
