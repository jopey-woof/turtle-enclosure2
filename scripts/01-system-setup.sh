#!/bin/bash

# Eastern Box Turtle Enclosure - System Setup Script
# This script performs basic system setup for the turtle enclosure automation

set -e  # Exit on any error

echo "🐢 Eastern Box Turtle Enclosure - System Setup"
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

print_status "Starting system setup for turtle enclosure automation..."

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

# Update system packages
print_status "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install essential packages
print_status "Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    unzip \
    dos2unix \
    python3 \
    python3-pip \
    python3-venv \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    logrotate \
    rsyslog

# Create turtle user if it doesn't exist
print_status "Setting up turtle user..."
if ! id "turtle" &>/dev/null; then
    sudo useradd -m -s /bin/bash turtle
    sudo usermod -aG sudo turtle
    print_success "Turtle user created"
else
    print_status "Turtle user already exists"
fi

# Set up turtle user password (optional)
print_warning "Setting up turtle user password..."
echo "turtle:turtle123" | sudo chpasswd

# Create turtle enclosure directory structure
print_status "Creating directory structure..."
sudo mkdir -p /opt/turtle-enclosure/{config,docker,scripts,logs,backups}
sudo mkdir -p /opt/turtle-enclosure/config/{homeassistant,zigbee2mqtt}
sudo chown -R turtle:turtle /opt/turtle-enclosure

# Configure firewall
print_status "Configuring firewall..."
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 8123/tcp  # Home Assistant
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 1880/tcp  # Node-RED
sudo ufw allow 8086/tcp  # InfluxDB
sudo ufw allow 1883/tcp  # MQTT
sudo ufw allow 5900/tcp  # VNC
sudo ufw allow 8081/tcp  # Camera stream

# Configure system limits
print_status "Configuring system limits..."
sudo tee /etc/security/limits.d/turtle-enclosure.conf > /dev/null <<EOF
# Turtle Enclosure System Limits
turtle soft nofile 65536
turtle hard nofile 65536
turtle soft nproc 32768
turtle hard nproc 32768
EOF

# Configure log rotation
print_status "Configuring log rotation..."
sudo tee /etc/logrotate.d/turtle-enclosure > /dev/null <<EOF
/opt/turtle-enclosure/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 turtle turtle
}
EOF

# Configure rsyslog for turtle enclosure
print_status "Configuring logging..."
sudo tee /etc/rsyslog.d/turtle-enclosure.conf > /dev/null <<EOF
# Turtle Enclosure Logging
local0.* /opt/turtle-enclosure/logs/system.log
EOF

sudo systemctl restart rsyslog

# Create systemd service directory
print_status "Creating systemd service directory..."
sudo mkdir -p /etc/systemd/system

# Configure systemd journal settings
print_status "Configuring systemd journal settings..."
sudo tee /etc/systemd/journald.conf.d/turtle-enclosure.conf > /dev/null <<EOF
# Turtle Enclosure Journal Settings
[Journal]
SystemMaxUse=100M
SystemKeepFree=200M
SystemMaxFileSize=10M
EOF

sudo systemctl restart systemd-journald

# Set up automatic security updates
print_status "Setting up automatic security updates..."
sudo apt install -y unattended-upgrades
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Configure fail2ban
print_status "Configuring fail2ban..."
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Set up monitoring script
print_status "Setting up system monitoring..."
sudo tee /opt/turtle-enclosure/scripts/monitor-system.sh > /dev/null <<'EOF'
#!/bin/bash

# System monitoring script for turtle enclosure
LOG_FILE="/opt/turtle-enclosure/logs/system.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    log_message "WARNING: Disk usage is ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ "$MEMORY_USAGE" -gt 80 ]; then
    log_message "WARNING: Memory usage is ${MEMORY_USAGE}%"
fi

# Check CPU load
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
CPU_LOAD_NUM=$(echo $CPU_LOAD | awk -F'.' '{print $1}')
if [ "$CPU_LOAD_NUM" -gt 5 ]; then
    log_message "WARNING: High CPU load: $CPU_LOAD"
fi

# Check system uptime
UPTIME_DAYS=$(uptime | awk '{print $3}' | sed 's/,//')
if [ "$UPTIME_DAYS" -gt 30 ]; then
    log_message "INFO: System has been up for $UPTIME_DAYS days"
fi
EOF

sudo chmod +x /opt/turtle-enclosure/scripts/monitor-system.sh
sudo chown turtle:turtle /opt/turtle-enclosure/scripts/monitor-system.sh

# Add system monitoring to crontab (every 5 minutes)
(crontab -u turtle -l 2>/dev/null; echo "*/5 * * * * /opt/turtle-enclosure/scripts/monitor-system.sh") | crontab -u turtle -

# Create backup script
print_status "Setting up backup system..."
sudo tee /opt/turtle-enclosure/scripts/backup-config.sh > /dev/null <<'EOF'
#!/bin/bash

# Backup script for turtle enclosure configuration
BACKUP_DIR="/opt/turtle-enclosure/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="turtle-enclosure-backup-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    /opt/turtle-enclosure/config \
    /opt/turtle-enclosure/scripts \
    /opt/turtle-enclosure/logs

# Keep only last 7 backups
find "$BACKUP_DIR" -name "turtle-enclosure-backup-*.tar.gz" -mtime +7 -delete

echo "Backup created: $BACKUP_FILE"
EOF

sudo chmod +x /opt/turtle-enclosure/scripts/backup-config.sh
sudo chown turtle:turtle /opt/turtle-enclosure/scripts/backup-config.sh

# Add daily backup to crontab
(crontab -u turtle -l 2>/dev/null; echo "0 2 * * * /opt/turtle-enclosure/scripts/backup-config.sh") | crontab -u turtle -

# Set final permissions
print_status "Setting final permissions..."
sudo chown -R turtle:turtle /opt/turtle-enclosure
sudo chmod -R 755 /opt/turtle-enclosure

print_success "System setup completed successfully!"
echo
print_status "System Configuration Summary:"
echo "==================================="
echo "✓ Ubuntu Server packages updated"
echo "✓ Turtle user created (password: turtle123)"
echo "✓ Directory structure created at /opt/turtle-enclosure"
echo "✓ Firewall configured (SSH, HA, Grafana, Node-RED, VNC, etc.)"
echo "✓ System limits configured"
echo "✓ Log rotation configured"
echo "✓ Automatic security updates enabled"
echo "✓ Fail2ban configured"
echo "✓ System monitoring enabled (every 5 minutes)"
echo "✓ Daily backups configured (2 AM)"
echo
print_status "Next steps:"
echo "============="
echo "1. Run Docker setup: ./scripts/02-docker-setup.sh"
echo "2. Run Home Assistant setup: ./scripts/03-home-assistant-setup.sh"
echo "3. Run Kiosk setup: ./scripts/04-kiosk-setup.sh"
echo "4. Run Hardware setup: ./scripts/05-hardware-setup.sh"
echo
print_warning "Important Notes:"
echo "=================="
echo "- Turtle user password is set to: turtle123"
echo "- SSH access is allowed through firewall"
echo "- System monitoring runs every 5 minutes"
echo "- Daily backups are created at 2 AM"
echo "- Automatic security updates are enabled"
echo
print_success "System configuration is ready! 🐢" 