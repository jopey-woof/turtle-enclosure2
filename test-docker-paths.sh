#!/bin/bash

# Test script to verify Docker Compose environment variable substitution

echo "🐢 Testing Docker Compose Path Substitution"
echo "=========================================="

# Test different BASE_DIR values
test_paths() {
    local test_dir="$1"
    echo
    echo "Testing with BASE_DIR=$test_dir"
    echo "--------------------------------"
    
    # Create a temporary directory structure
    mkdir -p "$test_dir/config/mosquitto/data"
    mkdir -p "$test_dir/config/mosquitto/log"
    mkdir -p "$test_dir/docker"
    
    # Copy the docker-compose file
    cp docker/docker-compose.yml "$test_dir/docker/"
    
    # Set the environment variable
    export BASE_DIR="$test_dir"
    
    echo "Environment variable BASE_DIR: $BASE_DIR"
    echo "Docker Compose file location: $test_dir/docker/docker-compose.yml"
    
    # Show what paths Docker will actually use
    echo "Docker Compose paths that will be used:"
    cd "$test_dir/docker"
    grep -E "BASE_DIR|/opt/turtle-enclosure" docker-compose.yml
    
    # Test if directories exist
    echo
    echo "Checking if required directories exist:"
    for dir in config/mosquitto/data config/mosquitto/log config/influxdb config/grafana; do
        if [ -d "$test_dir/$dir" ]; then
            echo "✅ $test_dir/$dir exists"
        else
            echo "❌ $test_dir/$dir missing"
        fi
    done
    
    cd - > /dev/null
}

# Test with the expected paths
echo "Testing with /home/turtle/turtle-enclosure (expected path for read-only /opt)"
test_paths "/home/turtle/turtle-enclosure"

echo
echo "Testing with /tmp/test-turtle-enclosure (temporary test path)"
test_paths "/tmp/test-turtle-enclosure"

echo
echo "✅ Test completed!"
echo
echo "To manually test Docker startup:"
echo "cd /home/turtle/turtle-enclosure/docker"
echo "export BASE_DIR=/home/turtle/turtle-enclosure"
echo "sudo -E docker compose up -d" 