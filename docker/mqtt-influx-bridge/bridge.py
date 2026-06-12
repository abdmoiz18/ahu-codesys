import paho.mqtt.client as mqtt
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
import json
import os

MQTT_BROKER = os.getenv("MQTT_BROKER", "localhost")
INFLUX_URL = os.getenv("INFLUX_URL", "http://influxdb:8086")
INFLUX_TOKEN = "ahu-token-123"
INFLUX_ORG = "ahu-lab"
INFLUX_BUCKET = "ahu-data"

influx_client = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
write_api = influx_client.write_api(write_options=SYNCHRONOUS)

def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        topic_parts = msg.topic.split("/")
        measurement = topic_parts[1]   # e.g., "temperature" or "motor"
        point = Point(measurement)
        for key, value in payload.items():
            if key != "timestamp" and isinstance(value, (int, float, bool)):
                point = point.field(key, float(value))
        write_api.write(bucket=INFLUX_BUCKET, record=point)
        print(f"Written: {msg.topic} -> {payload}")
    except Exception as e:
        print(f"Error: {e}")

mqtt_client = mqtt.Client()
mqtt_client.on_message = on_message
mqtt_client.connect(MQTT_BROKER, 1883)
mqtt_client.subscribe("ahu/#")
mqtt_client.loop_forever()
