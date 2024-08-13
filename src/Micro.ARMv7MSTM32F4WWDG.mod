MODULE ARMv7MSTM32F4WWDG;

	(*
		Alexander Shiryaev, 2018.05, 2019.10
        Modified by Tenko for use with ECS
        
		RM0090, Reference manual,
			STM32F4{0,1}{5,7}xx, STM32F4{2,3}{7,9}xx
	*)

	IMPORT SYSTEM;
    IN Micro IMPORT ARMv7M, ARMv7MTraps, MCU := STM32F4;

	CONST
		(* WDGTB values: *)
			WDGTB1* = 0; WDGTB2* = 1; WDGTB4* = 2; WDGTB8* = 3;
			WDGTBMax* = WDGTB8;
		(* W values: *)
			WMax* = 127;
		(* T values: *)
			TMax* = 63;

		SP = 13;
		SR0 = 0; SR1 = 1; SR2 = 2; SR3 = 3; SR12 = 4; SLR = 5; SPC = 6;

		(* interrupt sources *)
			WWDGInt = 0;

		Int = WWDGInt;
		int = Int MOD 32;
		ISER = ARMv7M.NVICISER0 + (Int DIV 32) * 4;
		ICER = ARMv7M.NVICICER0 + (Int DIV 32) * 4;
		IPR = ARMv7M.NVICIPR0 + Int;

		(* WWDGCR bits: *)
			WDGA = 7;

	VAR cr: SET;

    PROCEDURE TrapHandler ["isr_wwdg"];
	VAR
        ptr : SYSTEM.ADDRESS;
        context: POINTER TO ARMv7MTraps.Context;
	BEGIN
		SYSTEM.ASM("
            mov     r0, r11
            mov     r1, sp
            str	    r1, [r0, ptr]
        ");
        ARMv7MTraps.trapHandler(14H (* 20 *), context^);
	END TrapHandler;

	PROCEDURE Update*;
	BEGIN
		SYSTEM.PUT(MCU.WWDGCR, cr)
	END Update;

	(* timeout = 4096 * 2^WDGTB / PCLK1 * (T + 1) *)
	PROCEDURE Init* (WDGTB, W, T: INTEGER);
		CONST
			(* RCCAPB1ENR bits: *)
				WWDGEN = 11;
			(* WWDGCFR bits: *)
				EWI = 9;
			(* WWDGSR bits: *)
				EWIF = 0;
		VAR x: SET;
			i: INTEGER;
	BEGIN
		ASSERT(WDGTB DIV 4 = 0);
		ASSERT(W DIV 80H = 0);
		ASSERT(T DIV 40H = 0);

		SYSTEM.PUT(ICER, SET32({int})); ARMv7M.ISB;

		SYSTEM.GET(MCU.RCCAPB1ENR, x);
		SYSTEM.PUT(MCU.RCCAPB1ENR, x + {WWDGEN}); ARMv7M.DSB;

		SYSTEM.PUT(MCU.WWDGCFR,
			SYSTEM.VAL(SET, W + WDGTB * 80H) + {EWI}); (* W, WDGTB, EWI *)

		(* decrease priority of all interrupts *)
			i := 0;
			WHILE i < 60 DO
				SYSTEM.PUT(ARMv7M.NVICIPR0 + i, SIGNED32(80808080H)); (* set priorities to 8 *)
				INC(i)
			END;
		(* increase priority of WWDG interrupts *)
			SYSTEM.PUT(IPR, SIGNED32(0X)); (* set priority to 0 *)

		SYSTEM.GET(MCU.WWDGSR, x);
		SYSTEM.PUT(MCU.WWDGSR, x - {EWIF});

		cr := SYSTEM.VAL(SET, T + 40H) + {WDGA};

		SYSTEM.PUT(MCU.WWDGCR, cr); (* enable *)

		SYSTEM.PUT(ISER, SET32({int}))
	END Init;

END ARMv7MSTM32F4WWDG.
