# AHU Homelab - MQTT Broker (Containerised Mosquitto)

Date : 01-06-2026

Time : 9:30 PM IST (GMT +05:30)

This is the first component of my Building Automation Systems (BAS) Homelab. It runs an **Eclipse Mosquitto** MQTT Broker inside a Docker container, which acts as the central message bus for all simulated field devices (motors, temperature sensors, smoke detectors) anmd the supervisory stack (historian, dashboard).

## What This Demonstrates

- Containerised deployment of an industrial messaging broker (MQTT)
- Network communication between a Raspberry pi (host) and a remote client (laptop)
- Verification of broker health using standard MQTTclient tools and a GUI Explorer
- Alignment with BAS architectures where field controllers publish data to a central network for monitoring and analytics

## Architecture

| Component | Role in BAS |
|-----------|-------------|
| Mosquitto broker | The “supervisory network” – collects data from all field devices |
| MQTT Explorer (laptop) | A technician’s diagnostic tool to inspect live data |
| Docker Compose | Declarative configuration of the broker service |

## Setup 

### 1. Docker Compose File

Place the following 'docker-compose.yml' in your project's 'docker/' folder:

```yaml
version: '3.8'
services:
  mqtt-broker:
    image: eclipse-mosquitto:2.0.15
    container_name: ahu-mqtt
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto/config:/mosquitto/config
    restart: unless-stopped
```

Create the configuration file mosquitto/config/mosquitto.conf:

```text
listener 1883
listener 9001
protocol websockets
allow_anonymous true
```

### 2. Start the Broker

```bash
cd docker
docker compose up -d
```

Check that the container is running

```bash
docker ps
```

Expected output (anonymised):

```text
CONTAINER ID   IMAGE                     STATUS          PORTS
[hash]         eclipse-mosquitto:2.0.15  Up 5 minutes    0.0.0.0:1883->1883/tcp, 0.0.0.0:9001->9001/tcp
```

## Verification

### 1. Command Line Test

On the Raspberry Pi (where the broker runs):

```bash
# Terminal 1 – subscribe
mosquitto_sub -h localhost -t "test/topic"

# Terminal 2 – publish
mosquitto_pub -h localhost -t "test/topic" -m "Hello from RPi"
```

The subscriber receives a "Hello" from the RPi

### 2. MQTT Explorer (Remote Client)

1. Install MQTT Explorer on your laptop.

2. Create a new connection to the broker using the Raspberry Pi's IP address and port 1883.

3. Click **Connect**. The left panel will show the $SYS topic tree if the connection succeeds.

Example $SYS data observed:

- broker/version – mosquitto version 2.0.15

- broker/uptime – container has been running (exact value omitted)

- clients/active – 1 (MQTT Explorer)

- load/messages/received – low, stable message rate

The metrics confirm that the broker is healthy and reachable over the local network.

## What This Means for the full AHU Project

The MQTT Broker is now the **central data hub**. In the coming weeks, I will add:

- Python simulators that publish motor status, temperature, and smoke alarms to topics like ahu/motor/status.

- InfluxDB to store time-series data.

- Grafana to visualize live and historical data.

- (Not yet decided) A BACNet gateway to bridge MQTT to a simulated BACNet device.

## Security Note

The broker currently allows anonymous connections (allow_anonymous_true) and listens on the local network. This is acceptable for a development homelab. In a production BAS environment, the broker would be secured with authentication (username/password) and TLS Encryption. 

## Files

- docker/docker-compose.yml - service definition

- docker/mosquitto/config/mosquitto.conf - broker configuration

- mosquitto/config/mosquitto.conf (inside container) - runtime config


