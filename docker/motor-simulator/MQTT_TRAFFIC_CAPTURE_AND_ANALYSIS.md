# MQTT Traffic Capture & Analysis - Motor Simulator

This document described how I captured and analyzed MQTT traffic from the motor simulator (Python script publishing to '`ahu/motor/status`) using `dumpcap` on a Raspberry Pi, trasnferred the capture (.pcap file) to Windows, and examined it in Wireshark.

## Why use `dumpcap` instead of `tshark`?

- **`dumpcap`** is the dedicated capture engine of the Wireshark suite. It only captures raw packets and writes them to a file - nothing else.

- **`tshark`** is a command-line protocol analyzer; for capture-only tasks it simply calls `dumpcap` in the background.

- Using `dumpcap` directly is more efficient on a resource-constrained Raspberry Pi (lower CPU/memory usage) and reduces the risk of packet drops.

- It follows the principle of **least privilege**: only the minimal part of the tool needs elevated permissions, and the captured file can be analyzed later on a desktop machine with the full Wireshark GUI.

## Step-by-Step Capture Process

### 1. Install Wireshark/ `dumpcap` on the Raspberry Pi

```bash
sudo apt update && sudo apt install wireshark -y
sudo dpkg-reconfigure wireshark-common   # allow non‑root users to capture
sudo usermod -aG wireshark $USER
```

Log out and back in (or reconnect SSH) for group changes to take effect.

### 2. Identify the Docker Bridge Interface

The MQTT broker and motor simulator run on a Docker network. Find the bridge interface name:

```bash
docker network ls
docker network inspect docker_default | grep -i com.docker.network.bridge.name
```

If no name appears, use `brctl show` or `ip link` to locate the bridge (often `br-<network-id>`). In my case, it was br-73be2526da2b. Made sure the Docker container is already running.

### 3. Start the Capture with `dumpcap`

Launch the capture before starting the Python simulator to capture the TCP handshake:

```bash
dumpcap -i br-73be2526da2b -f "port 1883" -a duration:30 -w mqtt_capture.pcap
```

- -i - interface

- -f "port 1883" - capture filter (only MQTT traffic)

- -a duration:30 - stop after 30 seconds (optional, use Ctrl+C to stop whenever you want)

- -w - output file

### 4. Run the Motor Simulator

In another terminal, start the simulator (either directly or via Docker Compose). The capture will record all subsequent MQTT messages.

### 5. Transfer the .pcap file to Windows

From Windows Powershell, use `scp`:

```powershell
scp abdmoiz18@192.168.x.x:~/mqtt_capture.pcap .
```

(Replace the IP address with your Raspberry Pi's actual address)

### 6. Analyze in Wireshark Desktop

- Open `Wireshark -> File -> Open ->` select the .pcap file.

- Apply display filters: `mqtt.msgtype == 3` to see only publish messages, or `mqtt` to see all the MQTT Packets.

## Observations from the Capture 

| **Screenshot** | **Description** |
|----------------|-----------------|
| ![**Packet 1** (first captured publish)](/home/abdmoiz18/ahu-codesys/docker/motor-simulator/wireshark_screenshots/Screenshot 2026-06-03 175019.png) | Shows `MotorOut: true`. Capture started after script had already run for a few seconds. |
| ![**Packet 41** (first toggle after publish began)](/home/abdmoiz18/ahu-codesys/docker/motor-simulator/wireshark_screenshots/Screenshot 2026-06-03 175030.png) | `MotorOut: false`. The time gap between Packet 1 and Packet 41 is ~9 seconds, not exactly 10, because the first packet was not the very first publish. |
| ![**Packet 85** (second toggle)](/home/abdmoiz18/ahu-codesys/docker/motor-simulator/wireshark_screenshots/Screenshot 2026-06-03 175042.png) | `MotorOut: true`. Time difference between Packet 41 and Packet 85 is 10.0099 seconds, the correct periodic alternation. |
| ![**MQTT/TCP ACK alternation**](/home/abdmoiz18/ahu-codesys/docker/motor-simulator/wireshark_screenshots/Screenshot 2026-06-03 175703.png) | Shows that after each MQTT publish packet, the broker responds with a pure TCP ACK (Len:0). This is normal TCP behaviour and confirms reliable delivery. |

### Missing TCP Three-Way Handshake

The SYN, SYN-ACK, ACK packets (which establish the TCP connection) are not present in the capture. This is because I started `dumpcap` after the Python simulator (`motor_simulator.py`) had already connected to the MQTT broker. The handshake occurred before the capture began. 

The first packet recorded is an MQTT publish, not the SYN. This does not indicate a problem, it simply means the capture was started late. To capture the full conversation, one would need to start `dumpcap` first, then launch the simulator. The later packets (Packet 41 -> Packet 85) still demonstrate correct periodic behaviour.

## Conclusion

- The motor simulator correctly publishes alternating `MotorOut` values every 10 seconds.

- MQTT over TCP works as expected (publish messages followed by TCP ACKs).

- The capture file, despite missing the handshake, is sufficient to prove the system's functionality.

- Using `dumpcap` on the RPi and analyzing on Windows is an efficient and reliable workflow.

For future captures, start `dumpcap` before the client to record the entire TCP handshake and the very first packet.

## Files

- `mqtt_capture.pcap` - raw packet capture.

- `wireshark_screenshots` - folder containing the four screenshots.
