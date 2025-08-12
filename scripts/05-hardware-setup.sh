#!/bin/bash

# Eastern Box Turtle Enclosure - Hardware Setup Script
# This script configures USB devices, touchscreen, and Zigbee network

set -e  # Exit on any error

echo "🐢 Eastern Box Turtle Enclosure - Hardware Setup"
echo "================================================"

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

print_status "Starting hardware setup for turtle enclosure automation..."

# Function to detect USB devices
detect_usb_devices() {
    print_status "Detecting USB devices..."
    
    echo "Connected USB devices:"
    lsusb | while read line; do
        echo "  $line"
    done
    
    echo
    echo "Video devices:"
    ls /dev/video* 2>/dev/null | while read device; do
        echo "  $device"
    done
    
    echo
    echo "Serial devices:"
    ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | while read device; do
        echo "  $device"
    done
}

# Function to configure TEMPerHUM sensor
configure_temperhum() {
    print_status "Configuring TEMPerHUM USB sensor..."
    
    # Check if TEMPerHUM is connected
    if lsusb | grep -q "0c45:7401"; then
        print_success "TEMPerHUM sensor detected"
        
        # Install TEMPerHUM support
        sudo apt install -y python3-pip
        sudo pip3 install temperhum
        
        # Create TEMPerHUM service
        sudo tee /etc/systemd/system/temperhum.service > /dev/null <<EOF
[Unit]
Description=TEMPerHUM USB Sensor Service
After=multi-user.target

[Service]
Type=simple
User=turtle
Group=turtle
ExecStart=/usr/bin/python3 -c "
import time
import subprocess
import json
import os

def read_temperhum():
    try:
        result = subprocess.run(['temperhum'], capture_output=True, text=True)
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            temp = None
            hum = None
            for line in lines:
                if 'Temperature:' in line:
                    temp = float(line.split(':')[1].strip().replace('°C', ''))
                elif 'Humidity:' in line:
                    hum = float(line.split(':')[1].strip().replace('%', ''))
            return temp, hum
    except Exception as e:
        print(f'Error reading TEMPerHUM: {e}')
    return None, None

def main():
    while True:
        temp, hum = read_temperhum()
        if temp is not None and hum is not None:
            # Convert Celsius to Fahrenheit
            temp_f = (temp * 9/5) + 32
            
            # Write to file for Home Assistant to read
            data = {
                'temperature': round(temp_f, 1),
                'humidity': round(hum, 1),
                'timestamp': time.time()
            }
            
            with open('/tmp/temperhum_data.json', 'w') as f:
                json.dump(data, f)
                
        time.sleep(30)  # Read every 30 seconds

if __name__ == '__main__':
    main()
"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable temperhum.service
        sudo systemctl start temperhum.service
        
        print_success "TEMPerHUM service configured and started"
    else
        print_warning "TEMPerHUM sensor not detected. Please connect the device and run this script again."
    fi
}

# Function to configure Arducam camera
configure_arducam() {
    print_status "Configuring Arducam USB camera..."
    
    # Check if camera is connected
    if ls /dev/video* > /dev/null 2>&1; then
        print_success "Camera device detected"
        
        # Install camera streaming software
        sudo apt install -y motion mjpg-streamer
        
        # Configure motion for camera streaming
        sudo tee /etc/motion/motion.conf > /dev/null <<EOF
# Motion configuration for turtle camera
daemon on
process_id_file /var/run/motion/motion.pid
log_file /var/log/motion/motion.log
log_level 6

# Camera settings
videodevice /dev/video0
width 1280
height 720
framerate 10
minimum_frame_time 0

# Output settings
output_normal off
output_motion off
ffmpeg_output_movies off
snapshot_interval 0

# Web interface
webcontrol_localhost off
webcontrol_port 8080
webcontrol_interface 0.0.0.0

# Stream settings
stream_localhost off
stream_port 8081
stream_quality 90
stream_maxrate 10
stream_limit 0

# Motion detection (disabled for continuous streaming)
threshold 0
lightswitch 0
EOF

        # Create motion service
        sudo tee /etc/systemd/system/turtle-camera.service > /dev/null <<EOF
[Unit]
Description=Turtle Camera Streaming Service
After=network.target

[Service]
Type=simple
User=turtle
Group=turtle
ExecStart=/usr/bin/motion
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable turtle-camera.service
        sudo systemctl start turtle-camera.service
        
        print_success "Camera streaming service configured and started"
        print_status "Camera stream available at: http://localhost:8081"
    else
        print_warning "Camera device not detected. Please connect the Arducam and run this script again."
    fi
}

# Function to configure Zigbee network
configure_zigbee() {
    print_status "Configuring Zigbee network..."
    
    # Check if Zigbee dongle is connected
    if ls /dev/ttyUSB* /dev/ttyACM* > /dev/null 2>&1; then
        print_success "Zigbee dongle detected"
        
        # Create Zigbee2MQTT configuration
        sudo mkdir -p /opt/turtle-enclosure/config/zigbee2mqtt
        sudo tee /opt/turtle-enclosure/config/zigbee2mqtt/configuration.yaml > /dev/null <<EOF
# Zigbee2MQTT configuration for turtle enclosure
permit_join: false
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://localhost:1883
  user: turtle
  password: turtle123

serial:
  port: /dev/ttyACM0
  adapter: zstack

frontend:
  port: 8080

devices:
  # Smart plugs will be added here after pairing
  # Example:
  # '0x00158d0009b1b123':
  #   friendly_name: 'turtle_cooling_fan'
  #   description: 'Cooling fan smart plug'

groups:
  turtle_enclosure:
    friendly_name: Turtle Enclosure
    devices:
      # Will be populated after device pairing

advanced:
  log_level: info
  log_output:
    - console
    - file
  log_file: /opt/turtle-enclosure/logs/zigbee2mqtt.log
  log_rotation: true
  log_maxfiles: 5
  pan_id: 6754
  channel: 11
  network_key: GENERATE_NEW_KEY
EOF

        sudo chown -R turtle:turtle /opt/turtle-enclosure/config/zigbee2mqtt
        
        print_success "Zigbee2MQTT configuration created"
        print_status "To pair devices, set permit_join: true in configuration and restart Zigbee2MQTT"
    else
        print_warning "Zigbee dongle not detected. Please connect the Sonoff dongle and run this script again."
    fi
}

# Function to configure touchscreen
configure_touchscreen() {
    print_status "Configuring touchscreen..."
    
    # Install touchscreen calibration tools
    sudo apt install -y xinput-calibrator x11vnc
    
    # Create touchscreen calibration script
    sudo tee /opt/turtle-enclosure/scripts/calibrate-touchscreen.sh > /dev/null <<'EOF'
#!/bin/bash

# Touchscreen calibration script
echo "Starting touchscreen calibration..."
echo "Follow the on-screen instructions to calibrate your touchscreen."

# Check if running in X
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi

# Run calibration
xinput_calibrator --output-type xinput

echo "Calibration complete!"
echo "To apply calibration, restart the X server or reboot the system."
EOF

    sudo chmod +x /opt/turtle-enclosure/scripts/calibrate-touchscreen.sh
    sudo chown turtle:turtle /opt/turtle-enclosure/scripts/calibrate-touchscreen.sh
    
    # Create VNC service for remote access
    sudo tee /etc/systemd/system/turtle-vnc.service > /dev/null <<EOF
[Unit]
Description=Turtle Enclosure VNC Server
After=graphical-session.target

[Service]
Type=simple
User=turtle
Group=turtle
Environment=DISPLAY=:0
ExecStart=/usr/bin/x11vnc -display :0 -forever -shared -rfbauth /home/turtle/.vnc/passwd
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Create VNC password
    sudo mkdir -p /home/turtle/.vnc
    echo "turtle123" | sudo tee /home/turtle/.vnc/passwd > /dev/null
    sudo chown -R turtle:turtle /home/turtle/.vnc
    sudo chmod 600 /home/turtle/.vnc/passwd
    
    sudo systemctl daemon-reload
    sudo systemctl enable turtle-vnc.service
    
    print_success "Touchscreen configuration completed"
    print_status "VNC server available at: localhost:5900 (password: turtle123)"
    print_status "To calibrate touchscreen, run: ./scripts/calibrate-touchscreen.sh"
}

# Function to configure USB hub
configure_usb_hub() {
    print_status "Configuring USB hub..."
    
    # Create USB hub management script
    sudo tee /opt/turtle-enclosure/scripts/usb-hub-manager.sh > /dev/null <<'EOF'
#!/bin/bash

# USB Hub Manager for turtle enclosure
LOG_FILE="/opt/turtle-enclosure/logs/usb-hub.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check USB devices
check_devices() {
    log_message "Checking USB devices..."
    
    # Check TEMPerHUM
    if lsusb | grep -q "0c45:7401"; then
        log_message "TEMPerHUM sensor: Connected"
    else
        log_message "WARNING: TEMPerHUM sensor not detected"
    fi
    
    # Check camera
    if ls /dev/video* > /dev/null 2>&1; then
        log_message "Camera: Connected"
    else
        log_message "WARNING: Camera not detected"
    fi
    
    # Check Zigbee dongle
    if ls /dev/ttyUSB* /dev/ttyACM* > /dev/null 2>&1; then
        log_message "Zigbee dongle: Connected"
    else
        log_message "WARNING: Zigbee dongle not detected"
    fi
}

# Reset USB hub (if supported)
reset_hub() {
    log_message "Attempting USB hub reset..."
    # This would require specific hardware support
    # For now, just log the attempt
    log_message "USB hub reset attempted"
}

# Main function
main() {
    mkdir -p /opt/turtle-enclosure/logs
    
    case "$1" in
        "check")
            check_devices
            ;;
        "reset")
            reset_hub
            ;;
        *)
            echo "Usage: $0 {check|reset}"
            exit 1
            ;;
    esac
}

main "$@"
EOF

    sudo chmod +x /opt/turtle-enclosure/scripts/usb-hub-manager.sh
    sudo chown turtle:turtle /opt/turtle-enclosure/scripts/usb-hub-manager.sh
    
    # Add USB monitoring to crontab
    (crontab -u turtle -l 2>/dev/null; echo "*/2 * * * * /opt/turtle-enclosure/scripts/usb-hub-manager.sh check") | crontab -u turtle -
    
    print_success "USB hub management configured"
}

# Function to create hardware test script
create_hardware_test() {
    print_status "Creating hardware test script..."
    
    sudo tee /opt/turtle-enclosure/scripts/test-hardware.sh > /dev/null <<'EOF'
#!/bin/bash

# Hardware test script for turtle enclosure
echo "🐢 Turtle Enclosure Hardware Test"
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

# Test TEMPerHUM sensor
echo
echo "Testing TEMPerHUM sensor..."
if lsusb | grep -q "0c45:7401"; then
    print_success "TEMPerHUM sensor detected"
    if command -v temperhum > /dev/null; then
        echo "Reading sensor data..."
        temperhum_output=$(temperhum 2>/dev/null)
        if [ $? -eq 0 ]; then
            print_success "TEMPerHUM reading successful"
            echo "Data: $temperhum_output"
        else
            print_error "TEMPerHUM reading failed"
        fi
    else
        print_warning "TEMPerHUM software not installed"
    fi
else
    print_error "TEMPerHUM sensor not detected"
fi

# Test camera
echo
echo "Testing camera..."
if ls /dev/video* > /dev/null 2>&1; then
    print_success "Camera device detected"
    camera_device=$(ls /dev/video* | head -1)
    echo "Camera device: $camera_device"
    
    if command -v v4l2-ctl > /dev/null; then
        echo "Camera capabilities:"
        v4l2-ctl --device=$camera_device --list-formats-ext 2>/dev/null | head -10
    fi
else
    print_error "Camera device not detected"
fi

# Test Zigbee dongle
echo
echo "Testing Zigbee dongle..."
if ls /dev/ttyUSB* /dev/ttyACM* > /dev/null 2>&1; then
    print_success "Zigbee dongle detected"
    zigbee_device=$(ls /dev/ttyUSB* /dev/ttyACM* | head -1)
    echo "Zigbee device: $zigbee_device"
else
    print_error "Zigbee dongle not detected"
fi

# Test touchscreen
echo
echo "Testing touchscreen..."
if xinput list | grep -i touch > /dev/null; then
    print_success "Touchscreen detected"
    xinput list | grep -i touch
else
    print_warning "Touchscreen not detected or not properly configured"
fi

# Test network connectivity
echo
echo "Testing network connectivity..."
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    print_success "Internet connectivity confirmed"
else
    print_error "No internet connectivity"
fi

# Test Docker containers
echo
echo "Testing Docker containers..."
if command -v docker > /dev/null; then
    if docker ps | grep -q "turtle-"; then
        print_success "Turtle Docker containers running"
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep "turtle-"
    else
        print_warning "No turtle Docker containers running"
    fi
else
    print_error "Docker not installed"
fi

# Test Home Assistant
echo
echo "Testing Home Assistant..."
if curl -s http://localhost:8123 > /dev/null; then
    print_success "Home Assistant is accessible"
else
    print_error "Home Assistant is not accessible"
fi

echo
echo "Hardware test completed!"
echo "Check the results above and address any issues before proceeding."
EOF

    sudo chmod +x /opt/turtle-enclosure/scripts/test-hardware.sh
    sudo chown turtle:turtle /opt/turtle-enclosure/scripts/test-hardware.sh
    
    print_success "Hardware test script created"
}

# Main execution
echo
detect_usb_devices

echo
print_status "Configuring hardware components..."

configure_temperhum
configure_arducam
configure_zigbee
configure_touchscreen
configure_usb_hub
create_hardware_test

# Set permissions
print_status "Setting final permissions..."
sudo chown -R turtle:turtle /opt/turtle-enclosure
sudo chmod -R 755 /opt/turtle-enclosure

print_success "Hardware setup completed successfully!"
echo
print_status "Next steps:"
echo "============="
echo "1. Test hardware: ./scripts/test-hardware.sh"
echo "2. Calibrate touchscreen: ./scripts/calibrate-touchscreen.sh"
echo "3. Pair Zigbee devices (set permit_join: true in Zigbee2MQTT config)"
echo "4. Start services: sudo systemctl start turtle-*"
echo "5. Access camera stream: http://localhost:8081"
echo "6. Access VNC: localhost:5900 (password: turtle123)"
echo
print_warning "Important Notes:"
echo "=================="
echo "- Connect all USB devices before testing"
echo "- Run hardware test to verify all components"
echo "- Calibrate touchscreen for accurate touch input"
echo "- Pair Zigbee devices one at a time"
echo "- Check logs if devices are not detected"
echo
print_success "Hardware configuration is ready! 🐢" 