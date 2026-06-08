<script setup>
import { ref } from 'vue'

const props = defineProps({
  collections: Array,
  request: Object,
})

const emit = defineEmits(['save', 'close'])

const selectedCollection = ref(props.collections.length ? props.collections[0].id : '')
const requestName = ref(`${props.request.method} ${props.request.url}`)

function save() {
  if (selectedCollection.value && requestName.value) {
    emit('save', {
      collectionId: selectedCollection.value,
      name: requestName.value,
    })
  }
}
</script>

<template>
  <div class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50" @click.self="$emit('close')">
    <div class="bg-gray-900 border border-gray-700 rounded-xl p-6 w-full max-w-md shadow-2xl">
      <h3 class="text-lg font-semibold text-gray-100 mb-4">Save to Collection</h3>

      <div class="space-y-4">
        <div>
          <label class="block text-xs text-gray-400 mb-1">Request name</label>
          <input
            v-model="requestName"
            class="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm font-mono focus:outline-none focus:border-primary-500"
          />
        </div>

        <div>
          <label class="block text-xs text-gray-400 mb-1">Collection</label>
          <select
            v-model="selectedCollection"
            class="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm focus:outline-none focus:border-primary-500"
          >
            <option v-for="col in collections" :key="col.id" :value="col.id">{{ col.name }}</option>
          </select>
          <p v-if="!collections.length" class="text-xs text-yellow-400 mt-1">Create a collection first in the sidebar</p>
        </div>
      </div>

      <div class="flex justify-end gap-2 mt-6">
        <button @click="$emit('close')" class="px-4 py-2 text-sm text-gray-400 hover:text-gray-200 transition-colors">Cancel</button>
        <button
          @click="save"
          :disabled="!selectedCollection || !requestName"
          class="bg-primary-600 hover:bg-primary-500 disabled:opacity-50 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
        >
          Save
        </button>
      </div>
    </div>
  </div>
</template>
