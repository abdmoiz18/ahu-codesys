# Commissioning of the CODESYS System

## 1. Motor Seal-in - Start, Stop, Restart, Overload Trip, Emergency Stop

- Start the system
- Press StartCmd TRUE (expected MotorInternal = TRUE, MotorOut = TRUE)
- Press StartCmd FALSE (expected outputs above to retain their state)
- Observe MotorStartCount (expected increment to 1)

- Reset StartCmd and force StopCmd TRUE (expected MotorInternal = FALSE, MotorOut = FALSE)
- Press StartCmd TRUE (Motor runs again)
- Observe MotorStartCount (expected increment to 2)

- Press OverloadTrip while Motor is running (expected OverloadMem TRUE, OverloadAlarm TRUE, MotorOut FALSE, Alarm Text - "OVERLOAD TRIPPED - Motor Off")
- Press StartCmd TRUE (Motor does not start, MotorOut remains FALSE)
- Press ResetCmd (expected OverloadMem and OverloadAlarm FALSE)
- Press StartCmd (normal operation)

- Press EStop while motor runs (expected MotorOut FALSE, Alarm Text still shows "NORMAL OPERATION" as it is hardware safety, not an alarm)
- Release EStop and press StartCmd (normal operation)

Ignition: MotorOut LED reflects state, OverloadAlarm appears in Alarm Status Table when triggered.

## 2. Smoke Alarm - Latch, Safety Override, Alarm Priority

- Press SmokeDetected while motor runs (expected SmokeAlarmMem and SmokeAlarm TRUE, MotorOut and HeatOutput FALSE, Alarm Text = "SMOKE ALARM - SYSTEM SHUTDOWN")
- Release SmokeDetected and restart motor (Alarm stays latched and motor dosen't restart)
- Press ResetSmoke and restart motor (SmokeAlarmMem and SmokeAlarm FALSE, motor starts normally)

Ignition: SmokeAlarm appears in Alarm Status Table with Critical priority and correct Display Path, LED turns red.

## 3. Freeze Protection - Latch, Override, Priority

- While Motor and Heating runs, force temp to 4 C (epxected FreezeAlarmMem and FreezeAlarm TRUE, MotorOut and HeatOutput FALSE, Alarm Text - "FREEZE PROTECTION - SYSTEM SHUTDOWN")
- Press CurrentTemp back and restart motor (alarm stays latched and motor dosen't restart)
- Press FreezeAlarmMem FALSE and restart motor (normal operation)

Ignition: FreezeAlarm appears in Alarm Status Table with Critical priority, this alarm takes highest priority in HMI.

## 4. Fan Proof Timer

- While motor runs, force FanProofSignal FALSE (expected FanProofTimer to start counting and for FanProofTimer.Q and FanFaultAlarm TRUE after 5+ seconds)
- Press FanProofSignal TRUE (FanProofTimer resets and FanFaultAlarm remains TRUE, latched)

Ignition: FanFaultAlarm appears in Alarm Status Table; Fan Status LED updates.

## 5. Temperature Hysteresis

- Observe SimTemp while motor and heating are on (expected temperature rise and fall at the given rate, HeatOutput FALSE when temperature exceeds deadband, HeatOutput TRUE when temperature falls below deadband)

Ignition: Temperature trend appears in Power Chart; HeatOutput LED reflects state.

## 6. Combined Alarm Integration

- While motor runs, trigger overload (expected Alarm Text - "OVERLOAD TRIPPED - MOTOR OFF")
- Trigger smoke (Alarm text - "SMOKE ALARM - SYSTEM SHUTDOWN")
- Trigger freeze (Alarm text - "FREEZE PROTECTION - SYSTEM SHUTDOWN")
- Reset smoke and freeze (Overload alarm text)
- Reset overload (Alarm text - "NORMAL OPERATION")
- Observe MotorStartCount (must not increment)

Ignition: Alarm Status Table shows correct active alarms; priority order verified in HMI.

---
