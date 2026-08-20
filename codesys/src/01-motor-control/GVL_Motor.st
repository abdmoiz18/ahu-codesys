{attribute 'qualified_only'}
VAR_GLOBAL
    (* Inputs - Commands from HMI *)
	StartCmd        : BOOL;
    StopCmd         : BOOL;
    ResetCmd        : BOOL;
    EStop           : BOOL;
    OverloadTrip    : BOOL;
    
    (* Internal *)
    MotorInternal  : BOOL;
    OverloadMem     : BOOL;
    
    (* Outputs - Status to HMI *)
    MotorOut     : BOOL;
    OverloadAlarm   : BOOL;
	
	(* Motor Start Counter *)
	MotorStartCount : WORD;
	ResetCounterCmd : BOOL;
	StartCounter : CTU;
	MotorOutRising : R_TRIG;
	
	SystemShutdown : BOOL; (* For LD logic only *)
END_VAR
