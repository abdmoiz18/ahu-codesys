# AHU Industrial Automation Lab  
**CODESYS + MQTT + InfluxDB + Grafana + Python Simulation**

This project is an industrial automation portfolio lab that simulates core **Air Handling Unit (AHU)** control behavior and OT telemetry flow.

It demonstrates:
- PLC control logic implementation in **CODESYS** (ST/LD)
- Simulated field device telemetry via **MQTT**
- Time-series ingestion into **InfluxDB**
- Real-time visualization in **Grafana**
- Engineering validation through commissioning-style tests and packet analysis

---

## Why this project is relevant

This repository is built to showcase practical skills for industrial automation and controls roles:
- Control logic design (latching, interlocks, fail-safe behavior)
- BAS-style data flow from controller/simulator to supervisory monitoring
- OT/IT integration using lightweight industrial messaging
- Structured testing, troubleshooting, and technical documentation

---

## System Architecture

**Control Layer**
- CODESYS runtime on Raspberry Pi
- Motor control, alarm latching, safety interlocks, thermal/smoke-related logic

**Telemetry Layer**
- Python simulators publish AHU-like process values/status to MQTT topics
- MQTT broker (Mosquitto) acts as central message bus

**Data & Visualization Layer**
- MQTT-to-InfluxDB bridge writes topic payloads as time-series points
- Grafana dashboards display live and historical behavior

---

## Tech Stack

- **PLC/Automation:** CODESYS (Structured Text + Ladder)
- **Messaging:** Eclipse Mosquitto (MQTT)
- **Data Historian:** InfluxDB 2.x
- **Visualization:** Grafana
- **Simulation & Integration:** Python (`paho-mqtt`, `influxdb-client`)
- **Environment:** Docker Compose, Raspberry Pi, Linux shell tooling
- **Validation:** Wireshark / dumpcap packet capture analysis

---

## Key Implementations

- Motor seal-in logic with stop, overload trip, and reset handling
- Fan proof monitoring with TON-based timeout fault detection
- Smoke safety interlock with latched alarm and manual reset
- Thermal simulation with hysteresis-like control behavior
- End-to-end MQTT → InfluxDB → Grafana telemetry pipeline
- Startup automation and health-check flow for containerized services

---

## Quick Start (Docker Pipeline)

```bash
cd docker
cp .env.example .env   # if not present, create .env manually
docker compose up -d
```

Then access:
- Grafana: `http://localhost:3000`
- InfluxDB: `http://localhost:8086`
- MQTT broker: `localhost:1883`

> For Raspberry Pi deployment, replace `localhost` with `<RPi-IP>` where applicable.

---

## Repository Structure (High-Level)

```text
codesys/                  # PLC logic, control modules, commissioning docs
docker/                   # Compose stack, service Dockerfiles, startup script
scripts/                  # Python simulators and integration scripts
docs/                     # Architecture, setup, validation, troubleshooting
```

---

## Validation Evidence

This project includes engineering-style evidence, not just source code:
- Commissioning test logs for motor control behavior
- Fan proof logic test scenarios and expected outcomes
- Smoke safety interlock verification workflow
- MQTT traffic capture and protocol-level analysis (Wireshark/dumpcap)

---

## Engineering Notes

- Designed as a **portfolio proof-of-concept**, not production BAS deployment
- Security/auth hardening is intentionally minimal in homelab mode and should be strengthened for production use
- Focus is on control behavior, telemetry reliability, and integration clarity

---

