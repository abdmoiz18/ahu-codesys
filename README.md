# AHU Industrial Automation Lab  

This is a GitHub repository to simulate the control system for an Air Handling Unit (AHU) of a medium size facility. The Codesys section consists of Motor Seal-in logic, Temperature Hysteresis logic, Freeze Protection, Smoke Alarm Latch, Motor Start Counter, Fan Proof Check, Combined Safety Alarm override, all written and implemented in both Strctured Text (ST) and Ladder Logic (LD).

The simulation demonstrates fail-safe interlocking, robust industry-standard algorithms and control logic patterns used in commercial HVAC systems. However, in the end, it is still intended to be nothing more than a simplified single PLC simulation for educational purposes. Real-world deployments in mission-critical facilities such as in hospitals and pharmaceutical cleanrooms would require additional redundanacy, automatic failover, hardware voting, and comprehensive risk assesssment, all of which are beyond the scope of this repository. 

The Air Handling Unit (AHU) itself is a variable-air volume (VAV) serving a single critical zone. It includes a supply fan with a proof-of-flow sensor, an on/off heating coil, and a smoke detector. It is controlled by a Programmable Logic Controller (PLC) that executes ST or LD logic, ordered to prioritise safety and energy efficiency.

## PLC Logic

The motor control logic is a 3-wire start/stop with a seal-in, overload protection, and an emergency stop that overrides all other commands. It also has a Motor Start Counter logic to track the number of times the motor has been started, a feature used by facilities teams for predictive maintainence, tracking wear and tear, and scheduling of a replacement.

The temperature control loop implements hysteresis rather than a full PID, preferable in this scenario for simplicity, reliability, and immunity to tuning drift. The deadband ensures stable temperature control without excessive actuator cycling to prevent wearing out the heating coil and control valve.

The safety system has three hazard classes - Smoke, Freeze, and Overload. Freeze Protection carries the highest priority to prevent rupturing of the coil, which may cause catastrophic water damage. Smoke detection comes next, triggering an immediate system shutdown and requiring a manual reset as per fire codes. Overload protection comes last, preventing motor damage. The alarm text logic provides clear, human-readable status to the operator.

The fan proof timer is an interlock, where a fan must prove airflow within five seconds of being commanded to run, otherwise a fault alarm is generated. This is to prevent the heating coil to operate without airflow, which is a common cause of overheating and fire.

## Ignition Perspective

The system is designed to be operated by a modern SCADA interface (Ignition) to replace the manual forcing of variables during development. The OPC UA connection provides secure, standarised communication between the PLC and the HMI, and the alarm summary and the trend historian gives operators the tools they need to monitor, diagnose, and respond to events.

This is achieved with the use of Ignition Perspective. Currently, OPC-UA has been correctly established after a troubleshooting log (shown in the Ignition repo), give HMI screens has been designed using a Coordinate Container, Flex Containers, Toggle Switches, Labels, Text Boxes, etc. Tag Binding and Bidirectional Read/Write between CODESYS and Ignition has been implemented and validated after removing Modbus Register Mapping in the Motor GVL to avoid conflict between Modbus and OPC UA communication. 

Every HMI screen was made using a Coordinate Container as the background and Flex containers for smaller spaces.

The Overview HMI contains important status indicators, an alarm status table, and four buttons to navigate to the other four HMIs. The navigations buttons were configured using an onClick event which runs a script to navigate to the HMI. Four alarms were configured - Freeze Alarm and Smoke Alarm were given critical priority, and Fan Fault Alarm and Motor Overload Alarm were given high priority. The Alarm Journal HMI displays historical alarm data.

The Motor HMI, Temperature HMI, and Fan Smoke HMI all use Toggle switches (tag binding to its status) for Boolean inputs, Labels (tag binding to background colour) for Boolean outputs, and a 14 segment display for numeric outputs. 

The Temperature HMI also has a Power Chart to display historical tag data for Current Temperature, with tag data stored in a Core Historian which is powered by QuestDB.

Before Ignition, the supervisory layer was simulated using open-source tools (Docker, Python, InfluxDB, MQTT, Grafana) to provide a clear understanding of the data pipeline. A Python script simulates the thermal behaviour of the AHU (temperature hysteresis) and sends these values to the MQTT broker every second. An MQTT-to-InfluxDB bridge writes these messages with a time-series database. Grafana is then used to visualise temperature on a live dashboard. This provides an opportunity for comparative analysis later ahead.

---

