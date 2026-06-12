# AHU Homelab – Building Automation Control System Simulation

This repository documents a hands‑on homelab project that simulates the core control logic of an Air Handling Unit (AHU). The project is split into two parallel tracks:

1. **PLC & HMI** – CODESYS on a Raspberry Pi, Structured Text motor control, WebVisu operator interface.
2. **Networking & Simulation** – Docker, Python, MQTT, Wireshark to simulate field devices and analyse industrial communication.

The goal is to build a foundation in **Building Automation Systems (BAS)** while strengthening **industrial networking** and **OT/IT integration** skills.

---

## Project Aims

- ✅ Develop a working motor control system (start/stop, overload latch, emergency stop) in CODESYS Structured Text.
- ✅ Create a web‑based HMI (WebVisu) to interact with the PLC logic.
- ✅ Simulate a field device (motor) publishing MQTT data to a broker, mimicking a DDC controller in a BAS network.
- ✅ Capture and analyse MQTT traffic using Wireshark, demonstrating protocol analysis skills.
- ✅ Document the entire system with professional commissioning logs, architecture diagrams, and troubleshooting retrospectives.
- ✅ Provide a reusable, containerised simulation stack (Docker Compose) for future extensions.

---

## What This Project Covers

| Area | Implemented Features |
|------|----------------------|
| **PLC Logic** | Motor seal‑in (latching), overload latch with reset, emergency stop override, status lamps. |
| **HMI** | WebVisu buttons (Start, Stop, Overload, Reset, E‑Stop) and indicator lamps (Motor running, Overload alarm). |
| **Communication** | MQTT publication from a Python simulator to an Eclipse Mosquitto broker (containerised). |
| **Network Analysis** | Wireshark capture of MQTT packets, payload inspection (JSON), TCP ACK behaviour. |
| **Documentation** | Points list, commissioning test log, WebVisu troubleshooting log, system architecture diagram (partial). |
| **Infrastructure** | Docker Compose stack for MQTT broker + Python simulator, Bash startup script, GitHub version control. |

---

## What This Project Does NOT Cover

The following are **explicitly out of scope** for the current version. They may be added in future iterations.

- ❌ **Full PID temperature control** – only on/off hysteresis is simulated (not yet implemented).
- ❌ **BACnet or OPC UA** – only MQTT and Modbus TCP (optional) are used.
- ❌ **Physical I/O** – no real sensors or actuators; everything is simulated.
- ❌ **Redundant PLC or safety PLC** – single runtime, no SIL considerations.
- ❌ **Advanced scheduling** (weekly calendar, holiday exceptions) – only manual on/off.
- ❌ **Alarm prioritisation and history** – only basic alarm lamps.
- ❌ **Trend logging and reporting** – not yet integrated (InfluxDB/Grafana planned).
- ❌ **OT network segmentation with pfSense** – planned but not yet implemented.
- ❌ **Node‑RED or SCADA integration** – WebVisu is the primary HMI.

---

## Simulated AHU Aspects

The following AHU functions are **simulated** (not physically wired) using software:

| Simulated Component | Implementation |
|---------------------|----------------|
| **Motor start/stop** | Seal‑in logic in CODESYS ST, controlled via WebVisu or MQTT. |
| **Overload relay** | Latching Boolean variable `OverloadMem` triggered by `OverloadTrip` command. |
| **Emergency stop** | `EStop` variable that overrides motor output and seal‑in. |
| **Field device communication** | Python script publishing `MotorOut` status to MQTT every second. |
| **BAS network** | MQTT broker (Mosquitto) acting as the data concentrator. |

---

## NOT Simulated AHU Aspects (That Could Be Simulated in CODESYS)

The following are **real AHU features** that are **not** part of this project, but could be added in later phases:

- ❌ **Variable speed fan (VFD)** – 0‑100% speed control via analog output.
- ❌ **Temperature control with PID** – closed‑loop regulation with setpoint and deadband.
- ❌ **Pressure differential monitoring** – filter clog detection.
- ❌ **Heating/cooling valve control** – 0‑100% valve position with feedback.
- ❌ **Mixed air damper control** – economizer logic.
- ❌ **Occupancy schedule** – time‑of‑day setpoint switching.
- ❌ **BMS integration** – BACnet/IP server exposing points.
- ❌ **Alarm history and acknowledgement** – ISA‑18.2 style.
- ❌ **Energy metering** – kWh accumulation.

These are intentionally omitted to keep the project focused on the core motor control, MQTT simulation, and networking analysis.

---

