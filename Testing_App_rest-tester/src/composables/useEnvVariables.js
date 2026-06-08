import { useLocalStorage } from '@vueuse/core'

export function useEnvVariables() {
  const envVars = useLocalStorage('rest-tester-env', [])

  function addVariable(key, value) {
    envVars.value.push({ id: Date.now().toString(36), key, value, enabled: true })
  }

  function removeVariable(id) {
    envVars.value = envVars.value.filter(v => v.id !== id)
  }

  function updateVariable(id, key, value) {
    const v = envVars.value.find(e => e.id === id)
    if (v) {
      v.key = key
      v.value = value
    }
  }

  function toggleVariable(id) {
    const v = envVars.value.find(e => e.id === id)
    if (v) v.enabled = !v.enabled
  }

  function interpolate(str) {
    if (!str) return str
    return str.replace(/\{\{(\w+)\}\}/g, (match, varName) => {
      const found = envVars.value.find(v => v.key === varName && v.enabled)
      return found ? found.value : match
    })
  }

  return { envVars, addVariable, removeVariable, updateVariable, toggleVariable, interpolate }
}
