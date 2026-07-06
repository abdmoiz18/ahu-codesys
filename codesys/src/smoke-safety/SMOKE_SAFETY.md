# Smoke Safety Interlock – Ladder Logic Implementation

## Project Overview

This module implements a **smoke safety interlock** for an HVAC system using **CODESYS Ladder Logic (LD)**. When smoke is detected, the system:

1. **Latches** a smoke alarm
2. **Forces the heater OFF** (overrides temperature control)
3. **Freezes the temperature simulation** (prevents unrealistic cooling)
4. **Requires a manual reset** to resume normal operation

This implementation follows the **IEC 61131-3** standard and is designed for entry-level PLC programmers.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Variables Declaration](#variables-declaration)
3. [Final Ladder Logic Rungs](#final-ladder-logic-rungs)
   - Rungs 1–2: Smoke Alarm Latch & Output
   - Rungs 3–6: Motor Control (unchanged)
   - Rungs 7–8: Fan Proof (unchanged)
   - Rungs 9–11: Temperature Simulation (smoke-guarded)
   - Rungs 12–14: Hysteresis + Smoke Override
4. [Errors Encountered & Solutions](#errors-encountered--solutions)
5. [Testing Guide](#testing-guide)
6. [Final Verification Checklist](#final-verification-checklist)

---

## System Overview

### Priority Structure

| Priority | Condition | Action |
|----------|-----------|--------|
| **1 (Highest)** | Smoke detected | Heater OFF, simulation FREEZE, alarm LATCH |
| **2** | Temperature control | Normal hysteresis (only if no smoke) |
| **3** | Simulation | Updates temperature (only if no smoke) |

### Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `GVL_Smoke.SmokeDetected` | BOOL | Input from smoke detector |
| `GVL_Smoke.SmokeAlarmMem` | BOOL | Latched alarm memory |
| `GVL_Smoke.SmokeAlarm` | BOOL | Alarm output (follows `SmokeAlarmMem`) |
| `GVL_Smoke.ResetSmoke` | BOOL | Manual reset command |
| `GVL_Temp.HeatOutput` | BOOL | Heater command (smoke overrides to FALSE) |
| `GVL_Temp.SimTemp` | REAL | Simulated temperature |
| `GVL_Temp.CurrentTemp` | REAL | Process temperature |

---

## Variables Declaration (GVL_Smoke)

```pascal
{attribute 'qualified_only'}
VAR_GLOBAL
    (* Smoke Alarm *)
    SmokeDetected : BOOL;     (* Input from smoke detector *)
    SmokeAlarmMem : BOOL;     (* Latched alarm memory *)
    ResetSmoke : BOOL;        (* Reset command *)
    SmokeAlarm : BOOL;        (* Output alarm *)
END_VAR
```

---

## Final Ladder Logic Rungs

### Rungs 1–2: Smoke Alarm Latch & Output

#### Rung 1 – Smoke Alarm Latch

Implements: `SmokeAlarmMem := (SmokeDetected OR SmokeAlarmMem) AND NOT ResetSmoke`

```
   GVL_Smoke.SmokeDetected                          GVL_Smoke.ResetSmoke         GVL_Smoke.SmokeAlarmMem
-------| |--------+----------------------------------|/|---------------------------( )-----
                  |                                                           |
   GVL_Smoke.SmokeAlarmMem                          |                           |
-------| |--------+----------------------------------+                           |
```

**Power Flow:**
1. Power enters from the left rail
2. Parallel branches evaluate `SmokeDetected OR SmokeAlarmMem`
3. Both branches merge before `ResetSmoke` NC contact
4. If `ResetSmoke` is FALSE (NC closed), power reaches the coil
5. Coil `SmokeAlarmMem` is energized → latches

**Key Point:** The feedback contact (`SmokeAlarmMem`) rejoins **before** the `ResetSmoke` contact. This ensures `ResetSmoke` controls both the set and reset paths.

---

#### Rung 2 – Smoke Alarm Output

Implements: `SmokeAlarm := SmokeAlarmMem`

```
   GVL_Smoke.SmokeAlarmMem                          GVL_Smoke.SmokeAlarm
-------| |-----------------------------------------------( )-----
```

---

### Rungs 3–6: Motor Control (Unchanged)

For completeness, these are the existing motor logic rungs:

#### Rung 3 – Overload Latch
```
   GVL.OverloadTrip                                 GVL.ResetCmd                 GVL.OverloadMem
-------| |--------+----------------------------------|/|---------------------------( )-----
                  |                                                           |
   GVL.OverloadMem                                  |                           |
-------| |--------+----------------------------------+                           |
```

#### Rung 4 – Overload Alarm Output
```
   GVL.OverloadMem                                  GVL.OverloadAlarm
-------| |-----------------------------------------------( )-----
```

#### Rung 5 – Motor Seal‑in
```
   GVL.StartCmd          GVL.StopCmd   GVL.EStop   GVL.OverloadMem    GVL.MotorInternal
----| |----+-------------|/|------------|/|----------|/|----------------( )---
           |
           | GVL.MotorInternal
           +----| |-------+
```

#### Rung 6 – Motor Output
```
   GVL.MotorInternal   GVL.OverloadMem   GVL.EStop
-------| |----------------|/|--------------|/|--------+-------( )-------
                                                      GVL.MotorOut
```

---

### Rungs 7–8: Fan Proof (Unchanged)

#### Rung 7 – Fan Proof Timer
```
   GVL.MotorOut   GVL_Fan.FanProofSignal             GVL_Fan.FanProofTimer
-------| |------------|/|-----------------------------------[ TON ]---
                                                              PT := T#5s
```

#### Rung 8 – Fan Fault Alarm Latch
```
   GVL_Fan.FanProofTimer.Q                        GVL_Fan.FanFaultAlarm
-------| |-----------------------------------------------( S )---
```

---

### Rungs 9–11: Temperature Simulation (Smoke-Guarded)

These rungs **only execute when no smoke is active**. The NC contact of `SmokeAlarmMem` at the beginning of each rung prevents execution during a smoke event.

#### Rung 9 – Heating Simulation (ADD)

**Condition:** `NOT SmokeAlarmMem AND HeatOutput`

```
   GVL_Smoke.SmokeAlarmMem   GVL_Temp.HeatOutput                                 ADD
-------|/|----------+--------| |-----------------------------------------------|EN|
                   |                                                          |   |
                   |   GVL_Temp.HeatOutput                                   SimTemp--|IN1|
                   +-------| |----------------------------------------------+ 0.001--|IN2|
                                                                                 |   |
                                                                                 |Q|--+---[MOVE]--- SimTemp
                                                                                     |   |IN|
                                                                                     +---|   |
```

**What happens:**
- `SmokeAlarmMem = FALSE` (no smoke) → NC contact closed → power flows
- `HeatOutput = TRUE` → ADD block executes → `SimTemp` increases by 0.001

---

#### Rung 10 – Cooling Simulation (SUB)

**Condition:** `NOT SmokeAlarmMem AND NOT HeatOutput`

```
   GVL_Smoke.SmokeAlarmMem   GVL_Temp.HeatOutput                                 SUB
-------|/|----------+--------|/|-----------------------------------------------|EN|
                   |                                                          |   |
                   |   GVL_Temp.HeatOutput                                   SimTemp--|IN1|
                   +-------|/|----------------------------------------------+ 0.0006-|IN2|
                                                                                 |   |
                                                                                 |Q|--+---[MOVE]--- SimTemp
                                                                                     |   |IN|
                                                                                     +---|   |
```

**What happens:**
- `SmokeAlarmMem = FALSE` (no smoke) → NC contact closed → power flows
- `HeatOutput = FALSE` → SUB block executes → `SimTemp` decreases by 0.0006

---

#### Rung 11 – Copy SimTemp to CurrentTemp (Smoke-Guarded)

**Condition:** `NOT SmokeAlarmMem`

```
   GVL_Smoke.SmokeAlarmMem   GVL_Temp.SimTemp              MOVE
-------|/|------------+------------------------------------|EN|
                      |                                   |   |
                      |                           SimTemp--|IN|   CurrentTemp
                      |                                   |   |----|Q|---
                      +-----------------------------------+
```

**What happens:**
- `SmokeAlarmMem = FALSE` (no smoke) → power flows → MOVE executes → `CurrentTemp` updates
- `SmokeAlarmMem = TRUE` (smoke active) → NC contact opens → MOVE disabled → `CurrentTemp` holds value

---

### Rungs 12–14: Hysteresis + Smoke Override

These rungs implement the temperature hysteresis with smoke priority.

#### Rung 12 – Temperature SET (smoke-guarded)

**Condition:** `NOT SmokeAlarmMem AND CurrentTemp < Setpoint - 1.0`

```
   GVL_Smoke.SmokeAlarmMem   GVL_Temp.CurrentTemp   LowerLimit             GVL_Temp.HeatOutput
-------|/|----------+--------| |-------------------[LT]-----------------------( S )---
                   |                                 |                   |
                   |   GVL_Temp.HeatOutput          |                   |
                   +-------| |-----------------------+                   |
```

**What happens:**
- `SmokeAlarmMem = FALSE` → NC contact closed → LT block runs
- If `CurrentTemp < Setpoint - 1.0` → SET coil → `HeatOutput = TRUE`

---

#### Rung 13 – Temperature RESET (smoke-guarded)

**Condition:** `NOT SmokeAlarmMem AND CurrentTemp > Setpoint + 1.0`

```
   GVL_Smoke.SmokeAlarmMem   GVL_Temp.CurrentTemp   UpperLimit             GVL_Temp.HeatOutput
-------|/|----------+--------| |-------------------[GT]-----------------------( R )---
                   |                                 |                   |
                   |   GVL_Temp.HeatOutput          |                   |
                   +-------| |-----------------------+                   |
```

**What happens:**
- `SmokeAlarmMem = FALSE` → NC contact closed → GT block runs
- If `CurrentTemp > Setpoint + 1.0` → RESET coil → `HeatOutput = FALSE`

---

#### Rung 14 – Smoke Override (FORCES OFF – MUST BE LAST)

**Condition:** `SmokeAlarmMem`

```
   GVL_Smoke.SmokeAlarmMem                        GVL_Temp.HeatOutput
-------| |-----------------------------------------------( R )---
```

**Critical:** This rung **must be placed after** Rungs 12 and 13. It forces `HeatOutput = FALSE` when smoke is active, overriding any SET from Rung 12.

---

## Complete Rung Order

| Rung | Function | Smoke Guard? | Priority |
|------|----------|--------------|----------|
| **1** | Smoke Alarm Latch | N/A | 1 |
| **2** | Smoke Alarm Output | N/A | 1 |
| **3** | Overload Latch | N/A | 1 |
| **4** | Overload Alarm Output | N/A | 1 |
| **5** | Motor Seal‑in | N/A | 1 |
| **6** | Motor Output | N/A | 1 |
| **7** | Fan Proof Timer | N/A | 1 |
| **8** | Fan Fault Alarm Latch | N/A | 1 |
| **9** | Temperature Simulation (Heating) | ✅ YES | 2 |
| **10** | Temperature Simulation (Cooling) | ✅ YES | 2 |
| **11** | Copy SimTemp to CurrentTemp | ✅ YES | 2 |
| **12** | Temperature Hysteresis (SET) | ✅ YES | 2 |
| **13** | Temperature Hysteresis (RESET) | ✅ YES | 2 |
| **14** | **Smoke Override (forces OFF)** | **N/A** | **3 (Highest)** |

---

## Errors Encountered & Solutions

### Error 1: Smoke Override Not Working (ST vs. LD Conflict)

| Issue | Root Cause | Solution |
|-------|------------|----------|
| Smoke detected but `HeatOutput` stayed ON | Task priority: ST logic ran **after** LD, overriding LD changes | Removed ST logic or ensured consistency between ST and LD |

**What happened:** The task configuration executed ST code **after** LD rungs in the same scan cycle. If ST assigned `HeatOutput = TRUE`, it would overwrite LD's smoke override.

**Fix:** Removed the ST code entirely (ran purely in LD) OR modified ST to match LD logic.

---

### Error 2: Mislabeled Coil in Rung 1

| Issue | Root Cause | Solution |
|-------|------------|----------|
| Smoke alarm didn't latch | Coil labelled `SmokeAlarm` instead of `SmokeAlarmMem` | Corrected coil label to `GVL_Smoke.SmokeAlarmMem` |

**What happened:** The coil in Rung 1 was labelled `SmokeAlarm` (output) instead of `SmokeAlarmMem` (memory latch). The latch circuit had no feedback path, so it never latched.

**Fix:** Changed the coil label to `GVL_Smoke.SmokeAlarmMem`.

---

### Error 3: EN Pin Overriding Series Contacts

| Issue | Root Cause | Solution |
|-------|------------|----------|
| ADD/SUB blocks ran regardless of smoke condition | EN pin wired to `TRUE` constant | Wired EN to receive power from series contacts (or used standard blocks) |

**What happened:** Blocks with EN/ENO pins wired to `TRUE` execute **every scan**, ignoring all contacts before them.

**Fix:** 
- Option A: Wire EN to receive power from the series contacts
- Option B: Replace with standard blocks (no EN/ENO pins)
- Option C: Use an enable signal

---

### Error 4: MOVE Block Still Writing During Smoke

| Issue | Root Cause | Solution |
|-------|------------|----------|
| `SimTemp` froze but `CurrentTemp` kept changing | MOVE block (Rung 11) had EN wired to TRUE | Added smoke condition to MOVE block EN |

**What happened:** Even though `SimTemp` stopped changing (ADD/SUB were disabled), the MOVE block that copies `SimTemp` to `CurrentTemp` was still running, updating `CurrentTemp` every scan.

**Fix:** Added `NOT SmokeAlarmMem` condition to the MOVE block's EN pin.

---

### Error 5: Simulation Continued During Smoke

| Issue | Root Cause | Solution |
|-------|------------|----------|
| Temperature kept dropping during smoke | Simulation rungs (Rungs 9–10) not guarded by smoke condition | Added NC contact of `SmokeAlarmMem` at the start of each simulation rung |

**What happened:** When smoke forced `HeatOutput = FALSE`, the cooling simulation (SUB block) saw `HeatOutput = FALSE` and kept subtracting from `SimTemp`.

**Fix:** Added `NOT SmokeAlarmMem` condition to ALL simulation rungs (Rungs 9, 10, and 11).

---

## Testing Guide

### Test 1: Normal Temperature Control (No Smoke)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure `SmokeAlarmMem = FALSE` | Rungs 9–13 can execute |
| 2 | Force `CurrentTemp = 20.0°C` (below 21°C) | Rung 12 SET → `HeatOutput = TRUE` |
| 3 | Force `CurrentTemp = 24.0°C` (above 23°C) | Rung 13 RESET → `HeatOutput = FALSE` |
| 4 | Force `CurrentTemp = 22.0°C` (between thresholds) | `HeatOutput` holds previous state |

**✅ PASS – Normal temperature control works**

---

### Test 2: Smoke Detection

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Force `SmokeDetected = TRUE` | `SmokeAlarmMem` latches TRUE |
| 2 | `SmokeAlarm` becomes TRUE | Alarm output follows |
| 3 | Rung 14 executes | `HeatOutput = FALSE` (forced OFF) |
| 4 | Rungs 9–13 are bypassed (NC contacts open) | Simulation freezes, hysteresis disabled |
| 5 | `SimTemp` holds value | No heating or cooling |

**✅ PASS – Smoke overrides everything**

---

### Test 3: Smoke Clears (Alarm Still Latched)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Force `SmokeDetected = FALSE` | Detector input clears |
| 2 | `SmokeAlarmMem` stays TRUE | Alarm persists (latched) |
| 3 | Rungs 9–13 still bypassed | Simulation still frozen |
| 4 | `HeatOutput` stays FALSE | Safe state maintained |

**✅ PASS – Latch holds alarm state**

---

### Test 4: Manual Reset

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Force `ResetSmoke = TRUE` | `SmokeAlarmMem` resets to FALSE |
| 2 | `SmokeAlarm` becomes FALSE | Alarm clears |
| 3 | Rungs 9–13 re-enabled | Simulation and hysteresis resume |
| 4 | `HeatOutput` follows temperature | Normal control restored |

**✅ PASS – Reset clears alarm and restores control**

---

### Test 5: EN Pin Wiring Verification

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Force `SmokeAlarmMem = TRUE` | All EN pins in Rungs 9–13 should receive FALSE |
| 2 | Check ADD/SUB/MOVE blocks | None execute |
| 3 | Rung 14 executes | `HeatOutput = FALSE` |
| 4 | Force `SmokeAlarmMem = FALSE` | EN pins receive TRUE → blocks execute |

**✅ PASS – EN pins are correctly controlled**

---

## Final Verification Checklist

- [ ] `SmokeAlarmMem` latches when `SmokeDetected = TRUE`
- [ ] `SmokeAlarm` follows `SmokeAlarmMem`
- [ ] Rung 14 forces `HeatOutput = FALSE` when smoke is active
- [ ] Rungs 9–13 are disabled when smoke is active (NC contacts open)
- [ ] Temperature simulation FREEZES during smoke (`SimTemp` holds value)
- [ ] `CurrentTemp` holds value during smoke (MOVE block disabled)
- [ ] Hysteresis is disabled during smoke (SET/RESET coils bypassed)
- [ ] After `ResetSmoke`, everything resumes normally
- [ ] Motor, overload, and fan proof logic work independently

---

## Common Pitfalls & Golden Rules

### Pitfall 1: Mislabeling Coils
**Rule:** Always use the correct variable for latches. A latch coil must be the **memory** variable, not the output variable.

### Pitfall 2: EN Pins Overriding Contacts
**Rule:** If you use blocks with EN/ENO pins, wire EN to receive power from the series contacts. Never wire EN to a constant TRUE unless you want unconditional execution.

### Pitfall 3: Missing a Block
**Rule:** Every block that writes to a variable must be controlled by the same conditions. If one block is missed, it will override everything else.

### Pitfall 4: Wrong Rung Order
**Rule:** The smoke override rung (Rung 14) MUST be placed AFTER all temperature control rungs. In LD, the last coil write wins.

### Pitfall 5: Simulation Runs During Smoke
**Rule:** If your simulation uses `HeatOutput` to decide heating/cooling, you MUST guard the simulation with the smoke condition. Otherwise, smoke forcing `HeatOutput = FALSE` will trigger cooling simulation.

---

## Quick Reference

| Condition | Rung 12 (SET) | Rung 13 (RESET) | Rung 14 (Override) | Final HeatOutput |
|-----------|---------------|-----------------|--------------------|------------------|
| **No smoke, cold** | TRUE | FALSE | FALSE (bypassed) | SET → TRUE |
| **No smoke, hot** | FALSE | TRUE | FALSE (bypassed) | RESET → FALSE |
| **No smoke, mid** | FALSE | FALSE | FALSE (bypassed) | Holds previous |
| **Smoke active** | BYPASSED | BYPASSED | TRUE | RESET → FALSE |
| **Smoke cleared but latched** | BYPASSED | BYPASSED | TRUE | RESET → FALSE |
| **After ResetSmoke** | Normal operation resumes | Normal | FALSE (bypassed) | Follows temperature |

---

## Summary

This smoke safety interlock implementation demonstrates:

1. **Proper latching** of alarm conditions
2. **Priority-based** safety overrides
3. **Coordination** between simulation and control logic
4. **Manual reset** functionality
5. **Guarding** of all affected logic with safety conditions

**Key lesson:** Every block that writes to a shared variable must be controlled by the same conditions. In this case, the smoke condition (`NOT SmokeAlarmMem`) must guard:
- Temperature simulation (ADD/SUB/MOVE)
- Temperature hysteresis (SET/RESET coils)
- CurrentTemp update (MOVE block)

---

**Author:** PLC Programmer  
**Date:** 2026-07-06  
**CODESYS Version:** V3.5 SP18  
**Project:** HVAC Control with Smoke Safety Interlock
```
