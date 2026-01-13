import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
        },
    },
    server: {
        port: 3000,
        proxy: {
            '/api': {
                target: process.env.VITE_API_PROXY_TARGET || 'http://localhost:5000',
                changeOrigin: true,
                secure: false,
                configure: (proxy, _options) => {
                    proxy.on('error', (err, _req, res) => {
                        console.error('Proxy error:', err);
                    });
                },
            },
        },
    },
    build: {
        outDir: 'dist',
        sourcemap: true,
        chunkSizeWarningLimit: 1000,
        rollupOptions: {
            output: {
                manualChunks: {
                    vendor: ['react', 'react-dom', 'react-router-dom'],
                    mui: ['@mui/material', '@mui/icons-material'],
                    charts: ['recharts'],
                },
            },
        },
    },
    optimizeDeps: {
        include: ['react', 'react-dom', 'react-router-dom', '@mui/material'],
    },
});
