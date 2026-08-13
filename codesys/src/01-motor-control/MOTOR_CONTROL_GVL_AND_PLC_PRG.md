# Motor Control - CODESYS Implementation

This directory contains the Strctured Text (ST) source code for a basic motor control system, including seal-in, overload latch, emergency stop, and alarm output. The system is designed to run on a Raspberry Pi with the `CODESYS Control for Raspberry Pi SL` runtime.

## Global Variable List (GVL)

The GVL (`GVL_Motor.st`) declares all inputs, outputs, and internal variables. It uses explicit `AT %QX` addressing to map each Boolean variable to a dedicated Modbus coil address (even though WebVisu is the primary HMI). This makes the same variables accessible via Modbus TCP in the future without changing the logic.

### Variable Listing

| Variable Name | Address | Type | Direction | Description |
|---------------|---------|------|-----------|-------------|
| `StartCmd`    | `%QX0.0` | BOOL | Input (from HMI) | Start command (momentary) |
| `StopCmd`    | `%QX0.1` | BOOL | Input (from HMI) | Stop command |
| `ResetCmd`    | `%QX0.2` | BOOL | Input (from HMI) | Reset overload latch |
| `EStop`    | `%QX0.3` | BOOL | Input (from HMI) | Emergency Stop |
| `OverloadTrip`    | `%QX0.4` | BOOL | Input (from HMI) | Simulate overload |
| `MotorOut`    | `%QX0.5` | BOOL | Output (to HMI) | Motor running status |
| `OverloadAlarm`    | `%QX0.6` | BOOL | Output (to HMI) | Overload latched alarm |
| `MotorInternal`    | (none) | BOOL | Internal | Seal-in memory bit |
| `OverloadAlarm`    | (none) | BOOL | Internal | Overload latch memory |

### Why `AT %QX` addressing?

- **Simplicity**: The same variable can be read/written by WebVisu (via direct binding) and later by Modbus TCP without any extra mapping.

- **Flexibility**: If a Modbus client (eg: NodeRED, Python with `pymodbus`) is connected, it can read/write these coils using standard function codes (FC 01, 05, 15) after the Modbus server is configured with the `Discrete Bit Areas ` enabled.

- **No need for holding registers**: The `%QX` addresses are directly available as coils, avoiding the confusion of mapping bits inside holding resgiters. 

### GVL Source (excerpt)

```pascal
{attribute 'qualified_only'}
VAR_GLOBAL
    (* Inputs - Commands from HMI *)
    StartCmd AT %QX0.0        : BOOL;
    StopCmd AT %QX0.1         : BOOL;
    ResetCmd AT %QX0.2        : BOOL;
    EStop AT %QX0.3           : BOOL;
    OverloadTrip AT %QX0.4    : BOOL;
    
    (* Internal *)
    MotorInternal  : BOOL;
    OverloadMem     : BOOL;
    
    (* Outputs - Status to HMI *)
    MotorOut AT %QX0.5     : BOOL;
    OverloadAlarm AT %QX0.6   : BOOL;
END_VAR
```

The `{attribute 'qualified only'}` forces the use of the prefix `GVL.` when accessing these variables in the program code, a good practice that makes the origin of each variable clear.

## Strctured Text Logic (PLC_PRG_Motor.st)

The file (`PLC_PRG_Motor.st`) contains the main control logic for a motor with start/stop, overload latch, and emergency stop. The code is written in Structured Text (ST) and intended to be placed in the implementation part (lower POU window) of Codesys `PLC_PRG`. The upper POU window is the declaration part.

### Design Overview

The motor control follows the classic industrial patterns:

- **Seal-in (latching)**: Once the motor is started by a momentary `StartCmd`, it continues running even after the start command disappears. The stop command (`StopCmd`) or an emergency stop (`EStop`) breaks the seal.

- **Overload Latch**: An overload input (`OverloadTrip`) latches a memory bit (`OverloadMem`). This bit must be cleared by a seperate `ResetCmd`.

- **Emergency Stop**: Directly overrides the motor output and also breaks the seal-in (redundant but safe).

- **Alarm output**: Mirrors the overload latch to inform the HMI.

### Program Structure: Declaration vs Implementation

In CODESYS, each POU (Program Organization Unit) has two distinct sections:

- **Declaration Part** (upper section): Defines variables, constants, instances of function blocks, and other declarations. It is enclosed by `VAR...END VAR` (or similar). No executable code belongs here, mistakenly writing an assignment (eg: `GVL.Motor_Out := ...`) leads to a syntax error (eg: "expected comma") because it expects a variable declaration, not an executable statement. The working solution is to keep it minimal.

- **Implementation Part** (lower section): Contains the actual program code (assignments, IF statements, loops, etc.). This is where the logic resides.

### Use of `GVL.` Prefix

Because the Global Variable List (`GVL_Motor.st`) includes the pragma `{attribute 'qualified only'}`, all access to its variables MUST be prefixed with the GVL name. This rule makes the origin of each variable explicit, improving readability and preventing accidental name collisions. It is enforced by the CODESYS compiler.

### The ST Code (Implementation Part)

```pascal
(* Motor seal-in logic *)
GVL.MotorInternal := (GVL.StartCmd OR GVL.MotorInternal) AND NOT GVL.StopCmd AND NOT GVL.EStop;

(* Overload Latch - stays TRUE until reset *)
GVL.OverloadMem := (GVL.OverloadTrip OR GVL.OverloadMem) AND NOT GVL.ResetCmd;

(* Overload Alarm Output *)
GVL.OverloadAlarm := GVL.OverloadMem;

(* Motor output - runs only if internal seal-in is active  AND no overload AND no EStop *)
GVL.MotorOut := GVL.MotorInternal AND NOT GVL.OverloadMem AND NOT GVL.EStop;

(* If overload trips, break the seal-in *)
IF GVL.OverloadMem THEN
	GVL.MotorInternal := FALSE;
END_IF
```

- **Seal-in**: `StartCmd` or already running `MotorInternal` keeps the bit true, while `StopCmd` or `EStop` resets it.

- **Overload latch**: Once the overload occurs, `OverloadMem` becomes TRUE and stays TRUE until `ResetCmd` is given.

- **Alarm**: Simply copies the latch to the output alarm lamp.

- **Motor output**: `MotorOut` is true only if the seal-in is active, no overload is latched, and no emergency stop is active.

- **Extra seal-in break**: The IF statement resets `MotorInternal` when overload is latched, providing an additional safety layer (though the motor output already uses `NOT OverloadMem`, this ensures the seal-in does not remain active).

## Relationship with Modbus and future extensions

- The variables are mapped to `%QX` addresses in the GVL, so they are directly accessible as Modbus coils if the Discrete Bit Areas are enabled in the Modbus TCP Server device. This allows external clients (Node-RED, Python `pymodbus`, SCADA) to read/write the motor state without any additional mapping.

- For now, the WebVisu is the primary HMI. The Modbus capability is kept as an optional add-on.
