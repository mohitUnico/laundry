# How to Run Migration on AWS EC2 Server

## Option 1: Run Migration from EC2 Server (Recommended)

### Step 1: SSH into your EC2 instance
```bash
ssh -i your-key.pem ec2-user@your-ec2-ip-address
# Or if using ubuntu:
ssh -i your-key.pem ubuntu@your-ec2-ip-address
```

### Step 2: Install PostgreSQL client (if not already installed)
```bash
# For Amazon Linux 2 / RHEL
sudo yum install postgresql15 -y

# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql-client -y
```

### Step 3: Navigate to your project directory
```bash
cd /path/to/your/laundry/backend
```

### Step 4: Run the SQL migration
You have two options:

#### Option A: Using psql with connection string from .env
```bash
# Extract DATABASE_URL from your .env file and run:
psql "postgresql://postgres:laundry_project_1234@db.ponworwiiguwzjclluhl.supabase.co:5432/postgres?sslmode=require" -f scripts/remove_payment_pending.sql
```

#### Option B: Using psql interactively
```bash
# Connect to database
psql "postgresql://postgres:laundry_project_1234@db.ponworwiiguwzjclluhl.supabase.co:5432/postgres?sslmode=require"

# Then copy and paste the SQL from scripts/remove_payment_pending.sql
# Or use \i command:
\i scripts/remove_payment_pending.sql

# Exit psql
\q
```

## Option 2: Run Migration Directly from Local Machine

If you prefer to run it from your local machine (connecting to Supabase):

### Step 1: Install PostgreSQL client locally (if not installed)
```bash
# Windows (using Chocolatey)
choco install postgresql

# Mac (using Homebrew)
brew install postgresql

# Linux
sudo apt-get install postgresql-client  # Ubuntu/Debian
sudo yum install postgresql15          # RHEL/Amazon Linux
```

### Step 2: Navigate to backend directory
```bash
cd backend
```

### Step 3: Run the migration
```bash
psql "postgresql://postgres:laundry_project_1234@db.ponworwiiguwzjclluhl.supabase.co:5432/postgres?sslmode=require" -f scripts/remove_payment_pending.sql
```

## Option 3: Using Prisma Migrate (After Manual SQL Execution)

If you run the SQL manually, mark the migration as applied:

```bash
# On EC2 or locally
cd backend
npx prisma migrate resolve --applied 20260128000000_remove_payment_pending_order_status
```

## Verification

After running the migration, verify it worked:

```bash
# Connect to database
psql "postgresql://postgres:laundry_project_1234@db.ponworwiiguwzjclluhl.supabase.co:5432/postgres?sslmode=require"

# Check if payment_pending is removed from enum
SELECT unnest(enum_range(NULL::"OrderStatus")) AS order_status;

# Check if any orders still have payment_pending (should return 0 rows)
SELECT COUNT(*) FROM orders WHERE order_status = 'payment_pending';

# Exit
\q
```

## Troubleshooting

### If you get SSL connection error:
Add `?sslmode=require` to your connection string (already included above).

### If you get authentication error:
- Verify your database credentials in `.env` file
- Make sure your IP is whitelisted in Supabase (if IP restrictions are enabled)

### If trigger recreation fails:
The trigger function `trg_orders_daily_metrics()` should already exist. If it doesn't, you may need to run the migration that creates it first:
```bash
# Check if function exists
psql "your-connection-string" -c "\df trg_orders_daily_metrics"
```

