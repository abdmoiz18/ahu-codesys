```markdown
# Fan Status Proof Logic – CODESYS Implementation

## Project Overview
This module implements fan status monitoring with a **TON (Timer On-Delay)** to detect fan failure. When the motor is commanded to run (`MotorOut = TRUE`) but the fan proof signal (`FanProofSignal`) does not arrive within 5 seconds, a `FanFaultAlarm` is latched.

This implementation is based on the original Structured Text logic:
```pascal
FanProofTimer(IN := MotorOut AND NOT FanProofSignal, PT := T#5S);
IF FanProofTimer.Q THEN
    FanFaultAlarm := TRUE;
END_IF
```

---

Variables Declared (in GVL_Fan)

```pascal
VAR_GLOBAL
    FanProofTimer : TON;      (* TON instance for fan proof check *)
    FanProofSignal : BOOL;    (* Simulated feedback from fan *)
    FanFaultAlarm : BOOL;     (* Alarm output (latched) *)
END_VAR
```

---

Ladder Logic Implementation

Rung 16 – Main Fan Proof Timer

The timer starts when MotorOut is TRUE but FanProofSignal is FALSE. After 5 seconds, Q becomes TRUE.

```
   GVL.MotorOut   GVL_Fan.FanProofSignal             GVL_Fan.FanProofTimer
-------| |------------|/|-----------------------------------[ TON ]---
                                                              PT := T#5s
```

Rung 17 – Latch Fan Fault Alarm

When the timer expires (Q = TRUE), the alarm is set and remains latched.

```
   GVL_Fan.FanProofTimer.Q                        GVL_Fan.FanFaultAlarm
-------| |-----------------------------------------------( S )---
```

---

Testing Guide

Variables to Monitor / Force

Variable Type Purpose
GVL.StartCmd BOOL Start the motor (force TRUE momentarily)
GVL.MotorOut BOOL Verify motor is commanded (read-only)
GVL_Fan.FanProofSignal BOOL Simulate fan proof (forceable)
GVL_Fan.FanProofTimer.ET TIME Elapsed time (read-only)
GVL_Fan.FanProofTimer.Q BOOL Timer output (read-only)
GVL_Fan.FanFaultAlarm BOOL Latch alarm (force for reset if no reset rung)

---

Test Scenarios

✅ Test 1: Normal Start (Proof Arrives in Time)

Goal: Verify no alarm when proof signal arrives within 5 seconds.

Step Action Observation
1 Force GVL.StartCmd = TRUE (momentary) GVL.MotorOut becomes TRUE
2 Watch FanProofTimer.ET Timer counts from 0s toward 5s
3 Within 5s, force FanProofSignal = TRUE Timer resets to 0
4 Check FanFaultAlarm Remains FALSE

✅ PASS – Timer resets, no fault.

---

❌ Test 2: Fault Start (No Proof Arrives)

Goal: Verify alarm triggers when proof signal does not arrive.

Step Action Observation
1 Ensure FanProofSignal = FALSE —
2 Force GVL.StartCmd = TRUE (momentary) GVL.MotorOut becomes TRUE
3 Watch FanProofTimer.ET Timer counts from 0s to 5s
4 Wait 5 seconds – DO NOT set FanProofSignal At 5s, Q becomes TRUE
5 Check FanFaultAlarm Becomes TRUE (latched)

✅ PASS – Fault detected and latched.

---

🔒 Test 3: Alarm Persistence (Latched)

Goal: Verify alarm stays latched even after conditions clear.

Step Action Observation
1 After fault from Test 2, force FanProofSignal = TRUE Timer reset, but alarm stays TRUE
2 Force GVL.StartCmd = FALSE MotorOut becomes FALSE
3 Check FanFaultAlarm Remains TRUE

✅ PASS – Alarm is latched as intended.

---

🔄 Test 4: Reset the Alarm

Goal: Verify alarm can be cleared.

Step Action Observation
1 After fault, manually force FanFaultAlarm = FALSE —
2 Check FanFaultAlarm Becomes FALSE
3 (If Rung 18 exists) Force GVL_Commands.ResetFanFault = TRUE FanFaultAlarm becomes FALSE

✅ PASS – Alarm resets correctly.

---

⏱️ Test 5: Proof Arrives Just Before Timeout

Goal: Verify timer resets correctly when proof arrives before 5s.

Step Action Observation
1 Force GVL.StartCmd = TRUE MotorOut becomes TRUE
2 Wait 4.5 seconds ET should show ~4.5s
3 Within 5s, force FanProofSignal = TRUE Timer resets to 0
4 Check FanFaultAlarm Remains FALSE

✅ PASS – Timer resets, no fault.

---

✅ Test 6: Proof Already Present When Motor Starts

Goal: Verify timer does NOT start if proof already exists.

Step Action Observation
1 Force FanProofSignal = TRUE —
2 Force GVL.StartCmd = TRUE MotorOut becomes TRUE
3 Check FanProofTimer.ET Stays at 0
4 Check FanFaultAlarm Remains FALSE

✅ PASS – Timer only runs when proof is missing.

---

Troubleshooting

Issue Possible Cause Solution
Timer won't start FanProofSignal is TRUE Ensure FanProofSignal = FALSE before starting
Timer won't reset FanProofSignal is FALSE after timer started Force FanProofSignal = TRUE
Alarm won't latch SET coil missing or incorrectly connected Use ( S ) coil, not normal ( )
Alarm won't reset No reset rung Manually force FanFaultAlarm = FALSE or add Rung 18
C0080 error TON block missing instance name Double-click TON header and type GVL_Fan.FanProofTimer
Timer connects to EN instead of IN Wrong block type inserted Delete and re-insert TON block from Toolbox

---

Implementation Notes

· Rung order: Place after motor output (Rung 3) and temperature control (Rungs 7–14).
· Instance name: Must match exactly the variable declared in GVL (GVL_Fan.FanProofTimer).
· PT (Preset Time): Set to T#5s for 5-second delay.
· IN pin: Connect series contacts to the IN input, not EN.
· SET coil: Use ( S ) for latching, ( R ) for reset.
· Test without hardware: Force variables manually from the watch window.

---

Quick Reference Card

```
Normal Start:
StartCmd TRUE → MotorOut TRUE → Timer counts → FanProofSignal TRUE within 5s → Timer resets → No alarm

Fault Start:
StartCmd TRUE → MotorOut TRUE → Timer counts → FanProofSignal stays FALSE → 5s elapses → Q TRUE → Alarm SET

Reset:
Force FanFaultAlarm FALSE (manual) OR use ResetFanFault (if implemented)
```

---

Author: PLC Programmer
Date: 2026-06-16
CODESYS Version: V3.5 SP18

```
