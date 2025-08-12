#!/bin/bash

# Eastern Box Turtle Enclosure - Kiosk Setup Script
# This script configures the touchscreen kiosk interface

set -e  # Exit on any error

echo "🐢 Eastern Box Turtle Enclosure - Kiosk Setup"
echo "============================================="

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

print_status "Starting kiosk setup for turtle enclosure touchscreen interface..."

# Install desktop environment and display manager
print_status "Installing desktop environment..."
sudo apt update
sudo apt install -y \
    openbox \
    lxde-core \
    lxde \
    lightdm \
    chromium-browser \
    x11vnc \
    xinput-calibrator \
    unclutter \
    xdotool \
    wmctrl

# Configure LightDM for auto-login
print_status "Configuring auto-login..."
sudo tee /etc/lightdm/lightdm.conf > /dev/null <<EOF
[SeatDefaults]
autologin-user=turtle
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-greeter
EOF

# Create Openbox configuration
print_status "Creating Openbox configuration..."
sudo mkdir -p /home/turtle/.config/openbox
sudo tee /home/turtle/.config/openbox/autostart > /dev/null <<'EOF'
#!/bin/bash

# Turtle Enclosure Kiosk Autostart
# This script runs when the desktop environment starts

# Hide mouse cursor after 3 seconds
unclutter -idle 3 -root &

# Disable screen saver and power management
xset s off
xset -dpms
xset s noblank

# Start Chromium in kiosk mode
sleep 5
chromium-browser \
    --kiosk \
    --disable-web-security \
    --disable-features=VizDisplayCompositor \
    --disable-dev-shm-usage \
    --no-first-run \
    --no-default-browser-check \
    --disable-background-timer-throttling \
    --disable-backgrounding-occluded-windows \
    --disable-renderer-backgrounding \
    --disable-features=TranslateUI \
    --disable-ipc-flooding-protection \
    --start-maximized \
    http://localhost:8123 &

# Keep script running
wait
EOF

sudo chmod +x /home/turtle/.config/openbox/autostart
sudo chown -R turtle:turtle /home/turtle/.config

# Create kiosk service
print_status "Creating kiosk service..."
sudo tee /etc/systemd/system/turtle-kiosk.service > /dev/null <<EOF
[Unit]
Description=Turtle Enclosure Kiosk Interface
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
User=turtle
Group=turtle
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/turtle/.Xauthority
ExecStart=/usr/bin/startx /usr/bin/openbox-session
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create display manager service
print_status "Creating display manager service..."
sudo tee /etc/systemd/system/turtle-display.service > /dev/null <<EOF
[Unit]
Description=Turtle Enclosure Display Manager
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/lightdm
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable turtle-display.service
sudo systemctl enable turtle-kiosk.service

# Configure touchscreen
print_status "Configuring touchscreen..."
sudo tee /opt/turtle-enclosure/scripts/configure-touchscreen.sh > /dev/null <<'EOF'
#!/bin/bash

# Touchscreen configuration script
echo "Configuring touchscreen for turtle enclosure..."

# Set display resolution for 10.1" 1024x600 screen
xrandr --output HDMI-1 --mode 1024x600 --rate 60

# Configure touch input
if xinput list | grep -i touch > /dev/null; then
    echo "Touchscreen detected, configuring..."
    TOUCH_DEVICE=$(xinput list | grep -i touch | head -1 | sed 's/.*id=\([0-9]*\).*/\1/')
    
    # Map touchscreen to display
    xinput map-to-output $TOUCH_DEVICE HDMI-1
    
    # Configure touch sensitivity
    xinput set-prop $TOUCH_DEVICE "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
    
    echo "Touchscreen configured successfully"
else
    echo "No touchscreen detected"
fi
EOF

sudo chmod +x /opt/turtle-enclosure/scripts/configure-touchscreen.sh
sudo chown turtle:turtle /opt/turtle-enclosure/scripts/configure-touchscreen.sh

# Create kiosk recovery script
print_status "Creating kiosk recovery script..."
sudo tee /opt/turtle-enclosure/scripts/kiosk-recovery.sh > /dev/null <<'EOF'
#!/bin/bash

# Kiosk recovery script
LOG_FILE="/opt/turtle-enclosure/logs/kiosk.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check if Chromium is running
check_chromium() {
    if ! pgrep -f "chromium.*kiosk" > /dev/null; then
        log_message "Chromium kiosk not running, restarting..."
        pkill -f chromium
        sleep 2
        export DISPLAY=:0
        chromium-browser \
            --kiosk \
            --disable-web-security \
            --disable-features=VizDisplayCompositor \
            --disable-dev-shm-usage \
            --no-first-run \
            --no-default-browser-check \
            --disable-background-timer-throttling \
            --disable-backgrounding-occluded-windows \
            --disable-renderer-backgrounding \
            --disable-features=TranslateUI \
            --disable-ipc-flooding-protection \
            --start-maximized \
            http://localhost:8123 &
        log_message "Chromium kiosk restarted"
    fi
}

# Check if Home Assistant is accessible
check_homeassistant() {
    if ! curl -s http://localhost:8123 > /dev/null; then
        log_message "Home Assistant not accessible"
        return 1
    fi
    return 0
}

# Main function
main() {
    mkdir -p /opt/turtle-enclosure/logs
    
    if check_homeassistant; then
        check_chromium
    else
        log_message "Home Assistant not available, skipping kiosk check"
    fi
}

main "$@"
EOF

sudo chmod +x /opt/turtle-enclosure/scripts/kiosk-recovery.sh
sudo chown turtle:turtle /opt/turtle-enclosure/scripts/kiosk-recovery.sh

# Add kiosk recovery to crontab (every 2 minutes)
(crontab -u turtle -l 2>/dev/null; echo "*/2 * * * * /opt/turtle-enclosure/scripts/kiosk-recovery.sh") | crontab -u turtle -

# Create VNC configuration for remote access
print_status "Configuring VNC for remote access..."
sudo mkdir -p /home/turtle/.vnc
echo "turtle123" | sudo tee /home/turtle/.vnc/passwd > /dev/null
sudo chown -R turtle:turtle /home/turtle/.vnc
sudo chmod 600 /home/turtle/.vnc/passwd

# Create VNC service
sudo tee /etc/systemd/system/turtle-vnc.service > /dev/null <<EOF
[Unit]
Description=Turtle Enclosure VNC Server
After=graphical-session.target

[Service]
Type=simple
User=turtle
Group=turtle
Environment=DISPLAY=:0
ExecStart=/usr/bin/x11vnc -display :0 -forever -shared -rfbauth /home/turtle/.vnc/passwd -rfbport 5900
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable turtle-vnc.service

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

# Create kiosk test script
print_status "Creating kiosk test script..."
sudo tee /opt/turtle-enclosure/scripts/test-kiosk.sh > /dev/null <<'EOF'
#!/bin/bash

# Kiosk test script
echo "🐢 Testing Turtle Enclosure Kiosk"
echo "=================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Test display manager
echo
echo "Testing display manager..."
if systemctl is-active --quiet lightdm; then
    print_success "LightDM is running"
else
    print_error "LightDM is not running"
fi

# Test X server
echo
echo "Testing X server..."
if [ -n "$DISPLAY" ] && xset q > /dev/null 2>&1; then
    print_success "X server is running"
    echo "Display: $DISPLAY"
else
    print_error "X server is not running"
fi

# Test touchscreen
echo
echo "Testing touchscreen..."
if xinput list | grep -i touch > /dev/null; then
    print_success "Touchscreen detected"
    xinput list | grep -i touch
else
    print_warning "Touchscreen not detected"
fi

# Test Chromium
echo
echo "Testing Chromium..."
if pgrep -f "chromium.*kiosk" > /dev/null; then
    print_success "Chromium kiosk is running"
else
    print_error "Chromium kiosk is not running"
fi

# Test Home Assistant accessibility
echo
echo "Testing Home Assistant..."
if curl -s http://localhost:8123 > /dev/null; then
    print_success "Home Assistant is accessible"
else
    print_error "Home Assistant is not accessible"
fi

# Test VNC
echo
echo "Testing VNC..."
if systemctl is-active --quiet turtle-vnc.service; then
    print_success "VNC server is running"
    echo "VNC available at: localhost:5900 (password: turtle123)"
else
    print_error "VNC server is not running"
fi

echo
echo "Kiosk test completed!"
EOF

sudo chmod +x /opt/turtle-enclosure/scripts/test-kiosk.sh
sudo chown turtle:turtle /opt/turtle-enclosure/scripts/test-kiosk.sh

print_success "Kiosk setup completed successfully!"
echo
print_status "Next steps:"
echo "============="
echo "1. Reboot the system: sudo reboot"
echo "2. Test kiosk: ./scripts/test-kiosk.sh"
echo "3. Configure touchscreen: ./scripts/configure-touchscreen.sh"
echo "4. Access VNC: localhost:5900 (password: turtle123)"
echo "5. The kiosk will automatically start on boot"
echo
print_warning "Important Notes:"
echo "=================="
echo "- The system will auto-login as turtle user"
echo "- Chromium will start in kiosk mode automatically"
echo "- Touchscreen calibration may be needed"
echo "- VNC is available for remote access"
echo "- Kiosk recovery runs every 2 minutes"
echo
print_success "Kiosk configuration is ready! 🐢" 