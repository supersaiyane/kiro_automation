<script setup>
import { ref } from 'vue'

const props = defineProps({
  envVars: Array,
})

const emit = defineEmits(['add', 'remove', 'update', 'toggle'])

const newKey = ref('')
const newValue = ref('')

function addVar() {
  if (newKey.value.trim()) {
    emit('add', newKey.value.trim(), newValue.value)
    newKey.value = ''
    newValue.value = ''
  }
}
</script>

<template>
  <div class="h-full flex flex-col">
    <h3 class="text-sm font-semibold text-gray-300 mb-2 flex-shrink-0">Environment Variables</h3>
    <p class="text-[10px] text-gray-600 mb-3 flex-shrink-0">Use <code class="bg-gray-800 px-1 rounded" v-text="'{{VAR_NAME}}'"></code> in URLs, headers, or body</p>

    <!-- Add new -->
    <div class="flex gap-1 mb-3 flex-shrink-0">
      <input
        v-model="newKey"
        @keydown.enter="addVar"
        placeholder="KEY"
        class="w-1/3 bg-gray-800 border border-gray-700 rounded px-2 py-1.5 text-xs font-mono placeholder-gray-600 focus:outline-none focus:border-primary-500"
      />
      <input
        v-model="newValue"
        @keydown.enter="addVar"
        placeholder="value"
        class="flex-1 bg-gray-800 border border-gray-700 rounded px-2 py-1.5 text-xs font-mono placeholder-gray-600 focus:outline-none focus:border-primary-500"
      />
      <button
        @click="addVar"
        :disabled="!newKey.trim()"
        class="bg-primary-600 hover:bg-primary-500 disabled:opacity-30 text-white text-xs px-2 py-1.5 rounded transition-colors"
      >
        +
      </button>
    </div>

    <div v-if="!envVars.length" class="flex-1 flex items-center justify-center">
      <p class="text-xs text-gray-600">No variables defined</p>
    </div>

    <div v-else class="flex-1 overflow-y-auto space-y-1">
      <div
        v-for="v in envVars"
        :key="v.id"
        class="group flex items-center gap-1.5 p-1.5 rounded hover:bg-gray-800 transition-colors"
        :class="!v.enabled && 'opacity-50'"
      >
        <input
          type="checkbox"
          :checked="v.enabled"
          @change="$emit('toggle', v.id)"
          class="rounded border-gray-600 bg-gray-800 text-primary-500 focus:ring-primary-500 w-3 h-3"
        />
        <input
          :value="v.key"
          @change="$emit('update', v.id, $event.target.value, v.value)"
          class="w-1/3 bg-transparent border-b border-transparent hover:border-gray-700 focus:border-primary-500 px-1 py-0.5 text-[11px] font-mono text-primary-400 focus:outline-none"
        />
        <input
          :value="v.value"
          @change="$emit('update', v.id, v.key, $event.target.value)"
          class="flex-1 bg-transparent border-b border-transparent hover:border-gray-700 focus:border-primary-500 px-1 py-0.5 text-[11px] font-mono text-gray-300 focus:outline-none"
        />
        <button
          @click="$emit('remove', v.id)"
          class="opacity-0 group-hover:opacity-100 text-gray-600 hover:text-red-400 p-0.5 transition-opacity"
        >
          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        </button>
      </div>
    </div>
  </div>
</template>
