<template>
  <div class="avatar-item-grid-panel">
    <div class="avatar-item-grid-title">Accessoires</div>

    <div class="avatar-item-grid">
      <button
        v-for="item in items"
        :key="item.id"
        class="avatar-item-cell"
        :class="{
          selected: item.id === modelValue,
          locked: !isUnlocked(item)
        }"
        type="button"
        @click="select(item)"
      >
        <span class="avatar-item-icon">{{ item.icon || '▣' }}</span>
        <span class="avatar-item-name">{{ item.label }}</span>
        <span v-if="!isUnlocked(item)" class="avatar-lock">🔒</span>
      </button>
    </div>

    <p class="avatar-item-hint">
      Ausgegraute Items werden später durch Siege, Platzierungen oder Events freigeschaltet.
    </p>
  </div>
</template>

<script setup>
import { avatarOptions, isOptionUnlocked } from '../../services/avatarOptions'

const props = defineProps({
  modelValue: {
    type: String,
    required: true
  },
  unlockedItems: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['update:modelValue'])

const items = avatarOptions.accessoryItem

function isUnlocked(item) {
  return isOptionUnlocked(item, props.unlockedItems)
}

function select(item) {
  if (!isUnlocked(item)) return
  emit('update:modelValue', item.id)
}
</script>

<style scoped>
.avatar-item-grid-panel{
  border:3px solid #c5a66f;
  background:#fff4d2;
  padding:8px;
  margin-top:8px;
}

.avatar-item-grid-title{
  font-family:var(--font-pixel, 'Silkscreen', monospace);
  letter-spacing:.08em;
  font-size:12px;
  margin-bottom:7px;
}

.avatar-item-grid{
  display:grid;
  grid-template-columns:repeat(5, minmax(44px, 1fr));
  gap:6px;
}

.avatar-item-cell{
  position:relative;
  min-height:54px;
  border:3px solid #b89354;
  background:#fffdf6;
  display:grid;
  place-items:center;
  padding:4px;
  cursor:pointer;
  box-shadow:2px 2px 0 rgba(0,0,0,.16);
}

.avatar-item-cell.selected{
  outline:3px solid #4f8d33;
  outline-offset:-5px;
  background:#dff4c8;
}

.avatar-item-cell.locked{
  filter:grayscale(1);
  opacity:.45;
  cursor:not-allowed;
}

.avatar-item-icon{
  font-size:18px;
  line-height:1;
}

.avatar-item-name{
  font-size:9px;
  line-height:1.1;
  color:#2b2115;
  word-break:break-word;
}

.avatar-lock{
  position:absolute;
  right:2px;
  top:1px;
  font-size:11px;
}

.avatar-item-hint{
  margin:7px 0 0;
  color:#5f6f86;
  font-size:12px;
}

@media(max-width:760px){
  .avatar-item-grid{
    grid-template-columns:repeat(3, 1fr);
  }
}
</style>
