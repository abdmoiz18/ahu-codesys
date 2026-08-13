# Commissioning of the CODESYS System

## 1. Motor Seal-in - Start, Stop, Restart, Overload Trip, Emergency Stop

- Start the system
- Force StartCmd TRUE (expected MotorInternal = TRUE, MotorOut = TRUE)
- Force StartCmd FALSE (expected outputs above to retain their state)
- Observe MotorStartCount (expected increment to 1)

- Reset StartCmd and force StopCmd TRUE (expected MotorInternal = FALSE, MotorOut = FALSE)
- Force StartCmd TRUE (Motor runs again)
- Observe MotorStartCount (expected increment to 2)

- Press OverloadTrip while Motor is running (expected OverloadMem TRUE, OverloadAlarm TRUE, MotorOut FALSE, Alarm Text - "OVERLOAD TRIPPED - Motor Off")
- Force StartCmd TRUE (Motor does not start, MotorOut remains FALSE)
- Press ResetCmd (expected OverloadMem and OverloadAlarm FALSE)
- Force StartCmd (normal operation)

- Press EStop while motor runs (expected MotorOut FALSE, Alarm Text still shows "NORMAL OPERATION" as it is hardware safety, not an alarm)
- Release EStop and press StartCmd (normal operation)

## 2. Smoke Alarm - Latch, Safety Override, Alarm Priority

- Press SmokeDetected while motor runs (expected SmokeAlarmMem and SmokeAlarm TRUE, MotorOut and HeatOutput FALSE, Alarm Text = "SMOKE ALARM - SYSTEM SHUTDOWN")
- Release SmokeDetected and restart motor (Alarm stays latched and motor dosen't restart)
- Press ResetSmoke and restart motor (SmokeAlarmMem and SmokeAlarm FALSE, motor starts normally)

## 3. Freeze Protection - Latch, Override, Priority

- While Motor and Heating runs, force temp to 4 C (epxected FreezeAlarmMem and FreezeAlarm TRUE, MotorOut and HeatOutput FALSE, Alarm Text - "FREEZE PROTECTION - SYSTEM SHUTDOWN")
- Force CurrentTemp back and restart motor (alarm stays latched and motor dosen't restart)
- Force FreezeAlarmMem FALSE and restart motor (normal operation)

## 4. Fan Proof Timer

- While motor runs, force FanProofSignal FALSE (expected FanProofTimer to start counting and for FanProofTimer.Q and FanFaultAlarm TRUE after 5+ seconds)
- Force FanProofSignal TRUE (FanProofTimer resets and FanFaultAlarm remains TRUE, latched)

## 5. Temperature Hysteresis

- Observe SimTemp while motor and heating are on (expected temperature rise and fall at the given rate, HeatOutput FALSE when temperature exceeds deadband, HeatOutput TRUE when temperature falls below deadband)

## 6. Combined Alarm Integration

- While motor runs, trigger overload (expected Alarm Text - "OVERLOAD TRIPPED - MOTOR OFF")
- Trigger smoke (Alarm text - "SMOKE ALARM - SYSTEM SHUTDOWN")
- Trigger freeze (Alarm text - "FREEZE PROTECTION - SYSTEM SHUTDOWN")
- Reset smoke and freeze (Overload alarm text)
- Reset overload (Alarm text - "NORMAL OPERATION")
- Observe MotorStartCount (must not increment)

---
