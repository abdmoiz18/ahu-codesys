# Modbus TCP Server Configuration in CODESYS

This document summarises the Modbus TCP Server setup used in the CODESYS project for the motor control system. It explains the configuration choices, the behaviour of the "Writable" flag, the difference between holding registers and coils, and how this setup allows future integration with Modbus clients (eg: Node-RED, Python `pymodbus`) while keeping WebVisu as the primary HMI.

## 1. Adding the Modbus TCP Server Device

- In the CODESYS device tree, first add an Ethernet device using right-click, Add Device -> Ethernet. Then under Ethernet, right-click -> Add Device -> Modbus TCP Server (CODESYS uses "Server" for Modbus slave and "Client" for Modbus master.)

The device appears as a child of the Ethernet interface. No further physical configuration is needed for a simple homelab.

## 2. General Configuration Tab

The General tab contains several options:

| Option | Setting | Explanation |
|--------|---------|-------------|
| Port | 502 | Standard Modbus TCP Port |
| Watchdog | Disabled | Not needed for simulation, would trigger if no communication is received within a set time. |
| Bind to adapter | Unchecked | The server listens on all network interfaces. Not required because the Pi has a single active Ethernet connection. |
| Discrete Bit Areas | Unchecked (by default) | When unchecked, coils (%QX) and discrete inputs (%IX) are not exposed as Modbus address spaces. This is acceptable because WebVisu does not use Modbus, and we can still access the same data via holding registers (see below). |

### 2.1. The "Writable" Option

- Holding Registers (function codes 03, 06, 16): By default, they are mapped to %IW (read‑only from the client’s perspective). When “Writable” is checked, they are mapped to %QW – 16‑bit registers that a Modbus client can both read and write.

- Input Registers (function code 04): These traditionally are read‑only. However, in CODESYS, checking “Writable” also affects them, they are allocated as %QW space, but a client cannot write to input registers. This is a minor quirk that does not harm.

**Effect of checking "Writable":**

- You get a block of writable holding registers (%QW0 – %QW9 if you set 10 registers).

- The same memory area can be accessed as individual bits via the “I/O Mapping” tab, where you can link each bit of %QW0 to a Boolean variable (e.g., GVL_Motor.StartCmd mapped to %QW0.0).

- This provides an alternative way to exchange Boolean data without enabling the coil table.

## 3. Holding Resgisters and Bit Mapping

With “Writable” checked, the I/O Mapping tab shows channels like %QW0, %QW0.0, %QW0.1, … %QW0.15. Each %QW0.x is a bit of the first holding register. A Modbus client can:

- Read the whole 16‑bit register (FC 03) and decode the bits.

- Write individual bits (FC 06 is for a full register; to write a single bit, the client would need to read‑modify‑write the whole register, or use a coil write if coils are enabled).

Because we did not enable “Discrete bit areas”, the simpler coil functions (FC 01, 05, 15) are not available by default. This is why earlier attempts to use mbpoll with coil addresses failed – the server had no coil table.

## 4. Why we did not enable Coils/Discrete Inputs

- WebVisu does not use Modbus – it directly reads/writes the %QX variables via the runtime. No Modbus needed.

- Simplicity – Enabling coils would add another layer of configuration (defining start addresses, lengths, etc.). The holding register approach works and is already understood.

- Future flexibility – If you later want to expose the same variables as simple coils, you can enable “Discrete bit areas” at any time. The %QX variables are already declared with fixed addresses, so they would automatically appear as coils (address 0 for %QX0.0, etc.).

## 5. Relationship with the Global Variable List (GVL)

The GVL `GVL_Motor.st` declares all motor variables with explicit `AT %QX` addresses:

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
- These `%QX` addresses correspond to coils.

- If "Discrete Bit Areas" is enabled, a Modbus client can directly read/write `StartCmd` at coil address 0, `StopCmd` at 1, etc. using function codes 01, 05, 15.

- If coils remain disabled, you can still access the same bits by mapping them to `%QW0.x` in the I/O Mapping tab. The choice is yours.

## 6. Testing with `mbpoll` (Example)

Once coils are enabled, a command like:

```bash
mbpoll 192.168.137.100 -t 0 -r 1 -1   # write 1 to coil 0 (start)
mbpoll 192.168.137.100 -t 0 -r 5 -c 1 # read coil 4 (MotorOut)
```
would work. In our current configuration (coils disabled), the same data can be accessed via holding registers:

```bash
# Read holding register 0 (contains bits 0‑7)
mbpoll 192.168.137.100 -t 4 -r 1 -c 1
```

The client would then need to mask the appropriate bit.

## 7. Summary of Current Setup

| Feature | Status | How to use |
|---------|--------|------------|
| WebVisu HMI | Working | Direct binding to `GVL.xx` variables. |
| Modbus TCP Server | Configured, listening on port 502 | Server enabled, "Writable" checked, 10 holding registers. |
| Coil table | Disabled | Not needed for WebVisu, can be enabled later. |
| Access to motor variables via Modbus | Possible via holding register bits | Use FC 03/06/16 and decode bits. Simpler: enable coils later. |

## 8. Next Steps for Modbus Integration

### 8.1. If you want to use Node-RED or `pymodbus` with simple coil reads/writes:

- In the Modbus TCP Server General tab, tick “Discrete bit areas”.

- Set the number of coils (e.g., 10) and discrete inputs (e.g., 0).

- No further mapping needed – the %QX0.x variables will be accessible as coils at addresses 0, 1, 2, …

### 8.2. If you prefer to keep the current holding-register method:

- Map each `GVL_Motor` Boolean to a specific bit of `%QW0` in the I/O Mapping tab of the Modbus server.

- Write a client that reads/writes `%QW0` and masks bits.
