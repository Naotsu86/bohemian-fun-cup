<template>
  <span
    class="rank-trend"
    :class="trendClass"
    :title="title"
    :aria-label="title"
  >
    <template v-if="change > 0">
      <span class="triangle triangle-up"></span>
      <strong>{{ change }}</strong>
    </template>

    <template v-else-if="change < 0">
      <span class="triangle triangle-down"></span>
      <strong>{{ Math.abs(change) }}</strong>
    </template>

    <template v-else>
      <span class="triangle triangle-left"></span>
      <span class="triangle triangle-right"></span>
    </template>
  </span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  change: {
    type: Number,
    default: 0
  }
})

const trendClass = computed(() => {
  if (props.change > 0) return 'trend-up'
  if (props.change < 0) return 'trend-down'
  return 'trend-same'
})

const title = computed(() => {
  if (props.change > 0) {
    return `${props.change} Platz${props.change === 1 ? '' : 'e'} gestiegen`
  }

  if (props.change < 0) {
    const amount = Math.abs(props.change)
    return `${amount} Platz${amount === 1 ? '' : 'e'} verloren`
  }

  return 'Keine Veränderung seit dem letzten Spiel'
})
</script>

<style scoped>
.rank-trend{
  display:inline-flex;
  align-items:center;
  justify-content:center;
  gap:3px;
  min-width:28px;
  height:18px;
  vertical-align:middle;
  font-size:10px;
  font-weight:950;
}

.rank-trend strong{
  line-height:1;
}

.trend-up{color:#16823a}
.trend-down{color:#b91c1c}
.trend-same{
  color:#fff;
  filter:drop-shadow(1px 0 0 #5f6f86)
         drop-shadow(-1px 0 0 #5f6f86)
         drop-shadow(0 1px 0 #5f6f86)
         drop-shadow(0 -1px 0 #5f6f86);
}

.triangle{
  display:inline-block;
  width:0;
  height:0;
}

.triangle-up{
  border-left:6px solid transparent;
  border-right:6px solid transparent;
  border-bottom:10px solid currentColor;
}

.triangle-down{
  border-left:6px solid transparent;
  border-right:6px solid transparent;
  border-top:10px solid currentColor;
}

.triangle-left{
  border-top:5px solid transparent;
  border-bottom:5px solid transparent;
  border-right:8px solid currentColor;
}

.triangle-right{
  border-top:5px solid transparent;
  border-bottom:5px solid transparent;
  border-left:8px solid currentColor;
}
</style>
