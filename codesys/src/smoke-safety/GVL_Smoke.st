{attribute 'qualified_only'}
VAR_GLOBAL
	(* Inputs *)
	SmokeDetected : BOOL;
	ResetSmoke : BOOL;
	
	(* Internal *)
	SmokeAlarmMem : BOOL;
	
	(* Outputs *)
	SmokeAlarm : BOOL;
END_VAR
