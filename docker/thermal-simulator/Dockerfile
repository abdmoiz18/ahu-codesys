FROM python:3.11-slim
WORKDIR /app
COPY thermal_simulator.py .
RUN pip install paho-mqtt
CMD ["python", "thermal_simulator.py"]

