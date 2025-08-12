#!/bin/bash

# Start Home Assistant and related services for turtle enclosure
echo "🐢 Starting Turtle Enclosure Home Assistant..."

# Get the base directory from the setup script
if [ -f "/tmp/turtle-enclosure-base-dir" ]; then
    BASE_DIR=$(cat /tmp/turtle-enclosure-base-dir)
else
    # Fallback to default location
    BASE_DIR="/opt/turtle-enclosure"
fi

# Check if we're in the right directory
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Turtle enclosure system not found at $BASE_DIR"
    echo "Please run the setup scripts first: ./scripts/setup-turtle-enclosure.sh"
    exit 1
fi

# Navigate to the docker directory
cd "$BASE_DIR/docker"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found"
    echo "Please run the setup scripts first: ./scripts/setup-turtle-enclosure.sh"
    exit 1
fi

# Start all services
echo "Starting Docker containers..."
docker-compose up -d

# Wait for Home Assistant to be ready
echo "Waiting for Home Assistant to start..."
sleep 30

# Check if Home Assistant is responding
echo "Checking if Home Assistant is ready..."
for i in {1..30}; do
    if curl -s http://localhost:8123 > /dev/null; then
        echo "✅ Home Assistant is ready!"
        echo "🌐 Access Home Assistant at: http://localhost:8123"
        break
    fi
    echo "⏳ Waiting for Home Assistant... ($i/30)"
    sleep 10
done

# Check if all containers are running
echo
echo "Checking container status..."
docker-compose ps

echo
echo "🐢 Turtle Enclosure system is ready!"
echo "📱 Access Home Assistant at: http://localhost:8123"
echo "📊 Access Grafana at: http://localhost:3000 (admin/turtle123)"
echo "🔧 Access Node-RED at: http://localhost:1880" 