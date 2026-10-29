import { defineConfig } from 'vite'

export default defineConfig({
  server: {
    port: 5173,
    open: true,
    headers: {
      'Content-Security-Policy': "default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'"
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
