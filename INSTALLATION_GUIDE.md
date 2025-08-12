# 🐢 Eastern Box Turtle Enclosure - Installation Guide

## Overview

This guide will help you install and configure a comprehensive IoT monitoring and control system for your eastern box turtle's enclosure. The system features environmental monitoring, smart controls, and a beautiful turtle-themed touchscreen interface.

## 🏗️ System Architecture

### Hardware Requirements
- **Host**: Beelink Mini PC (Ubuntu Server 22.04 LTS)
- **Display**: ROADOM 10.1" Touchscreen Monitor (1024×600 IPS)
- **Sensors**: TEMPerHUM PC USB sensor (temperature & humidity)
- **Camera**: Arducam 1080P Day & Night Vision USB Camera
- **Zigbee Hub**: Sonoff Zigbee USB Dongle Plus (ZBDongle-E 3.0)
- **Smart Plugs**: ZigBee Smart Plugs 4-pack with energy monitoring
- **USB Hub**: Anker 4-Port USB 3.0 Hub + extension cables

### Software Stack
- **OS**: Ubuntu Server 22.04 LTS with minimal desktop
- **Containerization**: Docker + Docker Compose
- **Home Assistant**: Core automation platform
- **Display**: X11 + Openbox for lightweight desktop
- **Kiosk**: Chromium in fullscreen mode
- **Auto-start**: Systemd services for reliability

## 🚀 Quick Installation

### Prerequisites
- Ubuntu Server 22.04 LTS installed
- At least 10GB free disk space
- Internet connectivity
- Sudo access

### One-Command Installation

```bash
# Clone or download the turtle-enclosure project
cd /home/bitkittyy/turtle-enclosure

# Run the master setup script
./scripts/setup-turtle-enclosure.sh
```

This single command will:
1. Install Ubuntu Server packages and minimal desktop
2. Install Docker and Docker Compose
3. Configure Home Assistant with turtle-themed automation
4. Set up kiosk mode for touchscreen interface
5. Configure USB devices and Zigbee network
6. Create systemd services for auto-start

## 📋 Step-by-Step Installation

If you prefer to run the installation step by step:

### Step 1: System Setup
```bash
./scripts/01-system-setup.sh
```
- Installs essential packages
- Configures minimal desktop environment
- Sets up USB device rules
- Creates systemd services
- Configures firewall and security

### Step 2: Docker Setup
```bash
./scripts/02-docker-setup.sh
```
- Installs Docker Engine
- Installs Docker Compose
- Configures Docker daemon
- Creates Docker networks
- Sets up auto-restart policies

### Step 3: Home Assistant Setup
```bash
./scripts/03-home-assistant-setup.sh
```
- Creates Home Assistant configuration
- Sets up turtle-themed automations
- Configures sensors and switches
- Creates custom dashboards
- Sets up notification system

### Step 4: Hardware Integration
```bash
./scripts/05-hardware-setup.sh
```
- Configures TEMPerHUM USB sensor
- Sets up Arducam camera streaming
- Configures Zigbee network
- Calibrates touchscreen
- Creates hardware test scripts

## 🔧 Post-Installation Configuration

### 1. Hardware Connection
Connect your hardware devices:
- TEMPerHUM USB sensor
- Arducam USB camera
- Sonoff Zigbee dongle
- Touchscreen monitor

### 2. Test Hardware
```bash
./scripts/test-hardware.sh
```
This will verify all hardware components are working correctly.

### 3. Calibrate Touchscreen
```bash
./scripts/calibrate-touchscreen.sh
```
Follow the on-screen instructions to calibrate your touchscreen.

### 4. Access Home Assistant
- Open browser: http://localhost:8123
- Complete initial setup
- Create your admin account

### 5. Configure Turtle Settings
In Home Assistant:
- Set temperature range: 70-85°F
- Set humidity range: 60-80%
- Configure lighting schedule
- Set up mobile notifications

## 🎛️ System Access

### Web Interfaces
- **Home Assistant**: http://localhost:8123
- **Grafana**: http://localhost:3000 (admin/turtle123)
- **Node-RED**: http://localhost:1880
- **InfluxDB**: http://localhost:8086 (admin/turtle123)

### Remote Access
- **VNC**: localhost:5900 (password: turtle123)
- **SSH**: Standard SSH access

### Camera Stream
- **Live Feed**: http://localhost:8081

## 🐢 Turtle Care Features

### Environmental Monitoring
- **Temperature**: Real-time monitoring with alerts
- **Humidity**: Continuous humidity tracking
- **Lighting**: Automated UVB lighting schedule
- **Camera**: 24/7 enclosure monitoring

### Smart Controls
- **Cooling Fan**: Automatic temperature control
- **Misting System**: Humidity maintenance
- **UVB Lighting**: Day/night cycle automation
- **Manual Override**: Touchscreen controls

### Notifications
- **Mobile App**: Home Assistant mobile notifications
- **Email Alerts**: Backup notification system
- **Critical Alerts**: Emergency notifications for extreme conditions
- **Equipment Monitoring**: Failure detection and alerts

## 🔧 Maintenance

### System Monitoring
```bash
# Check system status
./scripts/monitor-system.sh

# Check Docker containers
./scripts/docker-health.sh

# View logs
tail -f /opt/turtle-enclosure/logs/*.log
```

### Backups
```bash
# Manual backup
./scripts/backup-config.sh

# Automatic backups run daily at 2 AM
```

### Updates
```bash
# Update Docker containers
cd /opt/turtle-enclosure/docker
docker-compose pull
docker-compose up -d
```

## 🐛 Troubleshooting

### Common Issues

#### System Won't Start
```bash
# Check system logs
sudo journalctl -u turtle-* -f

# Restart services
sudo systemctl restart turtle-*
```

#### Hardware Not Detected
```bash
# Check USB devices
lsusb
ls /dev/video*
ls /dev/ttyUSB* /dev/ttyACM*

# Run hardware test
./scripts/test-hardware.sh
```

#### Touchscreen Not Working
```bash
# Calibrate touchscreen
./scripts/calibrate-touchscreen.sh

# Check touchscreen devices
xinput list
```

#### Docker Issues
```bash
# Check Docker logs
cd /opt/turtle-enclosure/docker
docker-compose logs

# Restart Docker containers
docker-compose restart
```

### Log Locations
- **System Logs**: `/opt/turtle-enclosure/logs/`
- **Docker Logs**: `docker-compose logs` in `/opt/turtle-enclosure/docker/`
- **Home Assistant**: `/opt/turtle-enclosure/config/homeassistant/home-assistant.log`

## 📱 Mobile App Setup

1. Install "Home Assistant" app on your phone
2. Add your server: http://YOUR_IP:8123
3. Configure notifications
4. Monitor your turtle remotely

## 🎨 Customization

### Turtle-Themed UI
The system includes:
- Natural earth tone color scheme
- Turtle-inspired icons and graphics
- Organic, flowing layouts
- Touch-optimized interface

### Custom Automations
- Temperature-based cooling control
- Humidity-based misting system
- Time-based lighting schedules
- Equipment failure detection

### Additional Features
- Historical data visualization
- Energy consumption monitoring
- Weather integration
- Remote access capabilities

## 📞 Support

### Documentation
- **Quick Start**: `/opt/turtle-enclosure/QUICK_START.md`
- **System Info**: `/opt/turtle-enclosure/system-info.txt`
- **Installation Log**: `/tmp/turtle-enclosure-install.log`

### Commands
```bash
# System information
cat /opt/turtle-enclosure/system-info.txt

# Check service status
sudo systemctl status turtle-*

# View recent logs
tail -f /opt/turtle-enclosure/logs/*.log

# Restart all services
sudo systemctl restart turtle-*
```

## 🐢 Turtle Care Tips

- Monitor temperature daily (70-85°F optimal)
- Check humidity levels (60-80% optimal)
- Provide fresh water regularly
- Feed appropriate diet
- Maintain UVB lighting schedule
- Clean enclosure regularly
- Monitor for signs of illness

## 🎉 Congratulations!

Your turtle enclosure automation system is now ready! The system will:
- Automatically monitor environmental conditions
- Control heating, cooling, and lighting
- Provide real-time alerts and notifications
- Display beautiful turtle-themed interface
- Maintain optimal conditions for your turtle

Happy turtle parenting! 🐢💚

---

**Built with ❤️ for happy, healthy turtles** 