(*  =====================================================
    Smoke alarm latch - stays active until manually reset 
    ===================================================== *)
GVL_Smoke.SmokeAlarmMem := (GVL_Smoke.SmokeDetected OR GVL_Smoke.SmokeAlarmMem) AND NOT GVL_Smoke.ResetSmoke;

(* Smoke Alarm Output *)
GVL_Smoke.SmokeAlarm := GVL_Smoke.SmokeAlarmMem;

(* ===================
   Motor seal-in logic 
   ===================*)
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

(* ===================
   Motor Start Counter 
   =================== *)

GVL.MotorOutRising(CLK := GVL.MotorOut);
GVL.StartCounter(CU := GVL.MotorOutRising.Q,
	             RESET := GVL.ResetCounterCmd,
				 PV := 9999);
GVL.MotorStartCount := GVL.StartCounter.CV;

(* ===============
   Fan Proof Check 
   =============== *)

GVL_Fan.FanProofTimer(IN := GVL.MotorOut AND NOT GVL_Fan.FanProofSignal, PT := T#5S);

IF GVL_Fan.FanProofTimer.Q THEN
	GVL_Fan.FanFaultAlarm := TRUE;
END_IF

(* =========================
   Temperature Control Logic
   ========================= *)

(* In this simulation, temperature rises when heating and falls when it isn't, no active cooling *)
(* PLC Cycle is approximately 10 ms, adjust accordingly *)

IF NOT GVL_Smoke.SmokeAlarmMem THEN
    (* Only run simulation if no smoke *)
    IF GVL_Temp.HeatOutput THEN
        GVL_Temp.SimTemp := GVL_Temp.SimTemp + 0.001;
    ELSE
        GVL_Temp.SimTemp := GVL_Temp.SimTemp - 0.0006;
    END_IF
END_IF

GVL_Temp.CurrentTemp := GVL_Temp.SimTemp;

(*  =========================
    Hysteresis on/off Control 
    ========================= *)
(* Heat ON when temp falls below setpoint minus deadband *)
(* Heat OFF when temp rises above setpoint plus deadband *)

IF GVL_Smoke.SmokeAlarmMem THEN
    GVL_Temp.HeatOutput := FALSE;   // Smoke overrides
ELSIF GVL_Temp.CurrentTemp < (GVL_Temp.Setpoint - 1.0) THEN
	GVL_Temp.HeatOutput := TRUE;
ELSIF GVL_Temp.CurrentTemp > (GVL_Temp.Setpoint + 1.0) THEN
	GVL_Temp.HeatOutput := FALSE;
END_IF

(* ===========================
   Freeze Protection Detection
   =========================== *)

(* If air temp drops below 5 C, latch the freeze alarm *)
IF GVL_Temp.CurrentTemp < 5.0 THEN
	GVL_Temp.FreezeAlarmMem := TRUE;
END_IF

(* Output to HMI *)
GVL_Temp.FreezeAlarm := GVL_Temp.FreezeAlarmMem;

(* =====================================
   ALARM TEXT PRIORITISATION
   ===================================== *)
(* Highest priority first *)
IF GVL_Temp.FreezeAlarmMem THEN
    GVL_Temp.AlarmText := 'FREEZE PROTECTION - SYSTEM SHUTDOWN';
ELSIF GVL_Smoke.SmokeAlarmMem THEN
    GVL_Temp.AlarmText := 'SMOKE ALARM - SYSTEM SHUTDOWN';
ELSIF GVL.OverloadAlarm THEN
    GVL_Temp.AlarmText := 'OVERLOAD TRIPPED - MOTOR OFF';
ELSE
    GVL_Temp.AlarmText := 'NORMAL OPERATION';
END_IF

(* =====================================
   SAFETY OVERRIDE (Smoke + Freeze + EStop)
   ===================================== *)
(* Shut down ALL outputs if any safety condition is active *)
IF GVL_Smoke.SmokeAlarmMem OR GVL_Temp.FreezeAlarmMem OR GVL.EStop THEN
    GVL.MotorInternal := FALSE;     (* Break seal-in *)
    GVL.MotorOut := FALSE;          (* Stop motor *)
    GVL_Temp.HeatOutput := FALSE;   (* Turn off heating *)
END_IF
