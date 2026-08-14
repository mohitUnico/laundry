# Backend Connection Troubleshooting

## Issue: "Failed to load customers" / ECONNREFUSED

### Root Cause
The frontend (Vite dev server on port 3000) cannot connect to the backend API server (expected on port 5000).

### Solution Steps

1. **Start the Backend Server**
   ```bash
   cd backend
   npm install  # If dependencies not installed
   npm run dev  # Starts server on port 5000
   ```

2. **Verify Backend is Running**
   - Check terminal output for: `🚀 Server running in development mode on port 5000`
   - Test health endpoint: `http://localhost:5000/health`
   - Test API endpoint: `http://localhost:5000/api/v1/admin/customers`

3. **Check Environment Variables**
   - Backend: Ensure `.env` file exists in `backend/` directory
   - Frontend: Vite proxy is configured to forward `/api` to `http://localhost:5000`

4. **Verify Port Availability**
   - Port 5000 should be free (backend)
   - Port 3000 should be free (frontend)
   - If port is in use, kill the process or change PORT in backend `.env`

5. **Restart Both Servers**
   - Stop both frontend and backend
   - Start backend first: `cd backend && npm run dev`
   - Then start frontend: `cd mart-admin && npm run dev`

### Quick Check Commands

```bash
# Check if backend is running
curl http://localhost:5000/health

# Check if port 5000 is in use
# Windows:
netstat -ano | findstr :5000
# Linux/Mac:
lsof -i :5000

# Kill process on port 5000 (Windows)
# Find PID from netstat, then:
taskkill /PID <PID> /F
```

### Expected Behavior
- Backend logs: `🚀 Server running in development mode on port 5000`
- Frontend should successfully proxy `/api/*` requests to backend
- Customer list should load without errors

