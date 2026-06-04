{attribute 'qualified_only'}
VAR_GLOBAL
    (* Inputs - Commands from HMI *)
    StartCmd AT %QX0.0        : BOOL;
    StopCmd AT %QX0.1         : BOOL;
    ResetCmd AT %QX0.2        : BOOL;
    EStop AT %QX0.3           : BOOL;
    OverloadTrip AT %QX0.4    : BOOL;
    
    (* Internal *)
    MotorInternal  : BOOL;
    OverloadMem     : BOOL;
    
    (* Outputs - Status to HMI *)
    MotorOut AT %QX0.5     : BOOL;
    OverloadAlarm AT %QX0.6   : BOOL;
END_VAR
