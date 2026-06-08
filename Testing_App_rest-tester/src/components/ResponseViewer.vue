<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  response: Object,
})

const activeTab = ref('body')

const statusColor = computed(() => {
  if (!props.response) return ''
  const s = props.response.status
  if (s >= 200 && s < 300) return 'bg-green-500/20 text-green-400 border-green-500/30'
  if (s >= 300 && s < 400) return 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30'
  if (s >= 400 && s < 500) return 'bg-orange-500/20 text-orange-400 border-orange-500/30'
  if (s >= 500) return 'bg-red-500/20 text-red-400 border-red-500/30'
  return 'bg-gray-500/20 text-gray-400 border-gray-500/30'
})

const formattedBody = computed(() => {
  if (!props.response?.body) return ''
  try {
    const parsed = typeof props.response.body === 'string'
      ? JSON.parse(props.response.body)
      : props.response.body
    return JSON.stringify(parsed, null, 2)
  } catch {
    return typeof props.response.body === 'string'
      ? props.response.body
      : JSON.stringify(props.response.body, null, 2)
  }
})

const responseHeaders = computed(() => {
  if (!props.response?.headers) return []
  return Object.entries(props.response.headers).map(([key, value]) => ({ key, value }))
})

function syntaxHighlight(json) {
  if (!json) return ''
  return json
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?)/g, (match) => {
      let cls = 'text-green-400' // string
      if (/:\s*$/.test(match)) {
        cls = 'text-purple-400' // key
      }
      return `<span class="${cls}">${match}</span>`
    })
    .replace(/\b(true|false)\b/g, '<span class="text-yellow-400">$1</span>')
    .replace(/\b(null)\b/g, '<span class="text-gray-500">$1</span>')
    .replace(/\b(-?\d+\.?\d*([eE][+-]?\d+)?)\b/g, '<span class="text-blue-400">$1</span>')
}

function copyBody() {
  navigator.clipboard.writeText(formattedBody.value)
}
</script>

<template>
  <div class="h-full flex flex-col">
    <div v-if="!response" class="flex-1 flex items-center justify-center text-gray-500">
      <div class="text-center">
        <svg class="w-16 h-16 mx-auto mb-4 opacity-30" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
        <p class="text-sm">Send a request to see the response</p>
      </div>
    </div>

    <div v-else class="flex-1 flex flex-col min-h-0">
      <!-- Status bar -->
      <div class="flex items-center gap-3 mb-3 flex-shrink-0">
        <span class="px-3 py-1 rounded-full text-xs font-bold border" :class="statusColor">
          {{ response.status }} {{ response.statusText }}
        </span>
        <span class="text-xs text-gray-400">
          <span class="text-gray-500">Time:</span> {{ response.duration }}ms
        </span>
        <span v-if="response.size" class="text-xs text-gray-400">
          <span class="text-gray-500">Size:</span> {{ response.size }}
        </span>
      </div>

      <!-- Error display -->
      <div v-if="response.error" class="bg-red-500/10 border border-red-500/30 rounded-lg p-4 mb-3 flex-shrink-0">
        <p class="text-red-400 text-sm font-mono">{{ response.error }}</p>
      </div>

      <!-- Tabs -->
      <div class="border-b border-gray-700 mb-3 flex-shrink-0">
        <nav class="flex gap-1">
          <button
            v-for="tab in ['body', 'headers']"
            :key="tab"
            @click="activeTab = tab"
            class="px-4 py-2 text-sm capitalize rounded-t-lg transition-colors"
            :class="activeTab === tab ? 'bg-gray-800 text-primary-400 border-b-2 border-primary-500' : 'text-gray-400 hover:text-gray-200'"
          >
            {{ tab }}
          </button>
        </nav>
      </div>

      <!-- Body Tab -->
      <div v-if="activeTab === 'body'" class="flex-1 min-h-0 flex flex-col">
        <div class="flex justify-end mb-2 flex-shrink-0">
          <button @click="copyBody" class="text-xs text-gray-400 hover:text-primary-400 flex items-center gap-1">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><rect x="9" y="9" width="13" height="13" rx="2" ry="2" stroke-width="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1" stroke-width="2"/></svg>
            Copy
          </button>
        </div>
        <pre class="flex-1 overflow-auto bg-gray-800/50 rounded-lg p-4 text-xs font-mono leading-relaxed border border-gray-700/50" v-html="syntaxHighlight(formattedBody)"></pre>
      </div>

      <!-- Headers Tab -->
      <div v-if="activeTab === 'headers'" class="flex-1 overflow-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-gray-700">
              <th class="text-left py-2 px-3 text-gray-400 font-medium text-xs uppercase">Header</th>
              <th class="text-left py-2 px-3 text-gray-400 font-medium text-xs uppercase">Value</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="h in responseHeaders" :key="h.key" class="border-b border-gray-800">
              <td class="py-2 px-3 font-mono text-purple-400 text-xs">{{ h.key }}</td>
              <td class="py-2 px-3 font-mono text-gray-300 text-xs break-all">{{ h.value }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
