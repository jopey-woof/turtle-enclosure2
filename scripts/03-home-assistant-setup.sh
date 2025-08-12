#!/bin/bash

# Eastern Box Turtle Enclosure - Home Assistant Setup Script
# This script configures Home Assistant with turtle-themed customizations

set -e  # Exit on any error

echo "🐢 Eastern Box Turtle Enclosure - Home Assistant Setup"
echo "====================================================="

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

print_status "Starting Home Assistant setup for turtle enclosure automation..."

# Create Home Assistant configuration directory
print_status "Creating Home Assistant configuration directory..."
sudo mkdir -p /opt/turtle-enclosure/config/homeassistant
sudo chown -R turtle:turtle /opt/turtle-enclosure/config/homeassistant

# Create initial Home Assistant configuration
print_status "Creating initial Home Assistant configuration..."
sudo tee /opt/turtle-enclosure/config/homeassistant/configuration.yaml > /dev/null <<'EOF'
# Eastern Box Turtle Enclosure - Home Assistant Configuration
# This configuration provides automated monitoring and control for turtle enclosures

# Basic configuration
default_config:
  # Enable all integrations by default
  integrations:

# Load packages
homeassistant:
  name: Turtle Enclosure
  latitude: 40.7128  # New York City - Update for your location
  longitude: -74.0060
  elevation: 10
  unit_system: imperial
  time_zone: America/New_York
  packages: !include_dir_named packages
  customize: !include customize.yaml

# Frontend configuration
frontend:
  themes: !include_dir_merge_named themes
  javascript_version: auto

# Logging configuration
logger:
  default: info
  logs:
    custom_components: debug
    homeassistant.components.temperhum: debug
    homeassistant.components.zigbee2mqtt: debug
    homeassistant.components.mqtt: debug

# HTTP configuration
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - ::1
  cors_allowed_origins:
    - "http://localhost:8123"
    - "http://127.0.0.1:8123"

# MQTT configuration
mqtt:
  broker: localhost
  port: 1883
  client_id: turtle_homeassistant
  discovery: true
  discovery_prefix: zigbee2mqtt

# InfluxDB configuration for data storage
influxdb:
  host: localhost
  port: 8086
  database: turtle_data
  username: admin
  password: turtle123
  max_retries: 3
  default_measurement: state
  override_measurement: state
  tags:
    instance: turtle_enclosure
    source: homeassistant

# Automation configuration
automation: !include automations.yaml

# Script configuration
script: !include scripts.yaml

# Scene configuration
scene: !include scenes.yaml

# Group configuration
group: !include groups.yaml

# Template configuration
template: !include templates.yaml

# Custom components
custom_components: !include_dir_list custom_components

# Lovelace configuration
lovelace:
  mode: storage
  dashboards:
    turtle-dashboard:
      mode: storage
      title: Turtle Enclosure
      icon: mdi:turtle
      show_in_sidebar: true
      require_admin: false
EOF

# Create packages directory
print_status "Creating packages directory..."
sudo mkdir -p /opt/turtle-enclosure/config/homeassistant/packages
sudo chown turtle:turtle /opt/turtle-enclosure/config/homeassistant/packages

# Create turtle enclosure package
print_status "Creating turtle enclosure package..."
sudo tee /opt/turtle-enclosure/config/homeassistant/packages/turtle_enclosure.yaml > /dev/null <<'EOF'
# Turtle Enclosure Package
# This package contains all turtle enclosure related configurations

# Input helpers for turtle enclosure
input_boolean:
  turtle_cooling_override:
    name: "Turtle Cooling Override"
    icon: mdi:fan
  turtle_lighting_override:
    name: "Turtle Lighting Override"
    icon: mdi:lightbulb
  turtle_misting_override:
    name: "Turtle Misting Override"
    icon: mdi:water

input_number:
  target_temperature:
    name: "Target Temperature"
    min: 65
    max: 95
    step: 1
    unit_of_measurement: "°F"
    icon: mdi:thermometer
  target_humidity:
    name: "Target Humidity"
    min: 40
    max: 90
    step: 5
    unit_of_measurement: "%"
    icon: mdi:water-percent

input_select:
  turtle_lighting_mode:
    name: "Turtle Lighting Mode"
    options:
      - "Auto"
      - "Day"
      - "Night"
      - "Off"
    icon: mdi:lightbulb

# Sensors for turtle enclosure
sensor:
  - platform: template
    sensors:
      turtle_temperature_status:
        friendly_name: "Temperature Status"
        value_template: >-
          {% set temp = states('sensor.temperhum_temperature') | float %}
          {% if temp < 70 %}
            Too Cold
          {% elif temp > 85 %}
            Too Hot
          {% else %}
            Optimal
          {% endif %}
        icon_template: >-
          {% set temp = states('sensor.temperhum_temperature') | float %}
          {% if temp < 70 %}
            mdi:thermometer-low
          {% elif temp > 85 %}
            mdi:thermometer-high
          {% else %}
            mdi:thermometer
          {% endif %}

      turtle_humidity_status:
        friendly_name: "Humidity Status"
        value_template: >-
          {% set hum = states('sensor.temperhum_humidity') | float %}
          {% if hum < 60 %}
            Too Dry
          {% elif hum > 80 %}
            Too Humid
          {% else %}
            Optimal
          {% endif %}
        icon_template: >-
          {% set hum = states('sensor.temperhum_humidity') | float %}
          {% if hum < 60 %}
            mdi:water-off
          {% elif hum > 80 %}
            mdi:water-alert
          {% else %}
            mdi:water
          {% endif %}

# Binary sensors for turtle enclosure
binary_sensor:
  - platform: template
    sensors:
      turtle_environment_alert:
        friendly_name: "Environment Alert"
        value_template: >-
          {% set temp = states('sensor.temperhum_temperature') | float %}
          {% set hum = states('sensor.temperhum_humidity') | float %}
          {{ temp < 70 or temp > 85 or hum < 60 or hum > 80 }}
        icon_template: >-
          {% set temp = states('sensor.temperhum_temperature') | float %}
          {% set hum = states('sensor.temperhum_humidity') | float %}
          {% if temp < 70 or temp > 85 or hum < 60 or hum > 80 %}
            mdi:alert-circle
          {% else %}
            mdi:check-circle
          {% endif %}

# Switches for turtle enclosure
switch:
  - platform: template
    switches:
      turtle_cooling_fan:
        friendly_name: "Cooling Fan"
        value_template: "{{ states('switch.zigbee_plug_1') }}"
        turn_on:
          service: switch.turn_on
          target:
            entity_id: switch.zigbee_plug_1
        turn_off:
          service: switch.turn_off
          target:
            entity_id: switch.zigbee_plug_1
        icon_template: mdi:fan

      turtle_uvb_light:
        friendly_name: "UVB Light"
        value_template: "{{ states('switch.zigbee_plug_2') }}"
        turn_on:
          service: switch.turn_on
          target:
            entity_id: switch.zigbee_plug_2
        turn_off:
          service: switch.turn_off
          target:
            entity_id: switch.zigbee_plug_2
        icon_template: mdi:lightbulb

      turtle_misting_system:
        friendly_name: "Misting System"
        value_template: "{{ states('switch.zigbee_plug_3') }}"
        turn_on:
          service: switch.turn_on
          target:
            entity_id: switch.zigbee_plug_3
        turn_off:
          service: switch.turn_off
          target:
            entity_id: switch.zigbee_plug_3
        icon_template: mdi:water

# Camera configuration
camera:
  - platform: generic
    name: "Turtle Camera"
    still_image_url: http://localhost:8080/stream.mjpg
    stream_source: http://localhost:8080/stream.mjpg
    verify_ssl: false

# Weather integration (optional)
weather:
  - platform: openweathermap
    api_key: !secret openweathermap_api_key
    name: "Local Weather"
EOF

# Create customize.yaml
print_status "Creating customize.yaml..."
sudo tee /opt/turtle-enclosure/config/homeassistant/customize.yaml > /dev/null <<'EOF'
# Customize entities for turtle enclosure

# Temperature sensor customization
sensor.temperhum_temperature:
  friendly_name: "Enclosure Temperature"
  icon: mdi:thermometer
  unit_of_measurement: "°F"
  device_class: temperature

# Humidity sensor customization
sensor.temperhum_humidity:
  friendly_name: "Enclosure Humidity"
  icon: mdi:water-percent
  unit_of_measurement: "%"
  device_class: humidity

# Camera customization
camera.turtle_camera:
  friendly_name: "Turtle Camera"
  icon: mdi:camera

# Switch customizations
switch.turtle_cooling_fan:
  friendly_name: "Cooling Fan"
  icon: mdi:fan

switch.turtle_uvb_light:
  friendly_name: "UVB Light"
  icon: mdi:lightbulb

switch.turtle_misting_system:
  friendly_name: "Misting System"
  icon: mdi:water
EOF

# Create automations.yaml
print_status "Creating automations.yaml..."
sudo tee /opt/turtle-enclosure/config/homeassistant/automations.yaml > /dev/null <<'EOF'
# Turtle Enclosure Automations

# Temperature monitoring automation
- alias: "Temperature Too High - Activate Cooling"
  description: "Activate cooling when temperature exceeds 85°F"
  trigger:
    platform: numeric_state
    entity_id: sensor.temperhum_temperature
    above: 85
  condition:
    - condition: state
      entity_id: input_boolean.turtle_cooling_override
      state: "off"
  action:
    - service: switch.turn_on
      target:
        entity_id: switch.turtle_cooling_fan
    - service: notify.mobile_app
      data:
        title: "Turtle Alert - High Temperature"
        message: "Temperature is {{ states('sensor.temperhum_temperature') }}°F. Cooling fan activated."

- alias: "Temperature Normal - Deactivate Cooling"
  description: "Deactivate cooling when temperature drops below 80°F"
  trigger:
    platform: numeric_state
    entity_id: sensor.temperhum_temperature
    below: 80
  condition:
    - condition: state
      entity_id: input_boolean.turtle_cooling_override
      state: "off"
  action:
    - service: switch.turn_off
      target:
        entity_id: switch.turtle_cooling_fan

# Humidity monitoring automation
- alias: "Humidity Too Low - Activate Misting"
  description: "Activate misting when humidity drops below 60%"
  trigger:
    platform: numeric_state
    entity_id: sensor.temperhum_humidity
    below: 60
  condition:
    - condition: state
      entity_id: input_boolean.turtle_misting_override
      state: "off"
  action:
    - service: switch.turn_on
      target:
        entity_id: switch.turtle_misting_system
    - delay: "00:05:00"
    - service: switch.turn_off
      target:
        entity_id: switch.turtle_misting_system
    - service: notify.mobile_app
      data:
        title: "Turtle Alert - Low Humidity"
        message: "Humidity is {{ states('sensor.temperhum_humidity') }}%. Misting system activated."

# Lighting automation
- alias: "Day Lighting Schedule"
  description: "Control UVB lighting based on time"
  trigger:
    platform: time
    at: "08:00:00"
  condition:
    - condition: state
      entity_id: input_select.turtle_lighting_mode
      state: "Auto"
  action:
    - service: switch.turn_on
      target:
        entity_id: switch.turtle_uvb_light

- alias: "Night Lighting Schedule"
  description: "Turn off UVB lighting at night"
  trigger:
    platform: time
    at: "20:00:00"
  condition:
    - condition: state
      entity_id: input_select.turtle_lighting_mode
      state: "Auto"
  action:
    - service: switch.turn_off
      target:
        entity_id: switch.turtle_uvb_light

# Critical alerts automation
- alias: "Critical Temperature Alert"
  description: "Send critical alert for extreme temperatures"
  trigger:
    platform: numeric_state
    entity_id: sensor.temperhum_temperature
    above: 90
  action:
    - service: notify.mobile_app
      data:
        title: "🚨 CRITICAL - Turtle Temperature Alert"
        message: "Temperature is {{ states('sensor.temperhum_temperature') }}°F! Immediate action required!"

- alias: "Critical Humidity Alert"
  description: "Send critical alert for extreme humidity"
  trigger:
    platform: numeric_state
    entity_id: sensor.temperhum_humidity
    below: 50
  action:
    - service: notify.mobile_app
      data:
        title: "🚨 CRITICAL - Turtle Humidity Alert"
        message: "Humidity is {{ states('sensor.temperhum_humidity') }}%! Immediate action required!"

# Equipment failure detection
- alias: "Cooling Fan Failure Detection"
  description: "Detect if cooling fan is not consuming power when it should be on"
  trigger:
    platform: state
    entity_id: switch.turtle_cooling_fan
    to: "on"
  action:
    - delay: "00:05:00"
    - condition: template
      value_template: "{{ states('sensor.zigbee_plug_1_power') | float < 5 }}"
    - service: notify.mobile_app
      data:
        title: "⚠️ Equipment Alert - Cooling Fan"
        message: "Cooling fan may not be working properly. Check equipment."
EOF

# Create scripts.yaml
print_status "Creating scripts.yaml..."
sudo tee /opt/turtle-enclosure/config/homeassistant/scripts.yaml > /dev/null <<'EOF'
# Turtle Enclosure Scripts

# Emergency cooling script
emergency_cooling:
  alias: "Emergency Cooling"
  description: "Activate all cooling systems"
  fields:
    duration:
      description: "Duration to run cooling"
      example: "00:30:00"
  sequence:
    - service: switch.turn_on
      target:
        entity_id: switch.turtle_cooling_fan
    - service: switch.turn_on
      target:
        entity_id: switch.turtle_misting_system
    - delay: "{{ duration }}"
    - service: switch.turn_off
      target:
        entity_id: switch.turtle_cooling_fan
    - service: switch.turn_off
      target:
        entity_id: switch.turtle_misting_system

# Turtle feeding reminder
turtle_feeding_reminder:
  alias: "Turtle Feeding Reminder"
  description: "Send feeding reminder notification"
  sequence:
    - service: notify.mobile_app
      data:
        title: "🐢 Turtle Feeding Time"
        message: "Time to feed your turtle! Don't forget fresh water too."

# System health check
system_health_check:
  alias: "System Health Check"
  description: "Check all system components"
  sequence:
    - service: persistent_notification.create
      data:
        title: "System Health Check"
        message: |
          Temperature: {{ states('sensor.temperhum_temperature') }}°F
          Humidity: {{ states('sensor.temperhum_humidity') }}%
          Cooling Fan: {{ states('switch.turtle_cooling_fan') }}
          UVB Light: {{ states('switch.turtle_uvb_light') }}
          Misting System: {{ states('switch.turtle_misting_system') }}
EOF

# Create scenes.yaml
print_status "Creating scenes.yaml..."
sudo tee /opt/turtle-enclosure/config/homeassistant/scenes.yaml > /dev/null <<'EOF'
# Turtle Enclosure Scenes

# Day mode scene
turtle_day_mode:
  name: "Turtle Day Mode"
  entities:
    switch.turtle_uvb_light:
      state: "on"
    switch.turtle_cooling_fan:
      state: "off"
    switch.turtle_misting_system:
      state: "off"

# Night mode scene
turtle_night_mode:
  name: "Turtle Night Mode"
  entities:
    switch.turtle_uvb_light:
      state: "off"
    switch.turtle_cooling_fan:
      state: "off"
    switch.turtle_misting_system:
      state: "off"

# Emergency mode scene
turtle_emergency_mode:
  name: "Turtle Emergency Mode"
  entities:
    switch.turtle_cooling_fan:
      state: "on"
    switch.turtle_misting_system:
      state: "on"
    switch.turtle_uvb_light:
      state: "off"
EOF

# Create groups.yaml
print_status "Creating groups.yaml..."
sudo tee /opt/turtle-enclosure/config/homeassistant/groups.yaml > /dev/null <<'EOF'
# Turtle Enclosure Groups

# All turtle switches
turtle_switches:
  name: "Turtle Switches"
  entities:
    - switch.turtle_cooling_fan
    - switch.turtle_uvb_light
    - switch.turtle_misting_system

# All turtle sensors
turtle_sensors:
  name: "Turtle Sensors"
  entities:
    - sensor.temperhum_temperature
    - sensor.temperhum_humidity
    - sensor.turtle_temperature_status
    - sensor.turtle_humidity_status

# All turtle controls
turtle_controls:
  name: "Turtle Controls"
  entities:
    - input_boolean.turtle_cooling_override
    - input_boolean.turtle_lighting_override
    - input_boolean.turtle_misting_override
    - input_number.target_temperature
    - input_number.target_humidity
    - input_select.turtle_lighting_mode
EOF

# Create templates.yaml
print_status "Creating templates.yaml..."
sudo tee /opt/turtle-enclosure/config/homeassistant/templates.yaml > /dev/null <<'EOF'
# Turtle Enclosure Templates

# Temperature status template
temperature_status: >
  {% set temp = states('sensor.temperhum_temperature') | float %}
  {% if temp < 70 %}
    Too Cold ({{ temp }}°F)
  {% elif temp > 85 %}
    Too Hot ({{ temp }}°F)
  {% else %}
    Optimal ({{ temp }}°F)
  {% endif %}

# Humidity status template
humidity_status: >
  {% set hum = states('sensor.temperhum_humidity') | float %}
  {% if hum < 60 %}
    Too Dry ({{ hum }}%)
  {% elif hum > 80 %}
    Too Humid ({{ hum }}%)
  {% else %}
    Optimal ({{ hum }}%)
  {% endif %}

# System status template
system_status: >
  {% set temp = states('sensor.temperhum_temperature') | float %}
  {% set hum = states('sensor.temperhum_humidity') | float %}
  {% if temp < 70 or temp > 85 or hum < 60 or hum > 80 %}
    ⚠️ Attention Required
  {% else %}
    ✅ All Systems Normal
  {% endif %}
EOF

# Create secrets.yaml
print_status "Creating secrets.yaml..."
sudo tee /opt/turtle-enclosure/config/homeassistant/secrets.yaml > /dev/null <<'EOF'
# Turtle Enclosure Secrets
# Add your API keys and sensitive information here

# OpenWeatherMap API key (optional)
openweathermap_api_key: "your_api_key_here"

# Email configuration (optional)
email_password: "your_email_password_here"

# Mobile app configuration
mobile_app_device_id: "your_device_id_here"
EOF

# Set proper permissions
print_status "Setting proper permissions..."
sudo chown -R turtle:turtle /opt/turtle-enclosure/config/homeassistant
sudo chmod -R 755 /opt/turtle-enclosure/config/homeassistant

# Create Home Assistant startup script
print_status "Creating Home Assistant startup script..."
sudo tee /opt/turtle-enclosure/scripts/start-homeassistant.sh > /dev/null <<'EOF'
#!/bin/bash

# Start Home Assistant and related services
cd /opt/turtle-enclosure/docker

# Start all services
docker-compose up -d

# Wait for Home Assistant to be ready
echo "Waiting for Home Assistant to start..."
sleep 30

# Check if Home Assistant is responding
for i in {1..30}; do
    if curl -s http://localhost:8123 > /dev/null; then
        echo "Home Assistant is ready!"
        break
    fi
    echo "Waiting for Home Assistant... ($i/30)"
    sleep 10
done

echo "Turtle Enclosure system is ready!"
EOF

sudo chmod +x /opt/turtle-enclosure/scripts/start-homeassistant.sh
sudo chown turtle:turtle /opt/turtle-enclosure/scripts/start-homeassistant.sh

print_success "Home Assistant setup completed successfully!"
echo
print_status "Next steps:"
echo "1. Start Home Assistant: ./scripts/start-homeassistant.sh"
echo "2. Access Home Assistant at: http://localhost:8123"
echo "3. Complete initial setup in the web interface"
echo "4. Configure hardware integration: ./scripts/05-hardware-setup.sh"
echo
print_warning "Note: You'll need to complete the initial Home Assistant setup in the web interface"
print_warning "Update the secrets.yaml file with your actual API keys and credentials" 