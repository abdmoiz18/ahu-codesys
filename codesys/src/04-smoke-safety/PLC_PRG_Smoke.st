(* ======================
   Smoke Safety Interlock 
   ====================== *)
(* Because safety takes priority over process control, smoke alarm must override motor and heating inputs *)

(* Smoke alarm latch - stays active until manually reset *)
GVL_Smoke.SmokeAlarmMem := (GVL_Smoke.SmokeDetected OR GVL_Smoke.SmokeAlarmMem) AND NOT GVL_Smoke.ResetSmoke;

(* Smoke Alarm Output *)
GVL_Smoke.SmokeAlarm := GVL_Smoke.SmokeAlarmMem;

(* Safety override - shut down all outputs on smoke alarm *)
(* This modifies outputs set by earlier logic sections *)

IF GVL_Smoke.SmokeAlarmMem THEN
	GVL.MotorInternal := FALSE;
	GVL.MotorOut := FALSE;
	GVL_Temp.HeatOutput := FALSE;
END_IF

