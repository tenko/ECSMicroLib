MODULE ARMv7MSTM32SysTick0 IN Micro;

	(*
		Alexander Shiryaev, 2015.03, 2016.04
        Modified by Tenko for use with ECS
        
		SysTick timer for producing periodic events
	*)

	IMPORT SYSTEM, ARMv7M IN Micro;

	VAR flag: BOOLEAN;

	PROCEDURE SysTickIntHandler ["isr_systick"] ();
	BEGIN flag := TRUE;
	END SysTickIntHandler;
    
	PROCEDURE Init* (HCLK, freq: INTEGER);
		CONST
			(* SYSTCSR bits: *)
				ENABLE = 0; TICKINT = 1; CLKSOURCE = 2;
		VAR x: INTEGER;
	BEGIN
		SYSTEM.PUT(ARMv7M.SYSTCSR, SET32({})); (* disable SysTick *)
		flag := FALSE;
		(* NOTE: timer is 24-bit! *)
		(* http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0552a/Babieigh.html *)
			x := HCLK DIV 8 DIV freq - 1;
			ASSERT(x > 0);
			ASSERT(x < 1000000H);
			SYSTEM.PUT(ARMv7M.SYSTRVR, x);
		SYSTEM.PUT(ARMv7M.SYSTCVR, SIGNED32(0)); (* any write to current clears it *)
		SYSTEM.PUT(ARMv7M.SYSTCSR, SET32({ENABLE,TICKINT})) (* enable timer with clock source of HCLK/8 with interrupts *)
	END Init;

	PROCEDURE OnTimer* (): BOOLEAN;
		VAR res: BOOLEAN;
	BEGIN
		res := flag; IF res THEN flag := FALSE END;
	RETURN res
	END OnTimer;

END ARMv7MSTM32SysTick0.
