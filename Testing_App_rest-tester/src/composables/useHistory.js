import { useLocalStorage } from '@vueuse/core'

export function useHistory() {
  const history = useLocalStorage('rest-tester-history', [])

  function addToHistory(entry) {
    const item = {
      id: Date.now().toString(36) + Math.random().toString(36).slice(2, 7),
      timestamp: new Date().toISOString(),
      method: entry.method,
      url: entry.url,
      headers: entry.headers,
      body: entry.body,
      status: entry.status,
      duration: entry.duration,
    }
    history.value.unshift(item)
    if (history.value.length > 100) {
      history.value = history.value.slice(0, 100)
    }
  }

  function clearHistory() {
    history.value = []
  }

  function removeFromHistory(id) {
    history.value = history.value.filter(h => h.id !== id)
  }

  return { history, addToHistory, clearHistory, removeFromHistory }
}
