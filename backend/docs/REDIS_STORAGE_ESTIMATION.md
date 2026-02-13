# Redis Storage Estimation Guide

This guide helps you estimate how much storage Redis will consume on your EC2 instance for the pickup assignment queue.

## Storage Components

Redis uses storage in two ways:
1. **Disk Storage**: Configuration files, AOF logs, RDB snapshots
2. **RAM (Memory)**: Active data storage (primary)

## Disk Storage Breakdown

### Base Installation

```bash
# Check Redis installation size
dpkg -L redis-server | xargs du -ch | tail -1
# Typically: ~5-10 MB
```

**Base Installation**: ~5-10 MB

### AOF File (Persistence Log)

The AOF file grows as operations are performed. For pickup assignment queue:

**Per Job**:
- Job creation: ~200-500 bytes
- Job completion: ~100-200 bytes
- Job removal: ~100 bytes

**Estimated Growth**:
- **100 jobs/day**: ~50 KB/day → ~1.5 MB/month
- **1000 jobs/day**: ~500 KB/day → ~15 MB/month
- **10,000 jobs/day**: ~5 MB/day → ~150 MB/month

**AOF File Size**: Typically 10-50 MB for moderate usage

### RDB Snapshots (Optional)

RDB snapshots are periodic backups:

**Snapshot Size**:
- Empty Redis: ~100 bytes
- 1000 jobs: ~500 KB - 1 MB
- 10,000 jobs: ~5-10 MB

**RDB File Size**: Typically 1-10 MB (depends on snapshot frequency)

### Log Files

Redis logs (if enabled):

**Log Size**:
- Default: ~1-5 MB/month
- Verbose logging: ~10-50 MB/month

## Total Disk Storage Estimate

For **pickup assignment queue** with moderate usage:

| Component | Size | Notes |
|-----------|------|-------|
| Redis Installation | ~10 MB | One-time |
| AOF File | 10-50 MB | Grows with usage |
| RDB Snapshots | 1-10 MB | If enabled |
| Log Files | 1-5 MB | Optional |
| **Total Disk** | **~15-75 MB** | Typical range |

**Conservative Estimate**: **100 MB** disk space for Redis

## RAM (Memory) Usage

Redis stores all data in RAM. This is the **primary** storage concern.

### Memory Per Job

Each BullMQ job consumes:
- **Job data**: ~200-500 bytes
- **Metadata**: ~100-200 bytes
- **Overhead**: ~100-300 bytes

**Total per job**: ~500-1000 bytes (~1 KB)

### Memory Usage Scenarios

| Jobs in Queue | Memory Usage | Notes |
|---------------|--------------|-------|
| 100 jobs | ~100 KB | Very light |
| 1,000 jobs | ~1 MB | Light |
| 10,000 jobs | ~10 MB | Moderate |
| 100,000 jobs | ~100 MB | Heavy |

### Additional Redis Overhead

Redis itself uses:
- **Base overhead**: ~5-10 MB
- **Connection overhead**: ~1 KB per connection
- **Buffer overhead**: ~5-10 MB

**Total Base RAM**: ~15-25 MB

### Total RAM Estimate

For pickup assignment queue:

| Scenario | Jobs | Memory | Total RAM |
|----------|------|--------|-----------|
| Light usage | 1,000 | ~1 MB | ~20 MB |
| Moderate usage | 10,000 | ~10 MB | ~30 MB |
| Heavy usage | 50,000 | ~50 MB | ~70 MB |

**Conservative Estimate**: **50-100 MB RAM** for typical usage

## Your Use Case: Pickup Assignment Queue

For a laundry app pickup assignment queue:

### Typical Workload

- **Orders per day**: 100-1,000
- **Jobs scheduled**: 100-1,000/day
- **Jobs in queue**: 10-100 (most process quickly)
- **Peak jobs**: 200-500 (during busy hours)

### Storage Estimate

**Disk Storage**:
- AOF file: ~10-30 MB (grows slowly)
- RDB snapshots: ~1-5 MB
- **Total Disk**: **~20-40 MB**

**RAM Usage**:
- Active jobs: ~50-500 KB
- Completed jobs (retained): ~1-10 MB
- Redis overhead: ~15-20 MB
- **Total RAM**: **~20-35 MB**

**Very Conservative Estimate**: **50 MB RAM + 50 MB Disk**

## Configuration to Limit Storage

### Limit Memory Usage

Edit `/etc/redis/redis.conf`:

```conf
# Set max memory (adjust based on your EC2 instance)
maxmemory 100mb

# Eviction policy (removes old jobs when limit reached)
maxmemory-policy allkeys-lru
```

### Limit AOF File Growth

```conf
# AOF rewrite settings (compresses AOF file)
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

### Limit Job Retention

In `backend/src/queues/pickup-assignment.queue.js`:

```javascript
defaultJobOptions: {
    removeOnComplete: {
        age: 24 * 3600,  // Keep completed jobs for 24 hours
        count: 1000,     // Keep max 1000 completed jobs
    },
    removeOnFail: {
        age: 7 * 24 * 3600,  // Keep failed jobs for 7 days
    },
}
```

## Monitoring Storage Usage

### Check Disk Usage

```bash
# Check Redis data directory
du -sh /var/lib/redis/

# Check AOF file size
ls -lh /var/lib/redis/appendonly.aof

# Check RDB file size
ls -lh /var/lib/redis/dump.rdb
```

### Check RAM Usage

```bash
# Connect to Redis
redis-cli -a your-password-here

# Check memory usage
INFO memory

# Check database size
DBSIZE

# Get memory stats
MEMORY STATS
```

### Monitor via Redis CLI

```bash
redis-cli -a your-password-here INFO memory
```

Look for:
- `used_memory`: Current memory usage in bytes
- `used_memory_human`: Human-readable format
- `used_memory_peak`: Peak memory usage

## Real-World Example

For a **moderate laundry app** (500 orders/day):

**After 1 month**:
- Disk: ~30 MB (AOF + RDB)
- RAM: ~25 MB (active + overhead)

**After 1 year**:
- Disk: ~100-200 MB (with AOF rewrites)
- RAM: ~30-40 MB (stable, jobs process quickly)

## EC2 Instance Recommendations

### Minimum Requirements

- **t3.micro** (1 GB RAM): ✅ Sufficient for light usage
- **t3.small** (2 GB RAM): ✅ Recommended for moderate usage
- **t3.medium** (4 GB RAM): ✅ Plenty of headroom

**Disk**: Any EC2 instance has enough disk space (Redis uses <100 MB)

## Summary

For your pickup assignment queue:

| Resource | Typical Usage | Conservative Estimate |
|----------|--------------|----------------------|
| **Disk** | 20-40 MB | 100 MB |
| **RAM** | 20-35 MB | 50-100 MB |

**Bottom Line**: Redis will use **<100 MB disk** and **<100 MB RAM** for typical usage. This is negligible on any EC2 instance.

## Tips to Minimize Storage

1. **Enable job cleanup** (already configured)
2. **Set memory limits** with eviction policy
3. **Enable AOF rewrites** (automatic compression)
4. **Monitor regularly** and clean up old data if needed
5. **Use RDB snapshots** instead of AOF if disk is tight (less durable but smaller)

Your EC2 instance will have plenty of resources for Redis! 🎉
