# Redis on EC2 Setup Guide

This guide shows how to install and configure Redis on your EC2 instance with persistence enabled for the pickup assignment queue.

## Prerequisites

- EC2 instance running (Amazon Linux 2, Ubuntu, or similar)
- SSH access to the instance
- Root/sudo access

## Installation

### Ubuntu/Debian (Recommended for your setup)

```bash
# Update package list
sudo apt update

# Install Redis server
sudo apt install redis-server -y

# Start Redis
sudo systemctl start redis-server

# Enable Redis to start on boot
sudo systemctl enable redis-server

# Check status (should show "active (running)")
sudo systemctl status redis-server

# Test Redis is working
redis-cli ping
# Should return: PONG
```

### Amazon Linux 2

```bash
# Update system
sudo yum update -y

# Install Redis 6
sudo amazon-linux-extras install redis6 -y

# Start Redis
sudo systemctl start redis

# Enable Redis to start on boot
sudo systemctl enable redis

# Check status
sudo systemctl status redis
```

## Configure Persistence

### Option 1: AOF (Append-Only File) - Recommended

AOF logs every write operation and is more durable:

```bash
# Edit Redis configuration
# On Ubuntu, the config file is at:
sudo nano /etc/redis/redis.conf

# On Amazon Linux 2:
# sudo nano /etc/redis.conf
```

Find and modify these settings:

```conf
# Enable AOF persistence
appendonly yes

# AOF sync strategy (choose one):
# everysec: sync every second (good balance of performance and durability)
appendfsync everysec

# OR for maximum durability (slower):
# appendfsync always

# Disable RDB snapshots if using AOF only (optional)
save ""
```

### Option 2: RDB Snapshots (Periodic Backups)

RDB creates periodic snapshots:

```bash
sudo nano /etc/redis.conf
```

Find and modify:

```conf
# Enable RDB snapshots
# Save after 900 seconds if at least 1 key changed
save 900 1
# Save after 300 seconds if at least 10 keys changed
save 300 10
# Save after 60 seconds if at least 10000 keys changed
save 60 10000

# RDB file location
dir /var/lib/redis
```

### Option 3: Both AOF + RDB (Maximum Safety)

Enable both for redundancy:

```conf
# Enable AOF
appendonly yes
appendfsync everysec

# Enable RDB snapshots
save 900 1
save 300 10
save 60 10000
```

## Security Configuration

### Set a Password (Recommended)

```bash
sudo nano /etc/redis.conf
```

Find and uncomment/modify:

```conf
# Set a strong password
requirepass your-strong-password-here
```

### Bind to Localhost Only (If Redis is on same EC2 as app)

```conf
# Only allow connections from localhost
bind 127.0.0.1

# OR bind to specific IP (if app is on different server)
# bind 127.0.0.1 10.0.1.5
```

### Disable Dangerous Commands (Optional but Recommended)

```conf
# Rename dangerous commands
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_9c4d8f7a"
```

## Restart Redis

```bash
# Ubuntu/Debian
sudo systemctl restart redis-server

# Amazon Linux 2
# sudo systemctl restart redis
```

## Verify Persistence

```bash
# Connect to Redis CLI
redis-cli
# or with password:
redis-cli -a your-password-here

# Test persistence
SET test_key "test_value"
EXIT

# Restart Redis (Ubuntu)
sudo systemctl restart redis-server

# Connect again and check
redis-cli -a your-password-here
GET test_key
# Should return: "test_value"
```

## Configure Your Node.js App

Update `backend/.env`:

```env
# If Redis is on same EC2 (localhost)
REDIS_URL=redis://:your-password-here@localhost:6379

# OR if Redis is on different EC2 instance
REDIS_URL=redis://:your-password-here@10.0.1.5:6379

# OR without password (not recommended for production)
REDIS_URL=redis://localhost:6379
```

## Firewall Configuration

If Redis is on a different EC2 instance, configure security groups:

1. **Inbound Rule**: Allow TCP port 6379 from your app server's security group
2. **Outbound Rule**: Allow TCP port 6379 (usually already allowed)

**Important**: Don't expose Redis to the internet (0.0.0.0/0). Only allow from your app server.

## Monitoring

### Check Redis Status

```bash
# Check if Redis is running
sudo systemctl status redis

# Check Redis info
redis-cli -a your-password-here INFO

# Check persistence status
redis-cli -a your-password-here INFO persistence
```

### Check AOF File

```bash
# Check AOF file size and location
ls -lh /var/lib/redis/appendonly.aof

# View AOF file (read-only)
cat /var/lib/redis/appendonly.aof
```

### Check RDB Snapshots

```bash
# Check RDB file
ls -lh /var/lib/redis/dump.rdb
```

## Backup Strategy

### Manual Backup

```bash
# Create backup directory
sudo mkdir -p /backup/redis

# Copy AOF file
sudo cp /var/lib/redis/appendonly.aof /backup/redis/appendonly-$(date +%Y%m%d-%H%M%S).aof

# Copy RDB file
sudo cp /var/lib/redis/dump.rdb /backup/redis/dump-$(date +%Y%m%d-%H%M%S).rdb
```

### Automated Backup (Cron Job)

```bash
# Edit crontab
sudo crontab -e

# Add daily backup at 2 AM
0 2 * * * cp /var/lib/redis/appendonly.aof /backup/redis/appendonly-$(date +\%Y\%m\%d).aof && cp /var/lib/redis/dump.rdb /backup/redis/dump-$(date +\%Y\%m\%d).rdb
```

## Performance Tuning

### Memory Configuration

```conf
# Set max memory (adjust based on your EC2 instance size)
# Example: 512MB for t3.small
maxmemory 512mb

# Eviction policy (for job queue, use allkeys-lru)
maxmemory-policy allkeys-lru
```

### Connection Settings

```conf
# Max clients
maxclients 10000

# Timeout
timeout 300
```

## Troubleshooting

### Redis Won't Start

```bash
# Check logs
sudo journalctl -u redis -n 50

# Check configuration syntax
redis-server /etc/redis.conf --test-memory 1
```

### Permission Issues

```bash
# Ensure Redis user owns data directory
sudo chown -R redis:redis /var/lib/redis
sudo chmod 750 /var/lib/redis
```

### Connection Refused

1. Check Redis is running: `sudo systemctl status redis`
2. Check bind address in config
3. Check firewall/security groups
4. Test locally: `redis-cli -h localhost -p 6379 ping`

### Data Not Persisting

1. Check AOF/RDB is enabled in config
2. Check file permissions: `ls -la /var/lib/redis/`
3. Check disk space: `df -h`
4. Check Redis logs for errors

## Comparison: EC2 Redis vs Redis Cloud

| Feature | EC2 Redis | Redis Cloud Free |
|---------|-----------|------------------|
| **Cost** | Free (uses existing EC2) | Free |
| **Persistence** | ✅ Yes (AOF/RDB) | ❌ No |
| **Memory** | Limited by EC2 RAM | 30MB |
| **Management** | You manage | Managed |
| **Backups** | Manual/Automated | ❌ No |
| **High Availability** | Manual setup | ❌ No |
| **Setup Complexity** | Medium | Low |

## Recommended Setup for Production

1. **Enable AOF with `everysec` sync** (good balance)
2. **Set a strong password**
3. **Bind to localhost** (if app is on same EC2)
4. **Set up automated backups** (cron job)
5. **Monitor disk space** (AOF files can grow)
6. **Configure memory limits** (prevent OOM)

## Next Steps

After setting up Redis on EC2:

1. Update `REDIS_URL` in your `.env` file
2. Restart your Node.js application
3. Test the queue system with a test order
4. Monitor Redis logs and performance
5. Set up automated backups

Your pickup assignment queue will now have full persistence without any additional cost!
