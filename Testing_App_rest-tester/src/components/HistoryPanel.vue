<script setup>
import { computed } from 'vue'

const props = defineProps({
  history: Array,
})

const emit = defineEmits(['select', 'remove', 'clear'])

const methodColors = {
  GET: 'bg-green-500/20 text-green-400',
  POST: 'bg-yellow-500/20 text-yellow-400',
  PUT: 'bg-blue-500/20 text-blue-400',
  PATCH: 'bg-purple-500/20 text-purple-400',
  DELETE: 'bg-red-500/20 text-red-400',
}

function formatTime(iso) {
  const d = new Date(iso)
  const now = new Date()
  const diff = now - d
  if (diff < 60000) return 'just now'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`
  return d.toLocaleDateString()
}

function shortenUrl(url) {
  try {
    const u = new URL(url)
    return u.pathname + u.search
  } catch {
    return url.length > 40 ? url.slice(0, 40) + '...' : url
  }
}
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="flex items-center justify-between mb-3 flex-shrink-0">
      <h3 class="text-sm font-semibold text-gray-300">History</h3>
      <button
        v-if="history.length"
        @click="$emit('clear')"
        class="text-xs text-gray-500 hover:text-red-400 transition-colors"
      >
        Clear all
      </button>
    </div>

    <div v-if="!history.length" class="flex-1 flex items-center justify-center">
      <p class="text-xs text-gray-600">No history yet</p>
    </div>

    <div v-else class="flex-1 overflow-y-auto space-y-1 pr-1">
      <div
        v-for="item in history"
        :key="item.id"
        @click="$emit('select', item)"
        class="group flex items-center gap-2 p-2 rounded-lg hover:bg-gray-800 cursor-pointer transition-colors"
      >
        <span class="px-1.5 py-0.5 rounded text-[10px] font-bold flex-shrink-0" :class="methodColors[item.method]">
          {{ item.method }}
        </span>
        <div class="flex-1 min-w-0">
          <p class="text-xs font-mono text-gray-300 truncate">{{ shortenUrl(item.url) }}</p>
          <p class="text-[10px] text-gray-600">{{ formatTime(item.timestamp) }}</p>
        </div>
        <span v-if="item.status" class="text-[10px] text-gray-500">{{ item.status }}</span>
        <button
          @click.stop="$emit('remove', item.id)"
          class="opacity-0 group-hover:opacity-100 text-gray-600 hover:text-red-400 p-0.5 transition-opacity"
        >
          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        </button>
      </div>
    </div>
  </div>
</template>
