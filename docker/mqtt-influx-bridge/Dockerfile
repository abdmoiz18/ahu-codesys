FROM python:3.11-slim
WORKDIR /app
COPY bridge.py .
RUN pip install paho-mqtt influxdb-client
CMD ["python", "bridge.py"]
