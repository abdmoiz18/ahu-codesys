# AHU Industrial Automation Lab  

This is a GitHub repository to simulate the control system for an Air Handling Unit (AHU) of a medium size building. The Codesys section consists of Motor Seal-in logic, Temperature Hysteresis logic, Freeze Protection, Smoke Alarm Latch, Motor Start Counter, Fan Proof Check, Combined Safety Alarm override, all written and implemented in both Strctured Text (ST) and Ladder Logic (LD).

This system was designed for a medium-size mission-critical facility such as a hospital wing, pharmaceutical cleanroom, financial trading floor, etc, where uninterrupted operation is not just a convenience but a necessity and any failure carries critical consequences to life safety, product quality, data integrity, or finances.

The Air Handling Unit (AHU) itself is a variable-air volume (VAV) serving a single critical zone. It includes a supply fan with a proof-of-flow sensor, an on/off heating coil, and a smoke detector. It is controlled by a Programmable Logic Controller (PLC) that executes ST or LD logic, ordered to prioritise safety and energy efficiency.

## PLC Logic

The motor control logic is a 3-wire start/stop with a seal-in, overload protection, and an emergency stop that overrides all other commands. It also has a Motor Start Counter logic to track the number of times the motor has been started, a feature used by facilities teams for predictive maintainence, tracking wear and tear, and scheduling of a replacement.

The temperature control loop implements hysteresis rather than a full PID, preferable in this scenario for simplicity, reliability, and immunity to tuning drift. The deadband ensures stable temperature control without excessive actuator cycling to prevent wearing out the heating coil and control valve.

The safety system has three hazard classes - Smoke, Freeze, and Overload. Freeze Protection carries the highest priority to prevent rupturing of the coil, which may cause catastrophic water damage. Smoke detection comes next, triggering an immediate system shutdown and requiring a manual reset as per fire codes. Overload protection comes last, preventing motor damage. The alarm text logic provides clear, human-readable status to the operator.

The fan proof timer is an interlock, where a fan must prove airflow within five seconds of being commanded to run, otherwise a fault alarm is generated. This is to prevent the heating coil to operate without airflow, which is a common cause of overheating and fire.

## Ignition SCADA Addition (under development)

The system is designed to be operated by a modern SCADA interface (Ignition) to replace the manual forcing of variables during development. The OPC UA connection provides secure, standarised communication between the PLC and the HMI, and the alarm summary and the trend historian gives operators the tools they need to monitor, diagnose, and respond to events.

Until then, the supervisory layer was simulated using open-source tools (Docker, Python, InfluxDB, MQTT, Grafana) to provide a clear understanding of the data pipeline. A Python script simulates the thermal behaviour of the AHU (temperature hysteresis) and sends these values to the MQTT broker every second. An MQTT-to-InfluxDB bridge writes these messages with a time-series database. Grafana is then used to visualise temperature on a live dashboard.

Update: Ignition is now under development. Ignition Perspective is in use, with HMIs being developed. Currently, OPC-UA has been correctly established after a troubleshooting log (shown in the Ignition repo), the HMI has been designed using a Coordinate Container, Flex Containers, Toggle Switches, Labels, and Text Boxes. The current stage is about the validation of tag binding and bidirectional read/writes. After this, alarms will be set up and the entire system will be commissioned.
