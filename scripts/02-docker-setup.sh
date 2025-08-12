#!/bin/bash

# Eastern Box Turtle Enclosure - Docker Setup Script
# This script installs and configures Docker and Docker Compose

set -e  # Exit on any error

echo "🐢 Eastern Box Turtle Enclosure - Docker Setup"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_status "Starting Docker setup for turtle enclosure automation..."

# Remove old Docker versions if they exist
print_status "Removing old Docker installations..."
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Update package index
print_status "Updating package index..."
sudo apt update

# Install prerequisites
print_status "Installing Docker prerequisites..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
print_status "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
print_status "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
print_status "Updating package index with Docker repository..."
sudo apt update

# Install Docker Engine
print_status "Installing Docker Engine..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add current user to docker group
print_status "Adding user to docker group..."
sudo usermod -aG docker $USER

# Add turtle user to docker group
print_status "Adding turtle user to docker group..."
sudo usermod -aG docker turtle

# Start and enable Docker service
print_status "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose (standalone version for compatibility)
print_status "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create symbolic link
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify Docker installation
print_status "Verifying Docker installation..."
if docker --version; then
    print_success "Docker installed successfully"
else
    print_error "Docker installation failed"
    exit 1
fi

# Verify Docker Compose installation
print_status "Verifying Docker Compose installation..."
if docker-compose --version; then
    print_success "Docker Compose installed successfully"
else
    print_error "Docker Compose installation failed"
    exit 1
fi

# Configure Docker daemon
print_status "Configuring Docker daemon..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Name": "nofile",
      "Soft": 64000
    }
  }
}
EOF

# Restart Docker to apply configuration
print_status "Restarting Docker service..."
sudo systemctl restart docker

# Create Docker network for turtle enclosure
print_status "Creating Docker network..."
docker network create turtle-network 2>/dev/null || print_warning "Network already exists"

# Configure Docker to start containers on boot
print_status "Configuring Docker restart policy..."
sudo systemctl enable docker

# Create Docker configuration directory and all required subdirectories
print_status "Creating Docker configuration directory and required subdirectories..."

# Check if /opt is writable, if not use home directory
if sudo test -w /opt; then
    BASE_DIR="/opt/turtle-enclosure"
    print_status "Using /opt/turtle-enclosure for installation"
else
    BASE_DIR="/home/turtle/turtle-enclosure"
    print_status "Using /home/turtle/turtle-enclosure for installation (read-only filesystem detected)"
fi

# Create all required directories
sudo mkdir -p "$BASE_DIR/docker"
sudo mkdir -p "$BASE_DIR/config/homeassistant"
sudo mkdir -p "$BASE_DIR/config/mosquitto/data"
sudo mkdir -p "$BASE_DIR/config/mosquitto/log"
sudo mkdir -p "$BASE_DIR/config/zigbee2mqtt"
sudo mkdir -p "$BASE_DIR/config/influxdb"
sudo mkdir -p "$BASE_DIR/config/grafana"
sudo mkdir -p "$BASE_DIR/config/nodered"
sudo mkdir -p "$BASE_DIR/config/motion"
sudo mkdir -p "$BASE_DIR/logs"
sudo chown -R turtle:turtle "$BASE_DIR"
sudo chmod -R 755 "$BASE_DIR"

# Store the base directory for later use
echo "$BASE_DIR" > /tmp/turtle-enclosure-base-dir

# Copy Docker Compose file
print_status "Setting up Docker Compose configuration..."
if [ -f "docker/docker-compose.yml" ]; then
    # Read the base directory
    BASE_DIR=$(cat /tmp/turtle-enclosure-base-dir)
    
    # Copy and update the docker-compose file with the correct paths
    sudo cp docker/docker-compose.yml "$BASE_DIR/docker/"
    sudo chown turtle:turtle "$BASE_DIR/docker/docker-compose.yml"
    
    # Update paths in docker-compose file if using home directory
    if [ "$BASE_DIR" != "/opt/turtle-enclosure" ]; then
        sudo sed -i "s|/opt/turtle-enclosure|$BASE_DIR|g" "$BASE_DIR/docker/docker-compose.yml"
        print_status "Updated docker-compose.yml paths to use $BASE_DIR"
    fi
    
    print_success "Docker Compose file copied to $BASE_DIR/docker/"
else
    print_warning "Docker Compose file not found, will be created in next step"
fi

# Create Docker service for auto-start
print_status "Creating Docker auto-start service..."
BASE_DIR=$(cat /tmp/turtle-enclosure-base-dir)
sudo tee /etc/systemd/system/turtle-docker.service > /dev/null <<EOF
[Unit]
Description=Turtle Enclosure Docker Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$BASE_DIR/docker
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=turtle
Group=turtle

[Install]
WantedBy=multi-user.target
EOF

# Enable Docker service
sudo systemctl daemon-reload
sudo systemctl enable turtle-docker.service

# Create Docker maintenance script
print_status "Creating Docker maintenance script..."
sudo tee /opt/turtle-enclosure/scripts/docker-maintenance.sh > /dev/null <<'EOF'
#!/bin/bash

# Docker maintenance for turtle enclosure
LOG_FILE="/opt/turtle-enclosure/logs/docker.log"
mkdir -p /opt/turtle-enclosure/logs

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

cd /opt/turtle-enclosure/docker

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    log_message "WARNING: Some containers are not running, attempting restart"
    docker-compose restart
fi

# Clean up unused images (older than 30 days)
log_message "Cleaning up unused Docker images"
docker image prune -f --filter "until=720h"

# Clean up unused volumes
log_message "Cleaning up unused Docker volumes"
docker volume prune -f

# Clean up unused networks
log_message "Cleaning up unused Docker networks"
docker network prune -f

# Check disk usage
DISK_USAGE=$(df /var/lib/docker | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    log_message "WARNING: Docker disk usage is ${DISK_USAGE}%"
fi
EOF

sudo chmod +x /opt/turtle-enclosure/scripts/docker-maintenance.sh
sudo chown turtle:turtle /opt/turtle-enclosure/scripts/docker-maintenance.sh

# Add Docker maintenance to crontab (weekly)
sudo -u turtle bash -c '(crontab -l 2>/dev/null; echo "0 3 * * 0 /opt/turtle-enclosure/scripts/docker-maintenance.sh") | crontab -'

# Create Docker health check script
print_status "Creating Docker health check script..."
sudo tee /opt/turtle-enclosure/scripts/docker-health.sh > /dev/null <<'EOF'
#!/bin/bash

# Docker health check for turtle enclosure
LOG_FILE="/opt/turtle-enclosure/logs/docker-health.log"
mkdir -p /opt/turtle-enclosure/logs

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

cd /opt/turtle-enclosure/docker

# Check each container
for container in homeassistant zigbee2mqtt mosquitto influxdb grafana nodered; do
    if ! docker ps --format "{{.Names}}" | grep -q "turtle-$container"; then
        log_message "ERROR: Container turtle-$container is not running"
        # Attempt restart
        docker-compose restart $container
        log_message "Attempted restart of turtle-$container"
    else
        # Check if container is healthy
        if docker ps --format "{{.Names}}\t{{.Status}}" | grep "turtle-$container" | grep -q "unhealthy"; then
            log_message "WARNING: Container turtle-$container is unhealthy"
        fi
    fi
done

# Check Docker daemon
if ! systemctl is-active --quiet docker; then
    log_message "ERROR: Docker daemon is not running"
    systemctl restart docker
    log_message "Attempted restart of Docker daemon"
fi
EOF

sudo chmod +x /opt/turtle-enclosure/scripts/docker-health.sh
sudo chown turtle:turtle /opt/turtle-enclosure/scripts/docker-health.sh

# Add Docker health check to crontab (every 5 minutes)
sudo -u turtle bash -c '(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/turtle-enclosure/scripts/docker-health.sh") | crontab -'

# Test Docker installation
print_status "Testing Docker installation..."
if docker run --rm hello-world 2>/dev/null; then
    print_success "Docker test successful"
else
    print_warning "Docker test failed - this is normal if you haven't logged out/in yet"
    print_status "The user has been added to the docker group, but you may need to:"
    print_status "1. Log out and log back in, OR"
    print_status "2. Run: newgrp docker"
    print_status "3. Then test again with: docker run --rm hello-world"
fi

# Clean up test image (if it exists)
docker rmi hello-world:latest 2>/dev/null || true

print_success "Docker setup completed successfully!"
echo
print_status "Next steps:"
echo "1. Run the Home Assistant setup script: ./scripts/03-home-assistant-setup.sh"
echo "2. Configure hardware integration: ./scripts/05-hardware-setup.sh"
echo
print_warning "Important Docker Group Note:"
echo "=================================="
echo "You have been added to the docker group, but you may need to:"
echo "1. Log out and log back in, OR"
echo "2. Run: newgrp docker"
echo "3. Then test Docker with: docker run --rm hello-world"
echo
print_status "If Docker commands fail with permission errors, try the above steps." 