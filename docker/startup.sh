#!/bin/bash
set -e

echo "=== AHU Homelab Startup ==="
cd ~/ahu-codesys/docker

echo "Starting MQTT broker..."
sudo docker compose up -d mqtt-broker
sleep 5

# Health check: publish a test message and verify it's received
sudo docker exec ahu-mqtt mosquitto_pub -t test -m "health" || { echo "MQTT broker health check failed"; exit 1; }
echo "MQTT broker healthy"

echo "Starting simulators..."
sudo docker compose up -d motor-simulator thermal-simulator
sleep 3

echo "Starting InfluxDB..."
sudo docker compose up -d influxdb
sleep 10

# Check InfluxDB health (curl on host)
curl -s http://localhost:8086/health | grep -q "pass" || { echo "InfluxDB not ready"; exit 1; }
echo "InfluxDB healthy"

echo "Starting bridge and Grafana..."
sudo docker compose up -d mqtt-influx-bridge grafana
sleep 5

echo "All services running:"
sudo docker compose ps

echo "Grafana: http://$(hostname -I | awk '{print $1}'):3000 (admin/admin)"
