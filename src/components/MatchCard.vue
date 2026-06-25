<template>
  <div class="match">
    <div class="match-head">
      <span class="badge">Spiel {{ number }} · {{ modeLabel(match.mode) }}</span>
      <button v-if="editable" class="btn danger" @click="$emit('delete')">Löschen</button>
    </div>

    <div class="teams">
      <div class="team">
        <b>Team A</b>
        <div v-for="id in match.teamA" :key="id">{{ nameOf(id) }}</div>
      </div>
      <div class="team">
        <b>Team B</b>
        <div v-for="id in match.teamB" :key="id">{{ nameOf(id) }}</div>
      </div>
    </div>

    <div class="score">
      <input
        v-if="editable"
        type="number"
        min="0"
        max="99"
        :value="match.scoreA"
        placeholder="A"
        @change="$emit('score', { id: match.id, side: 'scoreA', value: $event.target.value })"
      />
      <div v-else class="scorebox">{{ match.scoreA !== '' ? match.scoreA : '–' }}</div>

      <div class="colon">:</div>

      <input
        v-if="editable"
        type="number"
        min="0"
        max="99"
        :value="match.scoreB"
        placeholder="B"
        @change="$emit('score', { id: match.id, side: 'scoreB', value: $event.target.value })"
      />
      <div v-else class="scorebox">{{ match.scoreB !== '' ? match.scoreB : '–' }}</div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  match: {
    type: Object,
    required: true,
  },
  number: {
    type: Number,
    required: true,
  },
  editable: {
    type: Boolean,
    default: false,
  },
  nameOf: {
    type: Function,
    required: true,
  },
})

defineEmits(['delete', 'score'])

function modeLabel(mode) {
  return String(mode).replace('v', ' gegen ')
}
</script>
