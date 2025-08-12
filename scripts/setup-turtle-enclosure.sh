#!/bin/bash

# Eastern Box Turtle Enclosure - Master Setup Script
# This script orchestrates the complete installation of the turtle enclosure system

set -e  # Exit on any error

echo "🐢 Eastern Box Turtle Enclosure - Master Setup"
echo "=============================================="
echo "This script will install and configure the complete turtle enclosure"
echo "automation system. This process may take 30-60 minutes."
echo

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

# Check Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
if [[ "$UBUNTU_VERSION" != "22.04" ]]; then
    print_warning "This script is designed for Ubuntu 22.04. You're running $UBUNTU_VERSION"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check available disk space
DISK_SPACE=$(df / | awk 'NR==2 {print $4}')
DISK_SPACE_GB=$((DISK_SPACE / 1024 / 1024))
if [ "$DISK_SPACE_GB" -lt 10 ]; then
    print_error "Insufficient disk space. Need at least 10GB, have ${DISK_SPACE_GB}GB"
    exit 1
fi

print_status "Available disk space: ${DISK_SPACE_GB}GB"

# Check internet connectivity
print_status "Checking internet connectivity..."
if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    print_error "No internet connectivity detected"
    exit 1
fi

print_success "Internet connectivity confirmed"

# Confirm installation
echo
print_warning "This installation will:"
echo "  - Install Ubuntu Server packages and minimal desktop"
echo "  - Install Docker and Docker Compose"
echo "  - Configure Home Assistant with turtle-themed automation"
echo "  - Set up kiosk mode for touchscreen interface"
echo "  - Configure USB devices and Zigbee network"
echo "  - Create systemd services for auto-start"
echo
read -p "Do you want to continue with the installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installation cancelled"
    exit 0
fi

# Create installation log
LOG_FILE="/tmp/turtle-enclosure-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

print_status "Installation log: $LOG_FILE"

# Step 1: System Setup
echo
print_status "Step 1/5: System Setup"
echo "============================"
if [ -f "scripts/01-system-setup.sh" ]; then
    ./scripts/01-system-setup.sh
    if [ $? -eq 0 ]; then
        print_success "System setup completed"
    else
        print_error "System setup failed"
        exit 1
    fi
else
    print_error "System setup script not found"
    exit 1
fi

# Step 2: Docker Setup
echo
print_status "Step 2/5: Docker Setup"
echo "==========================="
if [ -f "scripts/02-docker-setup.sh" ]; then
    ./scripts/02-docker-setup.sh
    if [ $? -eq 0 ]; then
        print_success "Docker setup completed"
    else
        print_error "Docker setup failed"
        exit 1
    fi
else
    print_error "Docker setup script not found"
    exit 1
fi

# Step 3: Home Assistant Setup
echo
print_status "Step 3/5: Home Assistant Setup"
echo "===================================="
if [ -f "scripts/03-home-assistant-setup.sh" ]; then
    ./scripts/03-home-assistant-setup.sh
    if [ $? -eq 0 ]; then
        print_success "Home Assistant setup completed"
    else
        print_error "Home Assistant setup failed"
        exit 1
    fi
else
    print_error "Home Assistant setup script not found"
    exit 1
fi

# Step 4: Copy configuration files
echo
print_status "Step 4/5: Copying Configuration Files"
echo "==========================================="

# Ensure all required directories exist
print_status "Creating required directories..."

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
    print_error "Docker Compose file not found"
    exit 1
fi

# Copy scripts
sudo cp -r scripts/* /opt/turtle-enclosure/scripts/
sudo chown -R turtle:turtle /opt/turtle-enclosure/scripts/
sudo chmod +x /opt/turtle-enclosure/scripts/*.sh
print_success "Scripts copied"

# Step 5: Final Configuration
echo
print_status "Step 5/5: Final Configuration"
echo "==================================="

# Create system information file
print_status "Creating system information..."
BASE_DIR=$(cat /tmp/turtle-enclosure-base-dir)
sudo tee "$BASE_DIR/system-info.txt" > /dev/null <<EOF
Turtle Enclosure System Information
==================================
Installation Date: $(date)
Ubuntu Version: $(lsb_release -d | cut -f2)
Docker Version: $(docker --version)
Home Assistant: Configured
Kiosk Mode: Enabled
Auto-start: Enabled

Access Information:
- Home Assistant: http://localhost:8123
- Grafana: http://localhost:3000 (admin/turtle123)
- Node-RED: http://localhost:1880
- InfluxDB: http://localhost:8086 (admin/turtle123)

Hardware Requirements:
- TEMPerHUM USB sensor: Connected
- Arducam USB camera: Connected
- Sonoff Zigbee dongle: Connected
- Touchscreen: 1024x600

Next Steps:
1. Connect your hardware devices
2. Access Home Assistant at http://localhost:8123
3. Complete the initial setup
4. Configure your turtle enclosure settings
5. Test the touchscreen interface

Support:
- Logs: /opt/turtle-enclosure/logs/
- Config: /opt/turtle-enclosure/config/
- Backups: /opt/turtle-enclosure/backups/
EOF

sudo chown turtle:turtle "$BASE_DIR/system-info.txt"

# Create quick start guide
print_status "Creating quick start guide..."
sudo tee "$BASE_DIR/QUICK_START.md" > /dev/null <<'EOF'
# Turtle Enclosure Quick Start Guide

## 🚀 Getting Started

1. **Connect Hardware**:
   - Plug in TEMPerHUM USB sensor
   - Connect Arducam USB camera
   - Insert Sonoff Zigbee dongle
   - Connect touchscreen monitor

2. **Start the System**:
   ```bash
   sudo systemctl start turtle-docker.service
   sudo systemctl start turtle-kiosk.service
   ```

3. **Access Home Assistant**:
   - Open browser: http://localhost:8123
   - Complete initial setup
   - Create your admin account

4. **Configure Your Turtle**:
   - Set temperature range: 70-85°F
   - Set humidity range: 60-80%
   - Configure lighting schedule
   - Set up mobile notifications

## 🎛️ Touchscreen Interface

The touchscreen will automatically display the turtle enclosure dashboard.
- Large, easy-to-read displays
- Touch-optimized controls
- Real-time camera feed
- Environmental monitoring

## 📱 Mobile App

1. Install "Home Assistant" app on your phone
2. Add your server: http://YOUR_IP:8123
3. Configure notifications
4. Monitor your turtle remotely

## 🔧 Troubleshooting

- **System won't start**: Check logs at `/opt/turtle-enclosure/logs/`
- **Hardware not detected**: Run `lsusb` and `ls /dev/video*`
- **Touchscreen not working**: Calibrate with `xinput_calibrator`
- **Docker issues**: Run `docker-compose logs` in `/opt/turtle-enclosure/docker/`

## 📞 Support

- Check system info: `cat /opt/turtle-enclosure/system-info.txt`
- View logs: `tail -f /opt/turtle-enclosure/logs/*.log`
- Restart services: `sudo systemctl restart turtle-*`

## 🐢 Turtle Care Tips

- Monitor temperature daily
- Check humidity levels
- Provide fresh water
- Feed appropriate diet
- Maintain UVB lighting schedule
- Clean enclosure regularly

Happy turtle parenting! 🐢💚
EOF

sudo chown turtle:turtle "$BASE_DIR/QUICK_START.md"

# Set final permissions
print_status "Setting final permissions..."
sudo chown -R turtle:turtle "$BASE_DIR"
sudo chmod -R 755 "$BASE_DIR"

# Create desktop shortcut
print_status "Creating desktop shortcuts..."
sudo mkdir -p /home/turtle/Desktop
sudo tee /home/turtle/Desktop/Turtle\ Enclosure.desktop > /dev/null <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Turtle Enclosure
Comment=Access turtle enclosure dashboard
Exec=chromium-browser --kiosk http://localhost:8123
Icon=turtle
Terminal=false
Categories=Utility;
EOF

sudo chown turtle:turtle /home/turtle/Desktop/Turtle\ Enclosure.desktop
sudo chmod +x /home/turtle/Desktop/Turtle\ Enclosure.desktop

# Installation complete
echo
print_success "🎉 Turtle Enclosure Installation Complete!"
echo
print_status "System Information:"
echo "======================"
echo "Installation Date: $(date)"
echo "System Location: $BASE_DIR"
echo "Home Assistant: http://localhost:8123"
echo "Grafana: http://localhost:3000"
echo "Node-RED: http://localhost:1880"
echo
print_status "Next Steps:"
echo "============="
echo "1. Reboot the system: sudo reboot"
echo "2. Connect your hardware devices"
echo "3. Access Home Assistant at http://localhost:8123"
echo "4. Complete the initial setup"
echo "5. Configure your turtle enclosure settings"
echo
print_status "Documentation:"
echo "================"
echo "Quick Start: $BASE_DIR/QUICK_START.md"
echo "System Info: $BASE_DIR/system-info.txt"
echo "Installation Log: $LOG_FILE"
echo
print_warning "Important Notes:"
echo "=================="
echo "- Update secrets.yaml with your API keys"
echo "- Configure your location in configuration.yaml"
echo "- Test all hardware connections"
echo "- Set up mobile app notifications"
echo
print_success "Your turtle enclosure automation system is ready! 🐢" 