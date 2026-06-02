import paho.mqtt.client as mqtt
import time
import json

import os
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
