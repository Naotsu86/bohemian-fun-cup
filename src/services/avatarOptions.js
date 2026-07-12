export const avatarOptions = {
  bodyColor: [
    { id: 'black', label: 'Schwarz', file: 'body_black.png', swatch: '#191B1C' },
    { id: 'blue', label: 'Blau', file: 'body_blue.png', swatch: '#2F7FC1' },
    { id: 'navy', label: 'Navy', file: 'body_navy.png', swatch: '#243B64' },
    { id: 'teal', label: 'Türkis', file: 'body_teal.png', swatch: '#209C9A' },
    { id: 'green', label: 'Grün', file: 'body_green.png', swatch: '#4E8E35' },
    { id: 'lime', label: 'Lime', file: 'body_lime.png', swatch: '#86B93D' },
    { id: 'yellow', label: 'Gelb', file: 'body_yellow.png', swatch: '#D8A91F' },
    { id: 'orange', label: 'Orange', file: 'body_orange.png', swatch: '#D96B1F' },
    { id: 'red', label: 'Rot', file: 'body_red.png', swatch: '#C94B3D' },
    { id: 'pink', label: 'Pink', file: 'body_pink.png', swatch: '#D96AA5' },
    { id: 'purple', label: 'Lila', file: 'body_purple.png', swatch: '#7B4A9E' },
    { id: 'brown', label: 'Braun', file: 'body_brown.png', swatch: '#7A4A28' },
    { id: 'gray', label: 'Grau', file: 'body_gray.png', swatch: '#8A8D8F' }
  ],

  bellyColor: [
    { id: 'default', label: 'Standard', file: 'belly.png', swatch: '#FAF5EB' }
  ],

  headItem: [
    { id: 'none', label: 'Keine', file: 'none.svg', unlocked: true }
  ],

  shortsItem: [
    { id: 'none', label: 'Keine', file: 'none.svg', unlocked: true }
  ],

  accessoryItem: [
    { id: 'none', label: 'Keines', file: 'none.svg', icon: '—', unlocked: true },
    { id: 'crown', label: 'Krone', file: 'none.svg', icon: '👑', unlocked: false },
    { id: 'cape', label: 'Umhang', file: 'none.svg', icon: '🧣', unlocked: false }
  ]
}

export function getOptionLabel(group, id) {
  return avatarOptions[group]?.find(option => option.id === id)?.label || id || '-'
}

export function getOptionFile(group, id) {
  return avatarOptions[group]?.find(option => option.id === id)?.file || ''
}

export function getAvailableOptions(group, unlockedIds = []) {
  return (avatarOptions[group] || []).filter(option =>
    option.unlocked ||
    unlockedIds.includes(option.id) ||
    group === 'bodyColor' ||
    group === 'bellyColor'
  )
}

export function getNextOption(group, currentId, direction = 1, unlockedIds = []) {
  const available = getAvailableOptions(group, unlockedIds)
  if (available.length === 0) return currentId
  const currentIndex = Math.max(0, available.findIndex(option => option.id === currentId))
  const nextIndex = (currentIndex + direction + available.length) % available.length
  return available[nextIndex].id
}

export function isOptionUnlocked(option, unlockedIds = []) {
  return Boolean(option.unlocked || unlockedIds.includes(option.id))
}
