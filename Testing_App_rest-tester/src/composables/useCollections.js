import { useLocalStorage } from '@vueuse/core'

export function useCollections() {
  const collections = useLocalStorage('rest-tester-collections', [])

  function createCollection(name) {
    const collection = {
      id: Date.now().toString(36) + Math.random().toString(36).slice(2, 7),
      name,
      requests: [],
      createdAt: new Date().toISOString(),
    }
    collections.value.push(collection)
    return collection
  }

  function deleteCollection(id) {
    collections.value = collections.value.filter(c => c.id !== id)
  }

  function renameCollection(id, name) {
    const col = collections.value.find(c => c.id === id)
    if (col) col.name = name
  }

  function saveRequest(collectionId, request) {
    const col = collections.value.find(c => c.id === collectionId)
    if (col) {
      const req = {
        id: Date.now().toString(36) + Math.random().toString(36).slice(2, 7),
        name: request.name || `${request.method} ${request.url}`,
        method: request.method,
        url: request.url,
        headers: request.headers,
        body: request.body,
        savedAt: new Date().toISOString(),
      }
      col.requests.push(req)
    }
  }

  function removeRequest(collectionId, requestId) {
    const col = collections.value.find(c => c.id === collectionId)
    if (col) {
      col.requests = col.requests.filter(r => r.id !== requestId)
    }
  }

  return { collections, createCollection, deleteCollection, renameCollection, saveRequest, removeRequest }
}
