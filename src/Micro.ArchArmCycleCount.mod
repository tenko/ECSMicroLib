(*
	Cycle count for accurate delays and accurate timing
*)

MODULE ArchArmCycleCount IN Micro;

IMPORT SYSTEM, ArchArm IN Micro;

VAR ^ cpuFreq- ["cpu_freq"]: INTEGER;
    
PROCEDURE Init* (CPUCLK : INTEGER);
CONST
    TRCENA = 24;
    CYCCNTENA = 0;
VAR
	x: SET32;
BEGIN
    cpuFreq := CPUCLK;
    SYSTEM.GET(ArchArm.SCB_DEMCR, x);
    SYSTEM.PUT(ArchArm.SCB_DEMCR, x + {TRCENA});
    SYSTEM.PUT(ArchArm.DWT_CYCCNT, UNSIGNED32(0));
    SYSTEM.GET(ArchArm.DWT_CONTROL, x);
    SYSTEM.PUT(ArchArm.DWT_CONTROL, x + {CYCCNTENA});
END Init;

(** Get current cycle count *)
PROCEDURE GetCount* ["ticks_cpu"] (): UNSIGNED32;
VAR x : UNSIGNED32;
BEGIN
    SYSTEM.GET(ArchArm.DWT_CYCCNT, x);
    RETURN x
END GetCount;

(** Busy wait delay micro seconds *)
PROCEDURE DelayUS* ["delay_us"]  (delay : UNSIGNED32);
VAR t0, ticks : UNSIGNED32;
BEGIN
    t0 := GetCount();
    ticks := delay * (UNSIGNED32(cpuFreq) DIV 1000000);
    WHILE GetCount() - t0 < ticks DO END;
END DelayUS;

END ArchArmCycleCount.
