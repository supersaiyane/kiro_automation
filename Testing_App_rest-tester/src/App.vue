<script setup>
import { ref, reactive } from 'vue'
import axios from 'axios'
import RequestBuilder from './components/RequestBuilder.vue'
import ResponseViewer from './components/ResponseViewer.vue'
import HistoryPanel from './components/HistoryPanel.vue'
import CollectionsPanel from './components/CollectionsPanel.vue'
import EnvVariables from './components/EnvVariables.vue'
import SaveToCollectionModal from './components/SaveToCollectionModal.vue'
import { useHistory } from './composables/useHistory.js'
import { useCollections } from './composables/useCollections.js'
import { useEnvVariables } from './composables/useEnvVariables.js'

const { history, addToHistory, clearHistory, removeFromHistory } = useHistory()
const { collections, createCollection, deleteCollection, renameCollection, saveRequest, removeRequest } = useCollections()
const { envVars, addVariable, removeVariable, updateVariable, toggleVariable, interpolate } = useEnvVariables()

const CORS_PROXY = 'https://corsproxy.io/?'

const request = ref({
  method: 'GET',
  url: '',
  headers: [],
  body: '',
  params: [],
})

const response = ref(null)
const loading = ref(false)
const corsProxy = ref(false)
const activePanel = ref('history')
const showSaveModal = ref(false)

async function sendRequest() {
  if (!request.value.url) return

  loading.value = true
  response.value = null

  let url = interpolate(request.value.url)

  // Append query params
  const params = (request.value.params || []).filter(p => p.key && p.enabled !== false)
  if (params.length) {
    const searchParams = new URLSearchParams()
    params.forEach(p => searchParams.append(interpolate(p.key), interpolate(p.value)))
    const separator = url.includes('?') ? '&' : '?'
    url = url + separator + searchParams.toString()
  }

  if (corsProxy.value) {
    url = CORS_PROXY + encodeURIComponent(url)
  }

  // Build headers
  const headers = {}
  request.value.headers
    .filter(h => h.key && h.enabled !== false)
    .forEach(h => {
      headers[interpolate(h.key)] = interpolate(h.value)
    })

  // Build body
  let data = undefined
  if (['POST', 'PUT', 'PATCH'].includes(request.value.method) && request.value.body) {
    const bodyStr = interpolate(request.value.body)
    try {
      data = JSON.parse(bodyStr)
      if (!headers['Content-Type'] && !headers['content-type']) {
        headers['Content-Type'] = 'application/json'
      }
    } catch {
      data = bodyStr
    }
  }

  const startTime = performance.now()

  try {
    const res = await axios({
      method: request.value.method.toLowerCase(),
      url,
      headers,
      data,
      validateStatus: () => true,
      timeout: 30000,
    })

    const duration = Math.round(performance.now() - startTime)
    const bodyStr = typeof res.data === 'string' ? res.data : JSON.stringify(res.data)
    const size = new Blob([bodyStr]).size

    response.value = {
      status: res.status,
      statusText: res.statusText,
      headers: res.headers,
      body: res.data,
      duration,
      size: formatSize(size),
    }

    addToHistory({
      method: request.value.method,
      url: request.value.url,
      headers: request.value.headers,
      body: request.value.body,
      status: res.status,
      duration,
    })
  } catch (err) {
    const duration = Math.round(performance.now() - startTime)
    response.value = {
      status: 0,
      statusText: 'Error',
      headers: {},
      body: null,
      duration,
      error: err.message || 'Request failed',
    }

    addToHistory({
      method: request.value.method,
      url: request.value.url,
      headers: request.value.headers,
      body: request.value.body,
      status: 0,
      duration,
    })
  } finally {
    loading.value = false
  }
}

function formatSize(bytes) {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / 1048576).toFixed(1) + ' MB'
}

function loadRequest(item) {
  request.value = {
    method: item.method || 'GET',
    url: item.url || '',
    headers: item.headers || [],
    body: item.body || '',
    params: item.params || [],
  }
}

function handleSaveToCollection(data) {
  saveRequest(data.collectionId, {
    name: data.name,
    method: request.value.method,
    url: request.value.url,
    headers: request.value.headers,
    body: request.value.body,
  })
  showSaveModal.value = false
}
</script>

<template>
  <div class="h-screen flex flex-col overflow-hidden">
    <!-- Header -->
    <header class="bg-gray-900 border-b border-gray-800 px-6 py-3 flex items-center justify-between flex-shrink-0">
      <div class="flex items-center gap-3">
        <div class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
        </div>
        <h1 class="text-lg font-bold text-gray-100">REST Tester</h1>
        <span class="text-[10px] bg-gray-800 text-gray-400 px-2 py-0.5 rounded-full">v1.0</span>
      </div>
      <button
        @click="showSaveModal = true"
        :disabled="!request.url"
        class="text-xs text-gray-400 hover:text-primary-400 disabled:opacity-30 flex items-center gap-1 transition-colors"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"/></svg>
        Save
      </button>
    </header>

    <!-- Main layout -->
    <div class="flex-1 flex min-h-0">
      <!-- Sidebar -->
      <aside class="w-72 bg-gray-900 border-r border-gray-800 flex flex-col flex-shrink-0">
        <!-- Panel tabs -->
        <div class="flex border-b border-gray-800">
          <button
            v-for="panel in ['history', 'collections', 'env']"
            :key="panel"
            @click="activePanel = panel"
            class="flex-1 py-2.5 text-[11px] font-medium capitalize transition-colors"
            :class="activePanel === panel ? 'text-primary-400 border-b-2 border-primary-500 bg-gray-800/50' : 'text-gray-500 hover:text-gray-300'"
          >
            {{ panel === 'env' ? 'Env Vars' : panel }}
          </button>
        </div>

        <!-- Panel content -->
        <div class="flex-1 p-3 min-h-0 overflow-hidden">
          <HistoryPanel
            v-if="activePanel === 'history'"
            :history="history"
            @select="loadRequest"
            @remove="removeFromHistory"
            @clear="clearHistory"
          />
          <CollectionsPanel
            v-if="activePanel === 'collections'"
            :collections="collections"
            @create="createCollection"
            @delete="deleteCollection"
            @rename="renameCollection"
            @select-request="loadRequest"
            @remove-request="removeRequest"
          />
          <EnvVariables
            v-if="activePanel === 'env'"
            :env-vars="envVars"
            @add="addVariable"
            @remove="removeVariable"
            @update="updateVariable"
            @toggle="toggleVariable"
          />
        </div>
      </aside>

      <!-- Main content -->
      <main class="flex-1 flex flex-col min-h-0 min-w-0">
        <!-- Request builder -->
        <div class="p-6 border-b border-gray-800 flex-shrink-0">
          <RequestBuilder
            v-model="request"
            :loading="loading"
            :cors-proxy="corsProxy"
            @send="sendRequest"
            @update:cors-proxy="corsProxy = $event"
          />
        </div>

        <!-- Response viewer -->
        <div class="flex-1 p-6 min-h-0 overflow-hidden">
          <ResponseViewer :response="response" />
        </div>
      </main>
    </div>

    <!-- Save modal -->
    <SaveToCollectionModal
      v-if="showSaveModal"
      :collections="collections"
      :request="request"
      @save="handleSaveToCollection"
      @close="showSaveModal = false"
    />
  </div>
</template>
