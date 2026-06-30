# AHU Homelab – Docker Services for Thermal Simulation and Data Pipeline

This part of the project implements a complete data pipeline:

- **Thermal simulator** (Python) publishes temperature and heater state to an MQTT broker.
- **MQTT broker** (Mosquitto) acts as the central message bus.
- **MQTT → InfluxDB bridge** subscribes to all `ahu/#` topics and writes data to InfluxDB.
- **InfluxDB** stores the time‑series data.
- **Grafana** visualises the temperature oscillation and heater state.

The pipeline demonstrates how a BAS (Building Automation System) supervisory platform collects, stores, and visualises field device data – exactly what a real Niagara or SCADA system does.

---

## Docker Services Explained

### 1. MQTT Broker (`mqtt-broker`)

- **Image:** `eclipse-mosquitto:2.0.15`
- **Ports:** `1883` (MQTT), `9001` (WebSocket, bound to localhost only)
- **Config:** `mosquitto/config/mosquitto.conf` with `allow_anonymous true` (for homelab use).
- **Restart:** always.

### 2. Motor Simulator (`motor-simulator`)

- **Python script** that toggles `MotorOut` every 10 seconds and publishes `{"MotorOut": bool, "OverloadAlarm": false, "timestamp": ...}` to `ahu/motor/status`.
- **Environment:** `MQTT_BROKER=mqtt-broker` (Docker service name).

### 3. Thermal Simulator (`thermal-simulator`)

- **Python script** that simulates a simple thermal model:
  - Temperature rises at 0.5°C/min when heater is ON, falls at 0.3°C/min when OFF.
  - Hysteresis: heater ON when temp < setpoint - 1.0, OFF when temp > setpoint + 1.0.
- Publishes `{"current_temp": float, "heat_output": bool, "setpoint": float, "timestamp": float}` to `ahu/temperature/status` every second.
- **Environment:** `MQTT_BROKER=mqtt-broker`.

### 4. InfluxDB (`influxdb`)

- **Image:** `influxdb:2.7`
- **Port:** `8086` (web UI and API).
- **Initialisation:** uses environment variables from `.env` to create an admin user, organisation (`ahu-lab`), bucket (`ahu-data`), and an API token.
- **Persistence:** volume `influxdb-data` mounted to `/var/lib/influxdb2`.

### 5. MQTT → InfluxDB Bridge (`mqtt-influx-bridge`)

- **Python script** using `paho-mqtt` and `influxdb-client`:
  - Subscribes to `ahu/#`.
  - On each message, parses the JSON payload and writes a point to InfluxDB with:
    - **Measurement:** extracted from the topic (e.g., `temperature` or `motor`).
    - **Fields:** all key/value pairs from the payload (except `timestamp`).
- **Environment:** `MQTT_BROKER`, `INFLUX_URL`, `INFLUX_TOKEN`, `INFLUX_ORG`, `INFLUX_BUCKET`.
- The token is read from `.env` (no hardcoded secrets in the script).

### 6. Grafana (`grafana`)

- **Image:** `grafana/grafana:10.4.5` (pinned version).
- **Port:** `3000` (web UI).
- **Persistence:** volume `grafana-data` for dashboards and datasource configuration.
- **Data source:** manually added as `http://influxdb:8086` with the same token.

---

## Setup Steps (in Order)

### 1. Prepare the `.env` File

Create `.env` in the `docker/` directory with:

```bash
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=MySecurePass123   # at least 8 characters
INFLUXDB_ORG=ahu-lab
INFLUXDB_BUCKET=ahu-data
INFLUXDB_TOKEN=ahu-token-123
```

Add `.env` to `.gitignore` (never commit secrets).

### 2. Start the MQTT Broker and Simulators

```bash
docker compose up -d mqtt-broker motor-simulator thermal-simulator
```

Check logs:

```bash
docker logs ahu-motor-sim --tail 5
docker logs ahu-thermal-sim --tail 5
```

Expected output: alternating status messages.

### 3. Start InfluxDB

```bash
docker compose up -d influxdb
sleep 15   # wait for initialisation
curl -s http://localhost:8086/health | grep -q "pass" && echo "OK" || echo "FAIL"
```

Verify the token and bucket:

```bash
docker exec ahu-influxdb influx bucket list --token ahu-token-123
```

You should see `ahu-data` among the buckets.

### 4. Start the MQTT → InfluxDB Bridge

```bash
docker compose up -d --build mqtt-influx-bridge
docker logs ahu-bridge --tail 10
```

Look for `Written: ahu/temperature/status -> ...`. If you see `401 Unauthorized`, check that the token in `.env` matches the actual InfluxDB token (re‑run the `influx setup` command if needed).

### 5. Verify Data in InfluxDB

```bash
docker exec ahu-influxdb influx query 'from(bucket:"ahu-data") |> range(start: -5m) |> limit(n: 1)' --token ahu-token-123
```

You should see a table with `current_temp`, `heat_output`, and `setpoint`.

### 6. Start Grafana

```bash
docker compose up -d grafana
```

Access the web UI at `http://<RPi-IP>:3000`. Default login: `admin` / `admin`. Change password.

### 7. Configure Grafana Data Source

1. **Configuration** → **Data Sources** → **Add data source** → **InfluxDB**.
2. Set:
   - Name: `AHU InfluxDB`
   - Query Language: `Flux`
   - URL: `http://influxdb:8086`
   - Organisation: `ahu-lab`
   - Token: `ahu-token-123`
   - Default bucket: `ahu-data`
3. Click **Save & Test** – you should see a green success message.

### 8. Build a Temperature Dashboard

1. **Create** → **Dashboard** → **Add visualization**.
2. Select the data source `AHU InfluxDB`.
3. Use the Flux query:

```flux
from(bucket: "ahu-data")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "temperature" and r._field == "current_temp")
```

4. Set refresh to `5s` and apply. You will see the hysteresis wave.

Add a second panel for `heat_output` using a state timeline.

---

## Wireshark Capture (Protocol Analysis)

### 1. Find the Docker Bridge Interface

```bash
docker network inspect docker_default | grep -i bridge.name
# or
ip link show | grep br-
```

Output example: `br-xxxxxxxxxxxx`.

### 2. Capture MQTT Traffic

```bash
sudo tcpdump -i br-xxxxxxxxxxxx -w mqtt_traffic.pcap
```

Let it run for 30–60 seconds while the simulators are publishing. Stop with `Ctrl+C`.

### 3. Transfer to Laptop and Analyse

```powershell
scp abdmoiz18@<RPi-IP>:~/mqtt_traffic.pcap .
```

Open in Wireshark, filter `mqtt.topic contains "temperature"`, expand a publish packet to see the JSON payload. Save a screenshot for documentation.

---

## Troubleshooting

| Error | Likely Cause | Fix |
|-------|--------------|-----|
| `401 Unauthorized` in bridge logs | Token mismatch or missing | Run `influx setup` manually inside the container or ensure `.env` token matches. |
| InfluxDB health check fails | Not enough time to initialise | Wait longer (20s) or check logs for errors. |
| Bridge shows `DeprecationWarning` | `mqtt.Client()` API version | Ignore – it still works. For a fix, use `mqtt.Client(client_id="")`. |
| Grafana “No data” | Wrong field name in query | Use `current_temp` (exact name from InfluxDB). |
| Permission denied to Docker socket | User not in `docker` group | Use `sudo` or add user to `docker` group and relog. |

---

## What This Demonstrates

- **Field device simulation** – Python scripts mimic DDC controllers.
- **Industrial protocol communication** – MQTT (lightweight, widely used in IoT/BAS).
- **Data historian** – InfluxDB stores time‑series data for trend analysis.
- **Visualisation** – Grafana dashboard showing live and historical temperature.
- **Protocol analysis** – Wireshark capture of MQTT traffic proves understanding of network communication.

This is the complete data pipeline of a building automation supervisory system, built with free and open‑source tools, running on a Raspberry Pi.

---

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Declares all services and their dependencies. |
| `.env` | Secrets (excluded from Git). |
| `mosquitto/config/mosquitto.conf` | Broker configuration. |
| `motor-simulator/` | Code for motor simulator. |
| `thermal-simulator/` | Code for thermal simulator. |
| `mqtt-influx-bridge/` | Bridge script and Dockerfile. |
| `scripts/startup.sh` | One‑command startup script with health checks. |

---

