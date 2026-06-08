<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  modelValue: Object,
  loading: Boolean,
  corsProxy: Boolean,
})

const emit = defineEmits(['update:modelValue', 'send', 'update:corsProxy'])

const activeTab = ref('params')

const methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']

const methodColors = {
  GET: 'text-green-400',
  POST: 'text-yellow-400',
  PUT: 'text-blue-400',
  PATCH: 'text-purple-400',
  DELETE: 'text-red-400',
}

const request = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

function updateField(field, value) {
  emit('update:modelValue', { ...props.modelValue, [field]: value })
}

function updateHeader(index, field, value) {
  const headers = [...props.modelValue.headers]
  headers[index] = { ...headers[index], [field]: value }
  updateField('headers', headers)
}

function addHeader() {
  const headers = [...props.modelValue.headers, { key: '', value: '', enabled: true }]
  updateField('headers', headers)
}

function removeHeader(index) {
  const headers = props.modelValue.headers.filter((_, i) => i !== index)
  updateField('headers', headers)
}

function updateParam(index, field, value) {
  const params = [...(props.modelValue.params || [])]
  params[index] = { ...params[index], [field]: value }
  updateField('params', params)
}

function addParam() {
  const params = [...(props.modelValue.params || []), { key: '', value: '', enabled: true }]
  updateField('params', params)
}

function removeParam(index) {
  const params = (props.modelValue.params || []).filter((_, i) => i !== index)
  updateField('params', params)
}
</script>

<template>
  <div class="space-y-4">
    <!-- URL Bar -->
    <div class="flex gap-2">
      <select
        :value="modelValue.method"
        @change="updateField('method', $event.target.value)"
        class="bg-gray-800 border border-gray-700 rounded-lg px-3 py-2.5 font-mono font-bold text-sm focus:outline-none focus:border-primary-500 cursor-pointer"
        :class="methodColors[modelValue.method]"
      >
        <option v-for="m in methods" :key="m" :value="m">{{ m }}</option>
      </select>

      <input
        :value="modelValue.url"
        @input="updateField('url', $event.target.value)"
        @keydown.enter="$emit('send')"
        type="text"
        placeholder="https://api.example.com/endpoint or use {{VAR}}"
        class="flex-1 bg-gray-800 border border-gray-700 rounded-lg px-4 py-2.5 text-sm font-mono placeholder-gray-500 focus:outline-none focus:border-primary-500"
      />

      <button
        @click="$emit('send')"
        :disabled="loading || !modelValue.url"
        class="bg-primary-600 hover:bg-primary-500 disabled:opacity-50 disabled:cursor-not-allowed text-white font-semibold px-6 py-2.5 rounded-lg transition-colors text-sm"
      >
        <span v-if="loading" class="inline-flex items-center gap-2">
          <svg class="animate-spin h-4 w-4" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>
          Sending
        </span>
        <span v-else>Send</span>
      </button>
    </div>

    <!-- CORS Toggle -->
    <div class="flex items-center gap-2 text-xs text-gray-400">
      <label class="flex items-center gap-2 cursor-pointer">
        <input
          type="checkbox"
          :checked="corsProxy"
          @change="$emit('update:corsProxy', $event.target.checked)"
          class="rounded border-gray-600 bg-gray-800 text-primary-500 focus:ring-primary-500"
        />
        <span>CORS Proxy</span>
      </label>
      <span class="text-gray-600">(prepends https://corsproxy.io/?)</span>
    </div>

    <!-- Tabs -->
    <div class="border-b border-gray-700">
      <nav class="flex gap-1">
        <button
          v-for="tab in ['params', 'headers', 'body']"
          :key="tab"
          @click="activeTab = tab"
          class="px-4 py-2 text-sm capitalize rounded-t-lg transition-colors"
          :class="activeTab === tab ? 'bg-gray-800 text-primary-400 border-b-2 border-primary-500' : 'text-gray-400 hover:text-gray-200'"
        >
          {{ tab }}
          <span v-if="tab === 'headers' && modelValue.headers.length" class="ml-1 bg-gray-700 text-gray-300 px-1.5 py-0.5 rounded-full text-xs">{{ modelValue.headers.filter(h => h.key).length }}</span>
          <span v-if="tab === 'params' && (modelValue.params || []).length" class="ml-1 bg-gray-700 text-gray-300 px-1.5 py-0.5 rounded-full text-xs">{{ (modelValue.params || []).filter(p => p.key).length }}</span>
        </button>
      </nav>
    </div>

    <!-- Params Tab -->
    <div v-if="activeTab === 'params'" class="space-y-2">
      <div v-for="(param, i) in (modelValue.params || [])" :key="i" class="flex gap-2 items-center">
        <input
          :value="param.key"
          @input="updateParam(i, 'key', $event.target.value)"
          placeholder="Key"
          class="flex-1 bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm font-mono placeholder-gray-600 focus:outline-none focus:border-primary-500"
        />
        <input
          :value="param.value"
          @input="updateParam(i, 'value', $event.target.value)"
          placeholder="Value"
          class="flex-1 bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm font-mono placeholder-gray-600 focus:outline-none focus:border-primary-500"
        />
        <button @click="removeParam(i)" class="text-gray-500 hover:text-red-400 p-1">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        </button>
      </div>
      <button @click="addParam" class="text-sm text-primary-400 hover:text-primary-300 flex items-center gap-1">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Add Parameter
      </button>
    </div>

    <!-- Headers Tab -->
    <div v-if="activeTab === 'headers'" class="space-y-2">
      <div v-for="(header, i) in modelValue.headers" :key="i" class="flex gap-2 items-center">
        <input
          :value="header.key"
          @input="updateHeader(i, 'key', $event.target.value)"
          placeholder="Header name"
          class="flex-1 bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm font-mono placeholder-gray-600 focus:outline-none focus:border-primary-500"
        />
        <input
          :value="header.value"
          @input="updateHeader(i, 'value', $event.target.value)"
          placeholder="Value"
          class="flex-1 bg-gray-800 border border-gray-700 rounded px-3 py-2 text-sm font-mono placeholder-gray-600 focus:outline-none focus:border-primary-500"
        />
        <button @click="removeHeader(i)" class="text-gray-500 hover:text-red-400 p-1">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        </button>
      </div>
      <button @click="addHeader" class="text-sm text-primary-400 hover:text-primary-300 flex items-center gap-1">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        Add Header
      </button>
    </div>

    <!-- Body Tab -->
    <div v-if="activeTab === 'body'">
      <textarea
        :value="modelValue.body"
        @input="updateField('body', $event.target.value)"
        placeholder='{"key": "value"}'
        rows="8"
        class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-sm font-mono placeholder-gray-600 focus:outline-none focus:border-primary-500 resize-y"
      ></textarea>
    </div>
  </div>
</template>
