MODULE ArchArmSysTick IN Micro;
(*
	Alexander Shiryaev, 2015.03, 2016.04
    Modified by Tenko for use with ECS
    
	SysTick timer for producing periodic events.
	Note that some modules expect the frequency to be 1000 (milli seconds)
*)

IMPORT SYSTEM, ArchArm IN Micro;

VAR
    tick-: UNSIGNED32;
	flag: BOOLEAN;

PROCEDURE ^ DelayIdle ["delay_idle"] ();

PROCEDURE SysTickIntHandler ["isr_systick"] ();
BEGIN
    INC(tick);
	flag := TRUE;
END SysTickIntHandler;

PROCEDURE Enabled*(): BOOLEAN;
CONST ENABLE = 0;
BEGIN RETURN SYSTEM.BIT(ArchArm.SYST_CSR, ENABLE)
END Enabled;

PROCEDURE Enable*;
CONST ENABLE = 0;
VAR x: SET32;
BEGIN
	SYSTEM.GET(ArchArm.SYST_CSR, x);	
	SYSTEM.PUT(ArchArm.SYST_CSR, x + {ENABLE})
END Enable;

PROCEDURE Disable*;
CONST ENABLE = 0;
VAR x: SET32;
BEGIN
	SYSTEM.GET(ArchArm.SYST_CSR, x);	
	SYSTEM.PUT(ArchArm.SYST_CSR, x - {ENABLE})
END Disable;

PROCEDURE Init* (HCLK, hz: INTEGER);
CONST
   (* SYSTCSR bits: *)
   ENABLE = 0; TICKINT = 1; CLKSOURCE = 2;
VAR
	x: INTEGER;
BEGIN
	SYSTEM.PUT(ArchArm.SYST_CSR, SET32({})); (* disable SysTick *)
	IF hz <= 0 THEN RETURN END;
	tick := 0;
	flag := FALSE;
	(* NOTE: timer is 24-bit! *)
	(* http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0552a/Babieigh.html *)
	x := HCLK DIV hz - 1;
	ASSERT(x <= 0FFFFFFH);
	SYSTEM.PUT(ArchArm.SYST_RVR, x);
	SYSTEM.PUT(ArchArm.SYST_CVR, SIGNED32(0)); (* any write to current clears it *)
	SYSTEM.PUT(ArchArm.SYST_CSR, SET32({ENABLE,TICKINT, CLKSOURCE})) (* enable timer with clock source of SYSCLOCK with interrupts *)
END Init;

(** Get current ticks *)
PROCEDURE GetTicks* ["ticks_ms"] (): UNSIGNED32;
BEGIN RETURN tick;
END GetTicks;

(** Wait delta number of ticks *)
PROCEDURE Delay* ["delay_ms"] (delta : UNSIGNED32);
VAR t0 : UNSIGNED32;
BEGIN
    t0 := tick;
    WHILE tick - t0 < delta DO DelayIdle END;
END Delay;

(** Wait delta seconds *)
PROCEDURE DelayS* ["delay_s"] (delta : UNSIGNED32);
VAR i : UNSIGNED32;
BEGIN
    FOR i := 0 TO delta - 1 DO
        Delay(1000);
    END;
END DelayS;

PROCEDURE OnTimer* (): BOOLEAN;
VAR res: BOOLEAN;
BEGIN
	res := flag; IF res THEN flag := FALSE END;
    RETURN res
END OnTimer;

END ArchArmSysTick.
