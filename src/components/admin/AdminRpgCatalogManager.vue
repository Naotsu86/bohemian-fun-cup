<template>
  <div class="card pixel-card menu-window admin-rpg-catalog">
    <h2>🏷️ Titel & Spezialattacken</h2>
    <div class="menu-body">
      <div class="catalog-tabs">
        <button class="btn" :class="{ primary: tab === 'titles' }" @click="tab = 'titles'">Titel</button>
        <button class="btn" :class="{ primary: tab === 'specials' }" @click="tab = 'specials'">Spezialattacken</button>
        <button class="btn" @click="load" :disabled="loading">Aktualisieren</button>
      </div>

      <p v-if="message" class="hint">{{ message }}</p>
      <p v-if="error" class="error-small">{{ error }}</p>

      <template v-if="tab === 'titles'">
        <button class="btn primary full" @click="addTitle">Neuen Titel anlegen</button>
        <CatalogRow
          v-for="row in titles"
          :key="row._key"
          :row="row"
          type="title"
          @save="saveTitleRow"
          @delete="deleteTitleRow"
        />
      </template>

      <template v-else>
        <button class="btn primary full" @click="addSpecial">Neue Spezialattacke anlegen</button>
        <CatalogRow
          v-for="row in specials"
          :key="row._key"
          :row="row"
          type="special"
          @save="saveSpecialRow"
          @delete="deleteSpecialRow"
        />
      </template>
    </div>
  </div>
</template>

<script setup>
import { defineComponent, h, onMounted, ref } from 'vue'
import { deleteSpecial, deleteTitle, loadRpgCatalogs, saveSpecial, saveTitle } from '../../services/rpgCatalogService'

const tab = ref('titles')
const titles = ref([])
const specials = ref([])
const loading = ref(false)
const message = ref('')
const error = ref('')

onMounted(load)

function defaultReq() {
  return { req_teamgeist: 0, req_geschwindigkeit: 0, req_kraft: 0, req_technik: 0, req_ehrgeiz: 0 }
}

async function load() {
  loading.value = true
  message.value = ''
  error.value = ''
  try {
    const data = await loadRpgCatalogs()
    titles.value = data.titles.map(row => ({ ...defaultReq(), ...row, _key: `title-${row.id}` }))
    specials.value = data.specials.map(row => ({ ...defaultReq(), ...row, _key: `special-${row.id}` }))
  } catch (e) {
    error.value = e.message || 'Daten konnten nicht geladen werden.'
  } finally {
    loading.value = false
  }
}

function addTitle() {
  titles.value.unshift({ id: null, name: '', description: '', min_level: 1, ...defaultReq(), sort_order: 100, active: true, _key: `new-title-${Date.now()}` })
}

function addSpecial() {
  specials.value.unshift({ id: null, name: '', description: '', min_level: 1, ...defaultReq(), sort_order: 100, active: true, _key: `new-special-${Date.now()}` })
}

async function saveTitleRow(row) {
  message.value = ''
  error.value = ''
  try {
    await saveTitle(row)
    message.value = `Titel "${row.name}" gespeichert.`
    await load()
  } catch (e) {
    error.value = e.message || 'Titel konnte nicht gespeichert werden.'
  }
}

async function deleteTitleRow(row) {
  if (!row.id || !confirm(`Titel "${row.name}" wirklich löschen?`)) return
  try {
    await deleteTitle(row.id)
    message.value = `Titel "${row.name}" gelöscht.`
    await load()
  } catch (e) {
    error.value = e.message || 'Titel konnte nicht gelöscht werden.'
  }
}

async function saveSpecialRow(row) {
  message.value = ''
  error.value = ''
  try {
    await saveSpecial(row)
    message.value = `Spezialattacke "${row.name}" gespeichert.`
    await load()
  } catch (e) {
    error.value = e.message || 'Spezialattacke konnte nicht gespeichert werden.'
  }
}

async function deleteSpecialRow(row) {
  if (!row.id || !confirm(`Spezialattacke "${row.name}" wirklich löschen?`)) return
  try {
    await deleteSpecial(row.id)
    message.value = `Spezialattacke "${row.name}" gelöscht.`
    await load()
  } catch (e) {
    error.value = e.message || 'Spezialattacke konnte nicht gelöscht werden.'
  }
}

const CatalogRow = defineComponent({
  props: { row: Object, type: String },
  emits: ['save', 'delete'],
  setup(props, { emit }) {
    const field = (label, key, inputType = 'text') => h('div', { class: 'field' }, [
      h('label', label),
      h('input', {
        type: inputType,
        min: inputType === 'number' ? 0 : undefined,
        value: props.row[key] ?? '',
        onInput: e => { props.row[key] = inputType === 'number' ? Number(e.target.value || 0) : e.target.value }
      })
    ])

    return () => h('div', { class: 'catalog-row' }, [
      h('div', { class: 'catalog-grid' }, [
        h('div', { class: 'field id-field' }, [h('label', 'Nr.'), h('input', { value: props.row.id || 'neu', disabled: true })]),
        field('Name', 'name'),
        field('Beschreibung', 'description'),
        field('Level', 'min_level', 'number'),
        field('Teamgeist', 'req_teamgeist', 'number'),
        field('Speed', 'req_geschwindigkeit', 'number'),
        field('Kraft', 'req_kraft', 'number'),
        field('Technik', 'req_technik', 'number'),
        field('Ehrgeiz', 'req_ehrgeiz', 'number'),
        field('Sort', 'sort_order', 'number'),
        h('label', { class: 'check-field' }, [
          h('input', { type: 'checkbox', checked: props.row.active, onChange: e => { props.row.active = e.target.checked } }),
          ' Aktiv'
        ])
      ]),
      h('div', { class: 'catalog-actions' }, [
        h('button', { class: 'btn primary', onClick: () => emit('save', props.row) }, 'Speichern'),
        h('button', { class: 'btn danger', disabled: !props.row.id, onClick: () => emit('delete', props.row) }, 'Löschen')
      ])
    ])
  }
})
</script>

<style scoped>
.catalog-tabs{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}
.catalog-row{border:3px solid #c5a66f;background:#fffdf6;padding:10px;margin-top:12px}
.catalog-grid{display:grid;gap:8px;align-items:end;grid-template-columns:.65fr 1.2fr 2fr repeat(7,.7fr) .65fr}
.field label{display:block;font-size:11px;color:#5f6f86;margin-bottom:3px}
.field input{width:100%;border:3px solid #b99b69;background:#fffdf6;padding:7px;font-weight:800}
.id-field input{opacity:.75;background:#f8edc8}
.check-field{display:flex;gap:6px;align-items:center;font-weight:800;padding-bottom:8px}
.catalog-actions{display:flex;justify-content:flex-end;gap:8px;margin-top:10px}
@media(max-width:1100px){.catalog-grid{grid-template-columns:1fr 1fr}}
@media(max-width:640px){.catalog-grid{grid-template-columns:1fr}.catalog-actions{flex-direction:column}}
</style>
