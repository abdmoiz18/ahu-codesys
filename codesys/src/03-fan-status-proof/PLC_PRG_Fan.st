(* Fan Proof Check *)

GVL_Fan.FanProofTimer(IN := GVL.MotorOut AND NOT GVL_Fan.FanProofSignal, PT := T#5S);

IF GVL_Fan.FanProofTimer.Q THEN
	GVL_Fan.FanFaultAlarm := TRUE;
END_IF

