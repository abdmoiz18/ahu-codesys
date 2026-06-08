# Converting Structured Text (ST) to Ladder Diagram (LD): A Step‑by‑Step Guide

This guide walks you through converting a motor control program from Structured Text to Ladder Diagram, using the exact logic from the example. You will learn a systematic method that applies to any ST‑to‑LD conversion.

## Original Structured Text Program

```pascal
(* Motor seal-in logic *)
GVL.MotorInternal := (GVL.StartCmd OR GVL.MotorInternal) AND NOT GVL.StopCmd AND NOT GVL.EStop;

(* Overload Latch - stays TRUE until reset *)
GVL.OverloadMem := (GVL.OverloadTrip OR GVL.OverloadMem) AND NOT GVL.ResetCmd;

(* Overload Alarm Output *)
GVL.OverloadAlarm := GVL.OverloadMem;

(* Motor output - runs only if internal seal-in is active AND no overload AND no EStop *)
GVL.MotorOut := GVL.MotorInternal AND NOT GVL.OverloadMem AND NOT GVL.EStop;

(* If overload trips, break the seal-in *)
IF GVL.OverloadMem THEN
    GVL.MotorInternal := FALSE;
END_IF
```

## Step-by-Step Conversion Process

### Step 1: Determine the logic behind the ST Code

Read the code and understand what each line does.

| Line | Behaviour |
|------|-----------|
| MotorInternal := (StartCmd OR MotorInternal) AND NOT StopCmd AND NOT EStop | Standard start/stop seal‑in with two stop conditions. |
| OverloadMem := (OverloadTrip OR OverloadMem) AND NOT ResetCmd | Reset‑dominant latch: stays TRUE after overload until ResetCmd is pressed. |
| OverloadAlarm := OverloadMem | Simple copy (combinational). |
| MotorOut := MotorInternal AND NOT OverloadMem AND NOT EStop | Output with extra safety interlocks (redundant but safe). |
| IF OverloadMem THEN MotorInternal := FALSE; | Forcibly breaks the seal‑in when overload is latched. |

### Step 2: Identify all memory elements (latches)

A memory element is a variable that appears on both sides of an assignment or is used as feedback.

- `GVL.MotorInternal` – appears in RHS and LHS → seal‑in latch.

- `GVL.OverloadMem` – appears in RHS and LHS → reset‑dominant latch.

- `GVL.OverloadAlarm` – only on LHS → combinational (no memory).

- `GVL.MotorOut` – only on LHS → combinational (no memory).

### Step 3: Write the next state equation for each element

Express the next value in Boolean form.

- `MotorInternal_next = (StartCmd OR MotorInternal) AND NOT StopCmd AND NOT EStop`

- `OverloadMem_next = (OverloadTrip OR OverloadMem) AND NOT ResetCmd`

For the overload, this is reset‑dominant: when `ResetCmd` is TRUE, the output is forced FALSE regardless of `OverloadTrip`.

### Step 4: Determine rung order based on evaluation priority

In Ladder Diagram, rungs execute top‑to‑bottom. The original ST has an override (`IF OverloadMem THEN MotorInternal := FALSE`) that must happen after the seal‑in calculation.

Order of rungs in LD:

1. Seal‑in for `MotorInternal` (without overload break).

2. Override: unlatch `MotorInternal` when `OverloadMem` is TRUE.

3. Set/reset logic for `OverloadMem` (reset‑dominant).

4. Combinational signals (`OverloadAlarm`, `MotorOut`).

### Step 5: Translate combinational signals directly

These need no memory, just series/parallel contacts.

`OverloadAlarm := OverloadMem` → One normally open contact driving a standard coil.

`MotorOut := MotorInternal AND NOT OverloadMem AND NOT EStop` → Three contacts in series (NO for `MotorInternal`, NC for `OverloadMem` and `EStop`) driving a standard coil.

### Step 6: Choose the cleanest Ladder pattern for each memory element

| Memory Element | Pattern | Reason |
|----------------|---------|--------|
| MotorInternal (seal‑in) | One rung with a parallel feedback branch + series stop contacts + standard coil ( ) | Simple, readable, matches classic motor start/stop. |
| MotorInternal (override) | One rung with a reset coil (R) triggered by OverloadMem | Explicitly clears the bit when overload is latched. |
| OverloadMem (reset‑dominant) | Two rungs: Set coil (S) when OverloadTrip AND NOT ResetCmd, Reset coil (R) when ResetCmd | Clear and safe; reset rung placed after set rung gives reset dominance. |

### Step 7: Final Diagram Ladder Rungs

```text
Rung 1 – Seal‑in for MotorInternal
      StartCmd               StopCmd(NC)   EStop(NC)      MotorInternal
------| |--------------------|/|-----------|/|--------------( )---
      |                      |
      |   MotorInternal      |
      +---| |-----------------

Rung 2 – Override: break seal‑in on overload
   OverloadMem
----| |-----------------------( U ) MotorInternal    (or (R) coil)

Rung 3 – Set OverloadMem (overload trip & not reset)
   OverloadTrip   ResetCmd(NC)
----| |-------------|/|--------------( S ) OverloadMem

Rung 4 – Reset OverloadMem (reset command)
   ResetCmd
----| |------------------------------( R ) OverloadMem

Rung 5 – Overload alarm
   OverloadMem
----| |------------------------------( ) OverloadAlarm

Rung 6 – Motor output with safety interlocks
   MotorInternal   OverloadMem(NC)   EStop(NC)
----| |--------------|/|--------------|/|--------------( ) MotorOut
```

### Common ST to Boolean Translations

1. **AND** → series contacts.

2. **OR** → parallel branches (or multiple rungs with set/reset).  

3. **NOT** → normally closed (NC) contact.  

4. **Seal‑in** `X := (A OR X) AND NOT B` → one rung with parallel feedback branch and series NC contact for B.  

5. **Reset‑dominant latch** `X := (A OR X) AND NOT R` → two rungs: Set when A AND NOT R, Reset when R (Reset after Set).  

6. **Unconditional unlatch** `IF C THEN X := FALSE` → one rung with reset coil `(R)` driven by C.

### Beginner Mistakes to Avoid

| Mistake | Why It’s Wrong | Correct Approach |
|---------|----------------|------------------|
| Using a normally open contact for StopCmd in the seal‑in rung | Stop would need to be TRUE to run. Use NC contact (StopCmd) so running requires StopCmd = FALSE. | Use NC contact. |
| Placing the overload break rung before the seal‑in rung | The seal‑in could re‑set MotorInternal later in the same scan, ignoring the overload. | Place break rung after seal‑in. |
| Trying to put the OverloadMem reset condition inside the same rung as the set. | Creates a race condition or requires duplicating the reset contact in both paths. | Use separate Set and Reset rungs. |
| Believing that a standard coil ( ) alone creates a latch. | A standard coil without a feedback branch is purely combinational – it will not hold state. | Add a parallel contact of the coil itself, or use Set/Reset. |
| Forgetting that the ResetCmd must be active for at least one scan to clear the latch. | Momentary pushbuttons work, but a one‑shot reset may not clear if the set condition is still true. | Use reset‑dominant pattern (Reset rung after Set). |


