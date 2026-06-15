
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

(* In Codesys, this is added right after motor seal-in logic *)

(* =========================
   Temperature Control Logic
   ========================= *)

(* In this simulation, temperature rises when heating and falls when it isn't, no active cooling *)
(* PLC Cycle is approximately 10 ms, adjust accordingly *)

IF GVL_Temp.HeatOutput THEN
	GVL_Temp.SimTemp := GVL_Temp.SimTemp + 0.001;
ELSE
	GVL_Temp.SimTemp := GVL_Temp.SimTemp - 0.0006;
END_IF

GVL_Temp.CurrentTemp := GVL_Temp.SimTemp;

(* Hysteresis on/off Control *)
(* Heat ON when temp falls below setpoint minus deadband *)
(* Heat OFF when temp rises above setpoint plus deadband *)

IF GVL_Temp.CurrentTemp < (GVL_Temp.Setpoint - 1.0) THEN
	GVL_Temp.HeatOutput := TRUE;
ELSIF GVL_Temp.CurrentTemp > (GVL_Temp.Setpoint + 1.0) THEN
	GVL_Temp.HeatOutput := FALSE;
END_IF

(* Fan Proof Check *)

GVL_Fan.FanProofTimer(IN := GVL.MotorOut AND NOT GVL_Fan.FanProofSignal, PT := T#5S);

IF GVL_Fan.FanProofTimer.Q THEN
	GVL_Fan.FanFaultAlarm := TRUE;
END_IF


