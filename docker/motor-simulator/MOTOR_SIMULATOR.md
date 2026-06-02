# AHU Homelab - Motor Simulator (MQTT Publisher)

This component is a **simulated field device** - a Python scripts that mimics a DDC Controller publishing motor status to an MQTT Broker. It is the first of several simulated devices in my BAS homelab (temperature sensors, smoke detectors will follow).

# What It Does 

- Every second, it publishes a JSON payload to the MQTT topic `ahu/motor/status` with the following fields:
 - `MotorOut` (bool): alternates every 10 seconds (simulating a motor that runs for 10 seconds, then stops for 10 seconds)
 - `OverloadAlarm` (bool): always `False` in this version (will be used later)
 - `timestamp` (float): Unix timestamp of publication

- The script runs continuously and can be executed directly on the Raspberry Pi or inside a Docker container as part of the `docker compose` stack.

## Architecture in BAS Terms

| Component | Role |
|-----------|------|
| Motor Simulator | DDC Controller that monitors a motor (simulated) and reports its state |
| MQTT broker (Mosquitto) | BAS supervisory network - collects data from all field devices |
| MQTT Explorer | Technician's diagnostic tool to inspect live data on the network |

## Setup

### 1. Python Script (`motor_simulator.py`)

Place the script in `docker/motor-simulator/motor_simulator.py` (or your project's `scripts/` folder).

```python
import paho.mqtt.client as mqtt
import time
import json

import os
# Broker Address can be overridden by environment variable
broker = os.getenv("MQTT_BROKER", "localhost")

broker = "localhost"
port = 1883
topic_status = "ahu/motor/status"
topic_alarm = "ahu/motor/alarm"

client = mqtt.Client()
client.connect(broker, port)

motor_out = False
overload_alarm = False
cycle = 0

while True:
    cycle += 1
    if cycle % 10 == 0:
        motor_out = not motor_out
    
    payload = {
        "MotorOut": motor_out,
        "OverloadAlarm": overload_alarm,
        "timestamp": time.time()
    }

    client.publish(topic_status, json.dumps(payload))
    print(f"Published: {payload}")
    time.sleep(1)
```

### 2. Docker Integration

Add the following service to your `docker-compose.yml` (on the same byline as the `mqtt-broker` service, right below it):

```yaml
motor-simulator:
        build: ./motor-simulator
        container_name: ahu-motor-sim
        depends_on:
            - mqtt-broker
        restart: unless-stopped
        environment:
            MQTT_BROKER: mqtt-broker
```

Also add the Dockerfile for the simulator:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY motor_simulator.py .
RUN pip install paho-mqtt
CMD ["python", "motor_simulator.py"]
```

### 3. Running

#### Manually (for testing)

```bash
cd docker/motor-simulator
python3 motor_simulator.py
```

#### Using Docker Compose (recommended for the full stack)

```bash
cd docker
docker compose up -d
```
### 4. Verification with MQTT Explorer

1. Ensure the MQTT broker container (`ahu-mqtt`) is running.

2. Start the motor simulator (manually or via Compose).

3. Open MQTT Explorer on your laptop, connect to the broker (use the Raspberry Pi's IP address, port 1883).

4. Subscribe to the topic `ahu/motor/status` (or `ahu/#` to see all messages).

5. The output displays a new message every second, with MotorOut alternating between `true` and `false` every 10 seconds.

#### Example Output seen in MQTT Explorer

```text
Topic: ahu/motor/status
Payload: {"MotorOut": false, "OverloadAlarm": false, "timestamp": 1780410673.5441449}
```

The broker's `$SYS` topics also confirm that a client is connected and messages are flowing.

## Files

- `docker/motor-simulator/motor_simulator.py` - the Python script

- `docker/motor-simulator/Dockerfile` - container definition

` 'docker/docker-compose.yml` - service definition (together with MQTT broker)
