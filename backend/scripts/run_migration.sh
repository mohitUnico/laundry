#!/bin/bash

# Script to run payment_pending removal migration on EC2
# Usage: ./scripts/run_migration.sh

set -e  # Exit on error

echo "🚀 Starting migration to remove payment_pending from OrderStatus enum..."

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ Error: DATABASE_URL environment variable is not set"
    echo "Please set it or source your .env file:"
    echo "  source .env"
    echo "  export DATABASE_URL"
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MIGRATION_FILE="$SCRIPT_DIR/remove_payment_pending.sql"

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Error: Migration file not found at $MIGRATION_FILE"
    exit 1
fi

echo "📄 Running migration from: $MIGRATION_FILE"
echo "🔌 Connecting to database..."

# Run the migration
psql "$DATABASE_URL" -f "$MIGRATION_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
    echo ""
    echo "📊 Verifying migration..."
    
    # Verify the migration
    psql "$DATABASE_URL" -c "SELECT unnest(enum_range(NULL::\"OrderStatus\")) AS order_status;" | grep -v "payment_pending" || echo "✅ payment_pending successfully removed from enum"
    
    # Check for any remaining orders with payment_pending (should be 0)
    COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM orders WHERE order_status = 'payment_pending';" | xargs)
    if [ "$COUNT" -eq 0 ]; then
        echo "✅ No orders with payment_pending status found"
    else
        echo "⚠️  Warning: Found $COUNT orders with payment_pending status"
    fi
    
    echo ""
    echo "🎉 Migration verification complete!"
else
    echo "❌ Migration failed. Please check the error messages above."
    exit 1
fi

