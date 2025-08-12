# Eastern Box Turtle Enclosure Automation System

I'm building a comprehensive IoT monitoring and control system for my eastern box turtle's enclosure using the following hardware and software stack:

## Hardware Setup
- **Host**: Beelink Mini PC (running Ubuntu Server 22.04 LTS)
- **Display**: ROADOM 10.1" Touchscreen Monitor (1024×600 IPS) - Primary kiosk interface
- **Connectivity**: 3-foot Anker HDMI cable for display connection
- **Sensors**: TEMPerHUM PC USB sensor (temperature & humidity monitoring)
- **Camera**: Arducam 1080P Day & Night Vision USB Camera
- **Zigbee Hub**: Sonoff Zigbee USB Dongle Plus (ZBDongle-E 3.0)
- **Smart Control**: ZigBee Smart Plugs 4-pack with energy monitoring (15A outlets, Zigbee repeaters)
- **USB Expansion**: Anker 4-Port USB 3.0 Hub + AINOPE USB 3.0 extension cables
- **Primary Heat Control**: Vivarium Electronics VE-200 w/night drop (existing, reliable thermostat)

## Software Stack
- **OS**: Ubuntu Server 22.04 LTS with minimal desktop environment
- **Container Platform**: Docker + Docker Compose
- **Home Assistant**: Running in Docker container
- **Kiosk Interface**: Chromium browser in fullscreen kiosk mode
- **Display Manager**: X11 with lightweight window manager (Openbox/LXDE)
- **Auto-start**: Systemd services for automatic kiosk launch

## Project Goals
1. **Touchscreen Kiosk Interface**: Create a simple, intuitive touchscreen dashboard for non-technical user operation
2. **Environmental Monitoring**: Track temperature and humidity with large, easy-to-read displays
3. **Smart Cooling Control**: Touch-controlled fans, misters, or cooling devices via Zigbee smart plugs
4. **Live Camera Feed**: Integrated video stream viewable on the touchscreen interface
5. **Energy Monitoring**: Display real-time power consumption from smart plugs
6. **Push Notifications**: Mobile app and email alerts for critical conditions and equipment failures
7. **Data Integration**: Monitor and log data while working alongside existing VE-200 heat controller
8. **Simple Device Control**: Large touch buttons for manual override of automated systems
9. **Visual Alerts**: Clear on-screen notifications for any issues or out-of-range conditions
10. **Beautiful Turtle Theming**: Create a visually stunning interface with turtle and nature-inspired design elements

## Specific Requirements
- Temperature range: 70-85°F (21-29°C) with basking spot up to 90°F (32°C)
- Humidity range: 60-80% for eastern box turtles
- Day/night lighting cycles
- **Critical Alert Scenarios**: Temperature outside safe range, humidity too low/high, equipment power failures, camera/sensor disconnection
- **Notification Preferences**: Tiered alerts (Critical/Warning/Info) with user-configurable settings
- **Delivery Methods**: Home Assistant mobile app (primary), email backup, on-screen kiosk alerts
- Historical data visualization and export capabilities
- **Equipment Failure Detection**: Monitor smart plug power consumption to detect device failures

## Technical Tasks I Need Help With

### System Setup & Configuration
1. **Ubuntu Server Installation**: Configure Ubuntu Server 22.04 LTS with minimal desktop components
2. **Docker Environment**: Set up Docker, Docker Compose, and container management
3. **Home Assistant Container**: Configure HA in Docker with proper volume mapping and USB device access
4. **Kiosk Display Setup**: Install and configure X11, display manager, and touchscreen drivers
5. **Auto-boot Kiosk**: Create systemd services for automatic login and Chromium kiosk mode startup

### Hardware Integration
6. **USB Device Management**: Configure udev rules for TEMPerHUM sensor and Arducam camera
7. **Touchscreen Calibration**: Set up touch input calibration for the 10.1" 1024×600 display
8. **Zigbee Network Setup**: Configure Sonoff dongle in Docker and pair the 4-pack smart plugs
9. **Camera Streaming**: Set up Arducam USB camera integration with Home Assistant container
10. **USB Sensor Integration**: Configure TEMPerHUM PC USB sensor in Home Assistant

### Home Assistant & Interface Design
11. **Turtle-Themed UI Design**: Create custom CSS with turtle-inspired colors, icons, and visual elements
12. **Docker Compose Configuration**: Proper container networking, volumes, and device mapping
13. **Custom Icon Integration**: Implement turtle, leaf, water drop, thermometer, and nature-themed icons
14. **Themed Touch Controls**: Create large, turtle-themed buttons optimized for 1024×600 touchscreen
15. **Custom Animations**: Add subtle nature-themed animations (flowing water, gentle movements)

### Automation & Monitoring
16. **Push Notification System**: Configure Home Assistant mobile app notifications and email alerts
17. **Smart Alert Logic**: Create automations for environmental alerts (temp/humidity out of range)
18. **Equipment Monitoring**: Set up notifications for device failures based on power consumption patterns
19. **Cooling Automation**: Smart plug automations that work alongside the VE-200 thermostat
20. **Seasonal/Time-based Themes**: Dynamic color schemes that reflect natural day/night cycles

### System Reliability
21. **Container Auto-restart**: Configure Docker containers to restart automatically after power outages
22. **Kiosk Recovery**: Implement watchdog services to restart the kiosk if it crashes
23. **USB Device Persistence**: Ensure USB devices are properly mapped and accessible after reboots
24. **System Monitoring**: Set up monitoring for the underlying Ubuntu system and Docker containers

## Development Environment
- **Base OS**: Ubuntu Server 22.04 LTS with minimal desktop components
- **Containerization**: Docker + Docker Compose for service management
- **Display Stack**: X11 + Openbox/LXDE for lightweight desktop environment
- **Kiosk Browser**: Chromium in fullscreen kiosk mode pointing to Home Assistant
- **Home Assistant**: Running in Docker container with proper volume mapping
- **Configuration**: YAML files for Home Assistant, docker-compose.yml for services
- **Custom Theming**: Custom CSS for turtle-themed UI, SVG icons and graphics
- **System Services**: Systemd units for auto-login, kiosk startup, and container management
- **USB Management**: Udev rules for consistent device mapping and permissions
- **Color Palette**: Forest greens, earthy browns, shell patterns, water blues

## System Architecture Priorities
- **Container Isolation**: Home Assistant and related services in Docker containers
- **Hardware Access**: Proper USB device mapping for sensors and camera
- **Auto-recovery**: System should restart all services after power loss
- **Kiosk Reliability**: Browser should restart if it crashes, always return to HA dashboard
- **Touch Optimization**: All UI elements sized and styled for finger navigation
- **Resource Efficiency**: Lightweight desktop environment to preserve resources for HA
- **Update Management**: Easy container updates without affecting system configuration

## Design Aesthetic Goals
- **Color Scheme**: Natural earth tones (forest green, warm browns, shell amber, water blue)
- **Visual Elements**: Turtle shell patterns, leaf shapes, water ripples, organic curves
- **Icons**: Custom turtle-themed icons for temperature (turtle with thermometer), humidity (turtle with water drops), power (turtle with leaf), camera (turtle eye), etc.
- **Animations**: Subtle nature-inspired movements (gentle leaf sway, water ripples, soft shell patterns)
- **Typography**: Friendly, readable fonts that complement the natural theme
- **Layout**: Organic, flowing layouts that avoid harsh geometric shapes
- **Status Indicators**: Shell-pattern progress bars, leaf-shaped buttons, water-drop humidity indicators

## User Experience Priority
This system is being built for a non-technical user who will primarily interact through the touchscreen. The interface must be:
- **Intuitive**: Large buttons, clear labels, obvious functionality
- **Reliable**: Auto-recovery from errors, graceful failure handling
- **Visual**: Prominent displays of critical information (temperature, humidity, camera)
- **Simple**: Minimal complexity, essential functions only
- **Responsive**: Fast touch response, immediate visual feedback
- **Connected**: Easy mobile app setup with clear notification management
- **Informative**: Notification history accessible via touchscreen with simple alert acknowledgment
- **Delightful**: Beautiful turtle-themed design that creates emotional connection and joy
- **Natural**: Interface that feels organic and connects the user to their pet's natural habitat needs

Please help me structure this project step-by-step, starting with the Ubuntu Server setup and Docker configuration, then moving through hardware integration, Home Assistant container deployment, kiosk setup, and finally the turtle-themed UI design. 

**Implementation Priority:**
1. **Foundation**: Ubuntu Server + Docker + basic kiosk display
2. **Hardware**: USB devices, touchscreen, Zigbee network
3. **Core HA**: Container deployment with basic sensor integration
4. **Interface**: Turtle-themed dashboard optimized for touchscreen
5. **Advanced Features**: Notifications, automations, monitoring

What's the best systematic approach to implement this Ubuntu Server + Docker + Home Assistant kiosk system, and what specific configurations should I tackle first?