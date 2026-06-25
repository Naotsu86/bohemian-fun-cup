<template>
  <div class="table-wrap">
    <table>
      <thead>
        <tr><th>Platz</th><th>Spieler</th><th>Punkte</th><th>Spiele</th><th>Siege</th><th>Ø</th></tr>
      </thead>
      <tbody>
        <tr v-for="(row, index) in rows" :key="row.id">
          <td class="place">{{ medal(index) }}</td>
          <td><b>{{ row.name }}</b></td>
          <td>{{ row.points }}</td>
          <td>{{ row.games }}</td>
          <td>{{ row.wins }}</td>
          <td>{{ row.avg }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
defineProps({ rows: { type: Array, required: true } })
function medal(index) {
  if (index === 0) return '🥇'
  if (index === 1) return '🥈'
  if (index === 2) return '🥉'
  return index + 1
}
</script>
