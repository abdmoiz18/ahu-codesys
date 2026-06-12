# WebVisu Troubleshooting Log – AHU Homelab

**Date:** [Date of debugging session]  
**Project:** AHU Homelab CODESYS v1.0  
**Target:** Raspberry Pi SL runtime  
**Issue:** WebVisu buttons unresponsive in CODESYS editor canvas  

This document is a complete chronological record of the debugging session. Each phase includes the action taken, the reasoning behind it, and the outcome.

---

## Phase 1 – Concept Definition
- **Action:** Asked for difference between Visualization Manager and Visualization.
- **Reason:** To understand the fundamentals before debugging.
- **Outcome:** Visualization Manager is mandatory; it creates `VISU_TASK`. Manager was present, so not the issue.

---

## Phase 2 – Automatic Generation Check
- **Action:** Noted that Manager appeared automatically when Visualization was added.
- **Reason:** To confirm CODESYS did not miss creating essential objects.
- **Outcome:** Environment configured correctly.

---

## Phase 3 – Button and Lamp Mapping
- **Action:** Followed step‑by‑step guide to link buttons to variables and lamps to outputs.
- **Reason:** To ensure HMI elements were correctly bound.
- **Outcome:** Binding was correct; problem elsewhere.

---

## Phase 4 – The “Memory Trap” Discovery
- **Action:** Noticed variables only changed when forced in GVL (using F7), not from HMI. Realised F7 is Write Values, not Force (Ctrl+F7).
- **Reason:** To understand why HMI appeared frozen.
- **Outcome:** PLC logic was overwriting variables every scan cycle – momentary pulses were erased before HMI could reflect them.

---

## Phase 5 – Structured Text Analysis
- **Action:** Pasted ST code and analysed seal‑in logic.
- **Reason:** To confirm logic correctness.
- **Outcome:** Logic was correct; issue not a coding error.

---

## Phase 6 – Task Priorities
- **Action:** Checked that `VISU_TASK` (priority 31) runs lower than `MainTask` (priority 1).
- **Reason:** To rule out visualisation task starvation.
- **Outcome:** Priorities correct; not the cause.

---

## Phase 7 – User Restrictions and Input Profile
- **Action:** Verified WebVisu not excluded from build, no security locks, input profile set to “Mouse/Keyboard”.
- **Reason:** To eliminate configuration blocks.
- **Outcome:** No restriction active.

---

## Phase 8 – Compiler Crash (Missing `browsercontrol_ext`)
- **Action:** Excluded WebVisu from build; warning appeared: `The extension 'VisuNativeControl.browsercontrol_ext' could not be found.`
- **Reason:** To identify why visual engine crashed.
- **Outcome:** CODESYS software simulator cannot run required browser extension – pointed toward runtime mismatch.

---

## Phase 9 – Raspberry Pi Context Shift
- **Action:** Revealed that project was compiled for physical Raspberry Pi SL runtime, not PC simulation.
- **Reason:** Because error only made sense considering target platform.
- **Outcome:** **Critical insight** – Windows editor canvas cannot simulate WebVisu interactions for remote Linux target.

---

## Phase 10 – Cascade of Corrupted Errors
- **Action:** Performed “Update Device” to align project with Pi firmware; project threw 18+ errors: “Input action uses invalid variable.”
- **Reason:** To force a clean re‑link between project and hardware.
- **Outcome:** Device update corrupted visualisation metadata, breaking all variable bindings.

---

## Phase 11 – Engine Reset and Purge
- **Action:** Deleted Visualization Manager, created temporary screen to force rebuild of clean manager, then deleted temporary screen.
- **Reason:** To purge corrupted auto‑generated code.
- **Outcome:** Errors disappeared; property fields editable. **But buttons still not responding.**

---

## Phase 12 – Cycle‑Speed Conflict
- **Action:** Added reset commands at end of ST code to clear `StartCmd`/`StopCmd` after motor state changed. Tried `Toggle` button mode.
- **Reason:** To prevent PLC from wiping command before HMI could read it.
- **Outcome:** Buttons became sluggish and still not working – reset commands executing too fast, dropping signal.

---

## Phase 13 – Bypassing via Script Actions
- **Action:** Replaced standard button bindings with **OnMouseDown** scripts that directly wrote `GVL.StartCmd := TRUE;` using Execute ST Code.
- **Reason:** To bypass Tap/Toggle mechanisms.
- **Outcome:** Even with scripts, editor canvas did not register clicks. **Confirmed editor itself not forwarding mouse events to runtime.**

---

## Phase 14 – Final Target Discovery
- **Action:** Concluded that CODESYS editor tab is **not a live test environment** for remote Raspberry Pi target – it is a layout designer only.
- **Reason:** All evidence pointed to design limitation, not a bug.
- **Outcome:** Debugging stopped. Correct test is via external web browser (`http://<Pi‑IP>:8080/webvisu.htm`).

---

## Why Debugging Was Stopped

1. Root cause identified (editor canvas non‑interactive for remote targets).
2. Motor logic already proven via variable forcing.
3. Diminishing returns – all reasonable configuration checks exhausted.
4. Emotional energy preserved for other project parts (Docker, networking).

---

## Impact on Commissioning Report

- **Motor control logic** fully verified via forcing – all tests passed.
- **WebVisu HMI tests** incomplete – buttons never responded in editor.
- Commissioning log updated to distinguish between **logic verified** and **HMI pending browser test**.

---

## Mental Note – Forgotten Documentation

- **Missed:** Documenting exact moment when buttons stopped responding.
- **Why helpful:** Could have narrowed cause (e.g., after device update = metadata corruption).
- **Why not critical:** Final discovery was design limitation, not regression.
- **Future action:** Create checklist of expected behaviours and note first failure step.

---

## Next Steps

1. Create minimal test project (one variable, one button, one lamp).
2. Compile and download to Pi.
3. Open web browser on laptop to `http://<Pi‑IP>:8080/webvisu.htm`.
4. Verify button toggles lamp.
5. Return to main project, include WebVisu in build, test motor buttons via browser.

---

*End of WebVisu Troubleshooting Log – logic verified, HMI pending browser validation.*

