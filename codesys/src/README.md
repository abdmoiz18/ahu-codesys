# CODESYS Logic

This directory outlines CODESYS logic executed in the IEC 61131-3 languages of Strctured Text (ST) and Ladder Logic (LD). Ladder Logic has been provided with an OpenXML file as well as screenshots, whereas Structured Text (ST) has been added as-is.

## Overall Logic

### 1. Smoke Alarm Latch

The Smoke Alarm latch is active until manual reset. It calculates its next state for the next scan cycle based on whether smoke has been detected in the current scan cycle, and if the alarm has not been reset. It is a Moore State Machine.

Note that the reset is level-sensitive, not edge-triggered. This means that in practice, if the reset is implemented as a push button that turns off upon release, it won't be able to carry out its function if smoke is present. To fix this, add a Pulse/One-Shot upon Reset Input.

### 2. Motor Seal-in Logic and Motor Start Counter

First, the state of the Motor is calculated based on whether the motor has been started, and NOT been stopped, emergency stopped, or the entire system shut down. The Overload right after will override the motor's state in case of the alarm.

The conditions for the overload alarm require that the system has not yet been reset, and the overload has been tripped. If the system has been reset, the overload's value is also reset. 

The Motor Start Counter is implemented in LD using two function blocks, a Rising Edge Trigger (R_TRIG) to detect the Motor Output going from FALSE to TRUE, with the output of R_TRIG feeding into an incrementing counter (CTU) with a limit of 9999.

The Overload alarm acts as a Moore state machine, whereas the Motor's state acts as a Mealy state machine as it relies on two states and an input (emergency stop).

### 3. Temperature Hysteresis Logic

First, the temperature is simulated and validated before an actual on/off decision is made, hence why its rungs come first. The simulated temperature's value is then written to the actual temperature.

The temperature's upper and lower limits (hence its deadband) are constantly updated before its use in the Set and Reset coils. The RS Latch is implemented after the Set and Reset conditions are updated to decide whether to turn the heater on and off. 

The Smoke Safety Override comes last, in order to overwrite the heater coil and prevent other statements from writing into the coil. For the same reason, the Fan Proof timer comes after the Motor Seal-in logic, as it relies on the motor's state, overload, and emergency stop.

Both the Heat output and Fan fault alarm are Moore state machines. It's worth noting that the Smoke safety FSM is a Master that can override the Slave Heater FSM if the smoke alarm is active. Similarly, the Motor Seal-in FSM is also a Master that can override the Slave Fan Fault FSM.

### 4. Alarming Logic

Three alarms - Freeze, Smoke, and Overload, are gathered to one single flag in LD, SystemShutdown. The Freeze Alarm is a Moore state machine. 

The priority order of Freeze, Smoke, and Overload is implemented in LD by designing it as a Priority Encoder with NO and NC contacts and MOVE Function Blocks. The Priority Encoder decides which alarm text to display based on which alarm is active. 

The last few rungs are executed to voerride RS latches and seal-ins to shut down the entire system. Hence SystemShutdown resets MotorInternal, MotorOut, and HeatOutput.

---
