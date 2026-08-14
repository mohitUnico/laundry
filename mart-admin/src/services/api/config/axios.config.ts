import axios, { AxiosInstance } from 'axios';

const defaultBaseUrl = '/api/v1';
// In development we prefer same-origin calls so Vite can proxy `/api/*` to the
// local backend and we avoid CORS + environment mismatches.
// In production builds, VITE_API_BASE_URL can point to the deployed API.
const baseURL = import.meta.env.DEV ? defaultBaseUrl : import.meta.env.VITE_API_BASE_URL || defaultBaseUrl;

const axiosInstance: AxiosInstance = axios.create({
  baseURL,
  // Default 30s to avoid dev DB timeouts; override via VITE_API_TIMEOUT if needed.
  timeout: parseInt(import.meta.env.VITE_API_TIMEOUT || '30000'),
  headers: {
    'Content-Type': 'application/json',
  },
});

export default axiosInstance;
