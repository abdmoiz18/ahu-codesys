import paho.mqtt.client as mqtt
import time
import json
import os

broker = os.getenv("MQTT_BROKER", "localhost")
client = mqtt.Client()
client.connect(broker, 1883)

current_temp = 20.0
setpoint = 22.0
heat_output = False
heat_on_rate = 0.5
cool_rate = 0.3

while True:
    if current_temp < setpoint - 1.0:
        heat_output = True
    elif current_temp > setpoint + 1.0:
        heat_output = False
    
    if heat_output:
        current_temp += heat_on_rate / 60
    else:
        current_temp -= cool_rate / 60
    
    payload = {
        "current_temp": round(current_temp, 2),
        "setpoint": setpoint,
        "heat_output": heat_output,
        "timestamp": int(time.time()),
    }

    client.publish("ahu/temperature/status", json.dumps(payload))
    print(f"Temperature: {current_temp:.2f} C, Heat Output: {'ON' if heat_output else 'OFF'}")
    time.sleep(1)

