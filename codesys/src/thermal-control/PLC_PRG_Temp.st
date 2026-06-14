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

