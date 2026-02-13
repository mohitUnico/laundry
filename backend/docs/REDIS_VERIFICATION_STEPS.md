# Redis Verification Steps

Follow these steps to verify Redis is configured correctly with persistence.

## Step 1: Test Basic Connection

```bash
# Test Redis is responding
redis-cli ping
# Should return: PONG
```

## Step 2: Check Persistence Configuration

```bash
# Check if AOF is enabled
redis-cli CONFIG GET appendonly
# Should return: appendonly yes

# Check AOF sync setting
redis-cli CONFIG GET appendfsync
# Should return: appendfsync everysec (or always)
```

## Step 3: Test Persistence

```bash
# Connect to Redis
redis-cli

# Set a test value
SET test_persistence "Hello Redis"

# Check it's there
GET test_persistence
# Should return: "Hello Redis"

# Exit Redis CLI
EXIT

# Restart Redis
sudo systemctl restart redis-server

# Connect again
redis-cli

# Check if data persisted
GET test_persistence
# Should return: "Hello Redis" (if persistence works)
```

## Step 4: Check AOF File

```bash
# Check if AOF file exists
ls -lh /var/lib/redis/appendonly.aof

# Check file size (should grow as you add data)
du -h /var/lib/redis/appendonly.aof
```

## Step 5: Check Password (if set)

```bash
# If password is set, test connection with password
redis-cli -a your-password-here ping
# Should return: PONG

# If no password, this will work:
redis-cli ping
```

## Step 6: Get Redis Info

```bash
# Get all Redis info
redis-cli INFO

# Get persistence info
redis-cli INFO persistence

# Get memory info
redis-cli INFO memory

# Get server info
redis-cli INFO server
```

## Step 7: Test from Node.js

```bash
cd backend

# Test connection (replace with your password if set)
node -e "const Redis = require('ioredis'); const r = new Redis('redis://localhost:6379'); r.ping().then(console.log).then(() => process.exit(0));"

# Or with password:
# node -e "const Redis = require('ioredis'); const r = new Redis('redis://:your-password@localhost:6379'); r.ping().then(console.log).then(() => process.exit(0));"
```

## Expected Results

✅ **Redis running**: `systemctl status` shows "active (running)"  
✅ **Persistence enabled**: `CONFIG GET appendonly` returns "yes"  
✅ **AOF file exists**: `/var/lib/redis/appendonly.aof` exists  
✅ **Data persists**: Test value survives restart  
✅ **Connection works**: `redis-cli ping` returns PONG  
✅ **Node.js connects**: Test script returns PONG  

## Troubleshooting

### If persistence test fails:

1. Check config file:
   ```bash
   sudo grep -E "appendonly|appendfsync" /etc/redis/redis.conf
   ```

2. Restart Redis:
   ```bash
   sudo systemctl restart redis-server
   ```

3. Check logs:
   ```bash
   sudo journalctl -u redis-server -n 50
   ```

### If password doesn't work:

1. Check config:
   ```bash
   sudo grep requirepass /etc/redis/redis.conf
   ```

2. Restart Redis after changing password:
   ```bash
   sudo systemctl restart redis-server
   ```
