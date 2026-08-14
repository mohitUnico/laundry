#!/bin/bash

# Script to compare local backend code with Docker container code
# Usage: ./scripts/compare-docker-code.sh

set -e

echo "=========================================="
echo "Backend Code Comparison: Local vs Docker"
echo "=========================================="
echo ""

# Check if container is running
if ! docker ps | grep -q "laundry-backend"; then
    echo "⚠️  Container is not running. Starting it temporarily..."
    docker-compose up -d backend
    sleep 3
    TEMP_START=true
else
    TEMP_START=false
fi

CONTAINER_NAME="laundry-backend"
LOCAL_DIR="./backend"
DOCKER_DIR="/app"

echo "📁 File Count Comparison:"
echo "---"
LOCAL_JS_COUNT=$(find "$LOCAL_DIR/src" -name "*.js" -type f 2>/dev/null | wc -l | tr -d ' ')
DOCKER_JS_COUNT=$(docker exec "$CONTAINER_NAME" find "$DOCKER_DIR/src" -name "*.js" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "Local JS files: $LOCAL_JS_COUNT"
echo "Docker JS files: $DOCKER_JS_COUNT"

if [ "$LOCAL_JS_COUNT" -eq "$DOCKER_JS_COUNT" ]; then
    echo "✅ File counts match"
else
    echo "⚠️  File counts differ"
fi

echo ""
echo "📄 Key Files Comparison:"
echo "---"

# List of key files to compare
KEY_FILES=(
    "src/server.js"
    "src/app.js"
    "src/config/database.js"
    "src/services/email.service.js"
    "src/services/otp.service.js"
    "src/controllers/auth.controller.js"
    "package.json"
    "prisma/schema.prisma"
)

for file in "${KEY_FILES[@]}"; do
    local_file="$LOCAL_DIR/$file"
    docker_file="$DOCKER_DIR/$file"
    
    if [ ! -f "$local_file" ]; then
        echo "❌ $file: Not found locally"
        continue
    fi
    
    if ! docker exec "$CONTAINER_NAME" test -f "$docker_file" 2>/dev/null; then
        echo "❌ $file: Not found in Docker"
        continue
    fi
    
    # Calculate checksums
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local_hash=$(md5 -q "$local_file" 2>/dev/null)
        docker_hash=$(docker exec "$CONTAINER_NAME" md5sum "$docker_file" 2>/dev/null | cut -d' ' -f1)
    else
        # Linux
        local_hash=$(md5sum "$local_file" 2>/dev/null | cut -d' ' -f1)
        docker_hash=$(docker exec "$CONTAINER_NAME" md5sum "$docker_file" 2>/dev/null | cut -d' ' -f1)
    fi
    
    if [ "$local_hash" = "$docker_hash" ]; then
        echo "✅ $file: Match (MD5: ${local_hash:0:8}...)"
    else
        echo "⚠️  $file: Different"
        echo "   Local:  ${local_hash:0:16}"
        echo "   Docker: ${docker_hash:0:16}"
    fi
done

echo ""
echo "📅 Timestamp Comparison:"
echo "---"
echo "Local file (server.js) last modified:"
stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LOCAL_DIR/src/server.js" 2>/dev/null || stat -c "%y" "$LOCAL_DIR/src/server.js" 2>/dev/null | cut -d' ' -f1-2

echo "Docker image created:"
docker inspect "$CONTAINER_NAME" --format='{{.Created}}' 2>/dev/null | cut -d'T' -f1-2 | tr 'T' ' ' | cut -d'.' -f1

echo ""
echo "📦 Package.json Comparison:"
echo "---"
echo "Local version:"
grep '"version"' "$LOCAL_DIR/package.json" | head -1

echo "Docker version:"
docker exec "$CONTAINER_NAME" grep '"version"' "$DOCKER_DIR/package.json" 2>/dev/null | head -1

echo ""
echo "🔍 Quick Diff Check (first 50 lines of server.js):"
echo "---"
echo "Local:"
head -5 "$LOCAL_DIR/src/server.js"
echo ""
echo "Docker:"
docker exec "$CONTAINER_NAME" head -5 "$DOCKER_DIR/src/server.js" 2>/dev/null

echo ""
echo "=========================================="

# Stop container if we started it temporarily
if [ "$TEMP_START" = true ]; then
    echo "Stopping temporarily started container..."
    docker-compose stop backend
fi

echo "✅ Comparison complete!"
echo ""
echo "💡 Tip: If files differ, rebuild the Docker image with:"
echo "   docker-compose build backend"

