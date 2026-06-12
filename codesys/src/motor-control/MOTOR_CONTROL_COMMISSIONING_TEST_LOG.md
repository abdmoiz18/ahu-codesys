MOTOR CONTROL COMMISSIONING TEST LOG
Date: 12-06-2026
Tester: Abdul Moiz Dhinda
System: AHU Homelab CODESYS v1.0

⚠️ IMPORTANT NOTE ON TEST METHOD
- All tests were performed by **forcing variables directly in the CODESYS online view**, because WebVisu buttons did not respond in the editor canvas (design limitation when targeting a remote Raspberry Pi runtime).  
- The motor control logic (seal‑in, overload latch, emergency stop) was **fully verified** via forcing.  
- WebVisu HMI integration is **pending a test via external browser** (`http://<Pi‑IP>:8080/webvisu.htm`). Once the browser test confirms button responsiveness, the “Result” column below will be updated to “PASS (HMI)”.

---

TEST 1 – NORMAL START/STOP (Logic Verified via Forcing)

| Action | Expected | Result (Logic) | Notes |
|--------|----------|----------------|-------|
| Force `StartCmd` := TRUE | `MotorOut` TRUE, motor lamp GREEN | **PASS** | Seal‑in set correctly. |
| Release force on `StartCmd` (set FALSE) | `MotorOut` remains TRUE (seal‑in active) | **PASS** | Latch holds. |
| Force `StopCmd` := TRUE | `MotorOut` FALSE, motor lamp GREY | **PASS** | Latch cleared. |

TEST 2 – OVERLOAD PROTECTION (Logic Verified via Forcing)

| Action | Expected | Result (Logic) | Notes |
|--------|----------|----------------|-------|
| Start motor (force `StartCmd` TRUE), then force `OverloadTrip` := TRUE | `MotorOut` FALSE, `OverloadAlarm` TRUE | **PASS** | Overload latches. |
| Force `StartCmd` TRUE while overload active | Motor does **not** start | **PASS** | Interlock works. |
| Force `ResetCmd` := TRUE | `OverloadAlarm` FALSE, motor restartable | **PASS** | Latch cleared; motor can restart after new start command. |

TEST 3 – EMERGENCY STOP (Logic Verified via Forcing)

| Action | Expected | Result (Logic) | Notes |
|--------|----------|----------------|-------|
| Start motor, force `EStop` := TRUE | `MotorOut` FALSE immediately | **PASS** | E‑Stop overrides. |
| Release `EStop` (force FALSE), force `StartCmd` TRUE | Motor starts normally | **PASS** | Normal operation resumes. |

---

## Summary of Commissioning Status

| Component | Status | Remarks |
|-----------|--------|---------|
| **Motor control logic** (ST code) | ✅ **PASS** | Verified via variable forcing. All tests passed. |
| **WebVisu HMI integration** | ⏳ **PENDING** | Buttons not responsive in editor canvas. Awaiting test in external browser (`http://<Pi‑IP>:8080/webvisu.htm`). |

Once the browser test confirms that the HMI buttons correctly write to the variables, this log will be updated to “PASS (HMI)” without changing the logic results.

---

*End of commissioning log – logic verified, HMI pending browser validation.*

