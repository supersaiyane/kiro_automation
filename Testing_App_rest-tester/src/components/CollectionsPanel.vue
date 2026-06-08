<script setup>
import { ref } from 'vue'

const props = defineProps({
  collections: Array,
})

const emit = defineEmits(['create', 'delete', 'rename', 'selectRequest', 'removeRequest'])

const newName = ref('')
const expandedId = ref(null)
const editingId = ref(null)
const editName = ref('')

const methodColors = {
  GET: 'text-green-400',
  POST: 'text-yellow-400',
  PUT: 'text-blue-400',
  PATCH: 'text-purple-400',
  DELETE: 'text-red-400',
}

function createCollection() {
  if (newName.value.trim()) {
    emit('create', newName.value.trim())
    newName.value = ''
  }
}

function toggleExpand(id) {
  expandedId.value = expandedId.value === id ? null : id
}

function startEdit(col) {
  editingId.value = col.id
  editName.value = col.name
}

function finishEdit(id) {
  if (editName.value.trim()) {
    emit('rename', id, editName.value.trim())
  }
  editingId.value = null
}
</script>

<template>
  <div class="h-full flex flex-col">
    <h3 class="text-sm font-semibold text-gray-300 mb-3 flex-shrink-0">Collections</h3>

    <!-- Create new -->
    <div class="flex gap-2 mb-3 flex-shrink-0">
      <input
        v-model="newName"
        @keydown.enter="createCollection"
        placeholder="New collection..."
        class="flex-1 bg-gray-800 border border-gray-700 rounded px-2 py-1.5 text-xs placeholder-gray-600 focus:outline-none focus:border-primary-500"
      />
      <button
        @click="createCollection"
        :disabled="!newName.trim()"
        class="bg-primary-600 hover:bg-primary-500 disabled:opacity-30 text-white text-xs px-2 py-1.5 rounded transition-colors"
      >
        +
      </button>
    </div>

    <div v-if="!collections.length" class="flex-1 flex items-center justify-center">
      <p class="text-xs text-gray-600">No collections yet</p>
    </div>

    <div v-else class="flex-1 overflow-y-auto space-y-1">
      <div v-for="col in collections" :key="col.id" class="rounded-lg border border-gray-800">
        <!-- Collection header -->
        <div class="flex items-center gap-2 p-2 hover:bg-gray-800 cursor-pointer transition-colors" @click="toggleExpand(col.id)">
          <svg class="w-3 h-3 text-gray-500 transition-transform" :class="expandedId === col.id && 'rotate-90'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>

          <template v-if="editingId === col.id">
            <input
              v-model="editName"
              @keydown.enter="finishEdit(col.id)"
              @blur="finishEdit(col.id)"
              @click.stop
              class="flex-1 bg-gray-700 border border-primary-500 rounded px-2 py-0.5 text-xs focus:outline-none"
              autofocus
            />
          </template>
          <template v-else>
            <span class="flex-1 text-xs text-gray-300 font-medium">{{ col.name }}</span>
            <span class="text-[10px] text-gray-600">{{ col.requests.length }}</span>
          </template>

          <button @click.stop="startEdit(col)" class="text-gray-600 hover:text-primary-400 p-0.5">
            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
          </button>
          <button @click.stop="$emit('delete', col.id)" class="text-gray-600 hover:text-red-400 p-0.5">
            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
          </button>
        </div>

        <!-- Requests list -->
        <div v-if="expandedId === col.id && col.requests.length" class="border-t border-gray-800">
          <div
            v-for="req in col.requests"
            :key="req.id"
            @click="$emit('selectRequest', req)"
            class="group flex items-center gap-2 px-3 py-1.5 hover:bg-gray-800/50 cursor-pointer"
          >
            <span class="text-[10px] font-bold" :class="methodColors[req.method]">{{ req.method }}</span>
            <span class="flex-1 text-[11px] text-gray-400 font-mono truncate">{{ req.name }}</span>
            <button
              @click.stop="$emit('removeRequest', col.id, req.id)"
              class="opacity-0 group-hover:opacity-100 text-gray-600 hover:text-red-400"
            >
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
