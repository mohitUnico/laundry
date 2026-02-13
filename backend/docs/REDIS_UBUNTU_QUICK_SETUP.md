# Redis on Ubuntu EC2 - Quick Setup Guide

Quick setup guide for installing and configuring Redis with persistence on Ubuntu EC2 instance.

## Step 1: Install Redis

```bash
# Update package list
sudo apt update

# Install Redis server
sudo apt install redis-server -y

# Verify installation
redis-cli ping
# Should return: PONG
```

## Step 2: Configure Persistence

```bash
# Edit Redis configuration file
sudo nano /etc/redis/redis.conf
```

Find and modify these settings:

### Enable AOF Persistence (Recommended)

Find the `# appendonly` line and change it to:

```conf
# Enable AOF persistence
appendonly yes

# AOF sync strategy (every second - good balance)
appendfsync everysec
```

### Set a Password (Security)

Find the `# requirepass` line and uncomment/modify:

```conf
# Set a strong password (change this!)
requirepass your-strong-password-here
```

### Optional: Bind to Localhost Only

If your Node.js app is on the same EC2 instance, bind to localhost:

```conf
# Only allow localhost connections
bind 127.0.0.1
```

Save and exit: `Ctrl+X`, then `Y`, then `Enter`

## Step 3: Restart Redis

```bash
# Restart Redis to apply changes
sudo systemctl restart redis-server

# Check status
sudo systemctl status redis-server
# Should show: active (running)

# Enable Redis to start on boot
sudo systemctl enable redis-server
```

## Step 4: Test Persistence

```bash
# Connect to Redis (with password)
redis-cli -a your-strong-password-here

# Test persistence
SET test_key "test_value"
EXIT

# Restart Redis
sudo systemctl restart redis-server

# Connect again
redis-cli -a your-strong-password-here

# Check if data persisted
GET test_key
# Should return: "test_value"
```

## Step 5: Configure Your Node.js App

Update `backend/.env`:

```env
# Enable queue-based pickup assignment
PICKUP_ASSIGNMENT_USE_QUEUE=true

# Redis connection (same EC2 instance)
REDIS_URL=redis://:your-strong-password-here@localhost:6379
```

## Step 6: Test Connection from Node.js

```bash
cd backend

# Test Redis connection
node -e "const Redis = require('ioredis'); const r = new Redis(process.env.REDIS_URL); r.ping().then(console.log).then(() => process.exit(0));"
# Should print: PONG
```

## Step 7: Start Your Application

```bash
cd backend
npm start
```

You should see:
```
✅ Pickup assignment worker started (queue-based mode)
✅ Pickup assignment catch-up job started (safety net)
Redis connected
Redis ready
```

## Verify Everything Works

1. **Check Redis is running:**
   ```bash
   sudo systemctl status redis-server
   ```

2. **Check AOF file exists (persistence enabled):**
   ```bash
   ls -lh /var/lib/redis/appendonly.aof
   ```

3. **Check Redis info:**
   ```bash
   redis-cli -a your-strong-password-here INFO persistence
   ```
   Look for: `aof_enabled:1`

4. **Test with a real order:**
   - Create an order with `pickup_time_from` 1-2 minutes in the future
   - Check logs for "Scheduled pickup assignment job"
   - Wait for the scheduled time
   - Check logs for "Pickup assignment job completed"

## Troubleshooting

### Redis won't start

```bash
# Check logs
sudo journalctl -u redis-server -n 50

# Check config syntax
redis-server /etc/redis/redis.conf --test-memory 1
```

### Connection refused

```bash
# Check if Redis is running
sudo systemctl status redis-server

# Check if port is listening
sudo netstat -tlnp | grep 6379

# Test local connection
redis-cli -h localhost -p 6379 -a your-password ping
```

### Permission issues

```bash
# Fix ownership
sudo chown -R redis:redis /var/lib/redis
sudo chmod 750 /var/lib/redis
```

### Password not working

Make sure you're using the password you set in `/etc/redis/redis.conf`:
- Check: `grep requirepass /etc/redis/redis.conf`
- Use: `redis-cli -a your-password-here`

## Security Checklist

- [ ] Password is set (`requirepass` in config)
- [ ] Bind to localhost only (if app is on same EC2)
- [ ] Firewall configured (if Redis is on different EC2)
- [ ] AOF persistence enabled
- [ ] Redis starts on boot (`systemctl enable`)

## Next Steps

- Set up automated backups (see main guide)
- Monitor Redis memory usage
- Configure memory limits if needed
- Set up monitoring/alerts

Your Redis is now configured with persistence and ready for production use! 🎉
