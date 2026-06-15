{attribute 'qualified_only'}
VAR_GLOBAL
	(* Process values *)
	CurrentTemp : REAL := 20.0;
	Setpoint : REAL := 22.0;
	
	(* Control Outputs *)
	HeatOutput : BOOL;
	
	(*Internal Simulation *)
	SimTemp : REAL := 20.0;
	LastCycleTime : REAL;
END_VAR

