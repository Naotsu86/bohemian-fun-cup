<template>
  <div class="markdown-content" v-html="html"></div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  markdown: {
    type: String,
    default: ''
  }
})

const html = computed(() => renderMarkdown(props.markdown))

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
}

function inlineFormat(value) {
  return escapeHtml(value)
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
}

function renderMarkdown(markdown) {
  const lines = String(markdown || '').replace(/\r\n/g, '\n').split('\n')
  const out = []
  let inList = false

  function closeList() {
    if (inList) {
      out.push('</ul>')
      inList = false
    }
  }

  for (const rawLine of lines) {
    const line = rawLine.trim()

    if (!line) {
      closeList()
      continue
    }

    if (line === '---') {
      closeList()
      out.push('<hr>')
      continue
    }

    if (line.startsWith('# ')) {
      closeList()
      out.push(`<h1>${inlineFormat(line.slice(2))}</h1>`)
      continue
    }

    if (line.startsWith('## ')) {
      closeList()
      out.push(`<h2>${inlineFormat(line.slice(3))}</h2>`)
      continue
    }

    if (line.startsWith('### ')) {
      closeList()
      out.push(`<h3>${inlineFormat(line.slice(4))}</h3>`)
      continue
    }

    if (line.startsWith('- ') || line.startsWith('* ')) {
      if (!inList) {
        out.push('<ul>')
        inList = true
      }
      out.push(`<li>${inlineFormat(line.slice(2))}</li>`)
      continue
    }

    closeList()
    out.push(`<p>${inlineFormat(line)}</p>`)
  }

  closeList()
  return out.join('\n')
}
</script>
