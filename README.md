# AHU Industrial Automation Lab  
**CODESYS + MQTT + InfluxDB + Grafana**

This repository is an industrial automation portfolio project that simulates core **Air Handling Unit (AHU)** control and supervisory telemetry behavior.

It demonstrates:
- PLC control development in **CODESYS** (Structured Text + Ladder Diagram)
- Field-device simulation and messaging via **Python + MQTT**
- Time-series ingestion and visualization using **InfluxDB + Grafana**
- Alarm-oriented control design including **Freeze Alarm**, **Smoke Alarm**, **Fan Proof**, and **alarm priority handling**

---

## Project Highlights

### PLC Control Logic (CODESYS)
- Motor start/stop seal-in logic
- Overload latch and reset handling
- Emergency stop override
- **Smoke alarm latch** with manual reset
- **Freeze Alarm** logic (latched when `CurrentTemp < 5.0°C`)
- **Motor Start Counter (Structured Text)** using rising-edge detection and CTU
- Fan proof timeout detection using TON timer
- **Alarm text prioritization** (Freeze > Smoke > Overload > Normal)
- **Safety override** that shuts down outputs on Smoke, Freeze, or E-Stop

### Ladder Diagram Safety/Alarm Layer
- Freeze alarm integration in LD
- Smoke alarm and fan fault alarm handling
- Overload alarm handling
- **Alarm Priority Logic in LD** to enforce deterministic alarm behavior when multiple alarms are active

### OT Telemetry Pipeline
- Python simulators publish AHU-like process values/status to MQTT
- MQTT broker (Mosquitto) as central message bus
- MQTT-to-InfluxDB bridge for historical storage
- Grafana dashboards for live and trend visualization

---

## Why this project is relevant

This project is designed to showcase practical skills expected in controls/automation and OT-integrated roles:

- PLC programming (ST + LD)
- Safety/interlock and alarm design
- Field telemetry simulation
- Industrial protocol workflow validation
- Data-driven supervisory monitoring integration

---

## Architecture Overview

1. **Control Layer:** CODESYS runtime executes AHU logic (motor, freeze protection, smoke safety, fan proof, alarm priority, and safety overrides).
2. **Field Simulation Layer:** Python-based simulators emulate AHU device signals.
3. **Messaging Layer:** MQTT transports telemetry/events.
4. **Data Layer:** InfluxDB stores time-series data.
5. **Visualization Layer:** Grafana displays system behavior and alarm trends.

---

## Tech Stack

- **PLC/Automation:** CODESYS (Structured Text, Ladder Diagram)
- **Messaging:** Eclipse Mosquitto (MQTT)
- **Data Historian:** InfluxDB 2.x
- **Visualization:** Grafana
- **Simulation/Glue:** Python (`paho-mqtt`, `influxdb-client`)
- **Runtime/Orchestration:** Docker Compose, Shell scripts
- **Platform:** Raspberry Pi + Linux environment

---

## New Additions (Current Revision)

- ✅ **Freeze Alarm** added to control logic and integrated into alarm behavior  
- ✅ **Motor Start Counter (ST)** added for operational event tracking  
- ✅ **Alarm Priority in ST/LD** implemented to prioritize alarm outcomes consistently during concurrent conditions  
- ✅ **Safety override** enforces shutdown when any critical safety condition is active (`SmokeAlarmMem OR FreezeAlarmMem OR EStop`)

---

## Control & Alarm Priority (from `PLC_PRG.st`)

Priority order:
1. **FREEZE PROTECTION - SYSTEM SHUTDOWN**
2. **SMOKE ALARM - SYSTEM SHUTDOWN**
3. **OVERLOAD TRIPPED - MOTOR OFF**
4. **NORMAL OPERATION**

Safety shutdown action (if Freeze OR Smoke OR E-Stop):
- `MotorInternal := FALSE`
- `MotorOut := FALSE`
- `HeatOutput := FALSE`

---

## Quick Start (Docker Telemetry Stack)

```bash
cd docker
cp .env.example .env   # create manually if not yet present
docker compose up -d
```

Access:
- Grafana: `http://localhost:3000`
- InfluxDB: `http://localhost:8086`
- MQTT Broker: `localhost:1883`

> For Raspberry Pi deployment, replace `localhost` with `<RPi-IP>`.

---

## Validation & Engineering Evidence

This repository includes commissioning-style evidence and test-focused documentation, such as:
- Motor control commissioning logs
- Fan proof verification scenarios
- Smoke/freeze/safety interlock documentation
- MQTT protocol capture and analysis (Wireshark/dumpcap)
- Troubleshooting retrospectives and implementation notes

---

## Repository Structure (High-Level)

```text
codesys/        # PLC logic, LD/ST modules, commissioning docs
docker/         # Compose stack, service Dockerfiles, startup tooling
scripts/        # Python simulators and integration scripts
docs/           # Architecture, setup, validation, troubleshooting
```

---

## Engineering Notes

- This is a homelab/portfolio simulation, not a production-certified BAS deployment.
- Security and hardening are intentionally simplified for development and demonstration.
- The focus is on control correctness, alarm behavior, integration clarity, and technical documentation quality.

---

