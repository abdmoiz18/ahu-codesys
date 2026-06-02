FROM python:3.11-slim
WORKDIR /app
COPY motor_simulator.py .
RUN pip install paho-mqtt
CMD ["python", "motor_simulator.py"]
