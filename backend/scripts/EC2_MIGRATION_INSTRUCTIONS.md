# EC2 Migration Instructions - Fix for Errors

## Issue 1: Connection String Typo
You had `postgresq1` instead of `postgresql` in your connection string.

## Issue 2: Migration Name with Spaces
The migration name should be `remove_payment_pending_order_status` (with underscores, no spaces).

## Corrected Commands

### Step 1: Run the SQL Migration

**Option A: Using psql with corrected connection string**
```bash
psql "postgresql://postgres:laundry_project_1234@db.ponworwiiguwzjclluhl.supabase.co:5432/postgres?sslmode=require" -f scripts/remove_payment_pending.sql
```

**Option B: If you have .env file on EC2, use it:**
```bash
# Load environment variables
source .env

# Run migration
psql "$DATABASE_URL" -f scripts/remove_payment_pending.sql
```

**Option C: Interactive psql session**
```bash
# Connect
psql "postgresql://postgres:laundry_project_1234@db.ponworwiiguwzjclluhl.supabase.co:5432/postgres?sslmode=require"

# Then run:
\i scripts/remove_payment_pending.sql

# Verify (optional):
SELECT unnest(enum_range(NULL::"OrderStatus")) AS order_status;

# Exit
\q
```

### Step 2: Mark Migration as Applied (After SQL Runs Successfully)

**IMPORTANT:** Use underscores, NOT spaces in the migration name:
```bash
npx prisma migrate resolve --applied 20260128000000_remove_payment_pending_order_status
```

**NOT:** `remove payment pending_order_status` ❌
**YES:** `remove_payment_pending_order_status` ✅

## Troubleshooting

### If you get "Network is unreachable":
1. Check if your EC2 instance has internet access
2. Verify the connection string is correct (note: `postgresql` not `postgresq1`)
3. Check if your EC2 security group allows outbound connections on port 5432
4. Verify Supabase allows connections from your EC2 IP

### If migration file not found:
```bash
# Check if file exists
ls -la scripts/remove_payment_pending.sql

# If not, you may need to upload it or clone the repo
```

### If psql command not found:
```bash
# Install PostgreSQL client
sudo apt-get update
sudo apt-get install postgresql-client -y
```

## Verification Commands

After running the migration, verify it worked:

```bash
# Connect to database
psql "postgresql://postgres:laundry_project_1234@db.ponworwiiguwzjclluhl.supabase.co:5432/postgres?sslmode=require"

# Check enum values (should NOT show payment_pending)
SELECT unnest(enum_range(NULL::"OrderStatus")) AS order_status;

# Check for any orders still with payment_pending (should return 0)
SELECT COUNT(*) FROM orders WHERE order_status = 'payment_pending';

# Exit
\q
```

