# Connecting to CODESYS Runtime on Raspberry Pi - Step-by-Step Guide

This document covers the complete process of connecting a CODESYS Development System (Windows) to a Raspberry Pi running the CODESYS Control runtime, including first‑time login, downloading the program, forcing variables, and troubleshooting common authentication issues.

## Prerequisites

- Raspberry Pi with CODESYS Control for Raspberry Pi SL runtime installed (`.deb` package) and the service running.

- Windows laptop with CODESYS Development System (version 3.5 or later) installed.

- Both devices on the same Ethernet subnet (e.g., Pi IP `192.168.137.100`, laptop IP `192.168.137.1`).

## 1. Find the Raspberry Pi's IP Address

On the Pi (via SSH or directly), run:

```bash
hostname -I
```
Typical output: `192.168.137.100.` Note this address; you will need it in CODESYS.

## 2. Configure the CODESYS Device Connection

1. Open your CODESYS project.

2. In the Devices tree, double‑click your device (e.g., Device (CODESYS Control for Raspberry Pi SL)).

3. Go to the Communication Settings tab.

4. Click Scan Network. The gateway should find your Pi.

5. Select the Pi and click OK.

6. The Active Path should now show the Pi’s IP address.

## 3. First-Time Login and Download

When you log in for the first time, CODESYS will ask for a username and password. These are not your SSH credentials; they are the CODESYS device user.

### Default credentials (if never changed)

- Username: `pi`

- Password: `raspberry`

If those do not work, you may have set a custom password earlier. If you cannot remember it, proceed to Step 4 to reset the user database.

### Log in and download

1. Click Online → Login (or the green arrow icon).

2. If asked for credentials, enter the username and password.

3. If the runtime has no program yet, CODESYS will ask: “The application does not exist on the controller. Do you want to create the application and log in?” → Yes.

4. After download, start the PLC: Debug → Start (or press F5). The status indicator should turn green (Running).

## 4. Resetting a Forgotten Password / "Too many retries" Lockout

If you get the error “Option aborted, too many retries” or cannot remember the password, you must reset the CODESYS user database on the Pi via SSH.

1. SSH into the Raspberry Pi:

```bash
ssh pi@192.168.137.100   (or your username)
```

2. Stop the CODESYS runtime:

```bash
sudo systemctl stop codesyscontrol
```

3. Remove the user database file:

```bash
sudo rm /etc/codesyscontrol/CODESYSControl.userdb.cfg
```

4. Restart the runtime:

```bash
sudo systemctl start codesyscontrol
```

5. Return to CODESYS and try logging in again. This time, it will behave as a fresh install and prompt you to create a new user. Use a simple username/password (e.g., admin/admin) and write it down.

If the lockout persists, also remove retained data:

```bash
sudo rm -rf /var/opt/codesys/PlcLogic/retain/
sudo systemctl restart codesyscontrol
```

## 5. Online View and Forcing Variables

Once logged in and the PLC is running, you can monitor and manipulate variables.

**Opening the online view**

- Double‑click the POU (e.g., PLC_PRG). The editor will show live values – variables that are TRUE are highlighted.

- If values do not update, ensure the PLC is in Run mode (green indicator). If not, press F5.

**Forcing a variable (overriding program logic)**

Forcing is used for testing – it locks a variable to a specific value regardless of what the program calculates.

1. Right‑click the variable in the editor (or in a watch window).

2. Select Force Value → enter TRUE or FALSE.

3. The variable will show a red F next to it, indicating it is forced.

4. The program cannot change this value until you release the force.

**Example test sequence for motor control:**

- Force GVL_Motor.StartCmd to TRUE. Observe MotorInternal and MotorOut become TRUE.

- Release the force on StartCmd (right‑click → Release Force). The motor should stay TRUE – seal‑in working.

- Force GVL_Motor.StopCmd to TRUE. Motor should turn FALSE.

- Force GVL_Motor.OverloadTrip to TRUE. Motor stops, OverloadAlarm becomes TRUE.

- Force GVL_Motor.ResetCmd to TRUE. Alarm clears, motor stays off.

**Writing a variable (one‑time change)**

- Right‑click → Write Value (or use Ctrl+F7). This sets the variable once, but the program may overwrite it in the next scan.

**Releasing all forces**

- Menu Debug → Release All Forces (or the toolbar icon with a red X over a hand).

- All forced variables return to program‑controlled values.

## 6. Common Debugging Issues and Fixes

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Cannot log in, “too many retries” | Forgotten password or lockout | Reset user database (Step 4). |
| Variables do not update in online view | PLC is not in Run mode | Press F5 to start. |
| WebVisu buttons have no effect | Variables are forced | Release all forces. |
| WebVisu buttons still no effect | Button variable binding missing `GVL_` prefix | Use full name, e.g., `GVL.StartCmd`. |
| Modbus client cannot read/write coils | Coils not enabled in Modbus server | Enable Discrete bit areas in Modbus TCP Server config. |
| Forcing a variable does not “stick” | You used Write instead of Force | Use Force Value (F7). |

## 7. Disconnecting

- To stop the PLC without losing the program: Debug → Stop.

- To log out (unload the program from the runtime): Online → Logout.

- To completely reset the runtime and erase the program: Online → Reset (Warm or Cold).

## Summary of Useful Shortcuts

| Action | Shortcut | 
|--------|----------|
| Login | `Ctrl+Shift+L` (or green arrow) |
| Start PLC | `F5` |
| Stop PLC | `Shift+F5` |
| Force variable | `F7` after right-click |
| Write variable | `Ctrl+F7` after right-click |
| Release force on variable | Right-click -> Release Force |
| Release all forces | `Debug -> Release All Forces` |

This guide is based on the actual debugging experience with CODESYS Control for Raspberry Pi SL. The steps have been tested and verified.
