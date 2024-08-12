MODULE STM32F4System IN Micro;

	(*
		Alexander Shiryaev, 2021.08
        Modified by Tenko for use with ECS

		RM0368, Reference manual,
			STM32F401x{B,C,D,E}

		RM0383, Reference manual,
			STM32F411xC/E

		RM0090, Reference manual,
			STM32F405xx/07xx, STM32F415xx/17xx,
			STM32F42xxx, STM32F43xxx

		RM0390, Reference manual,
			STM32F446xx
	*)
	IMPORT SYSTEM;
    IN Micro IMPORT  ARMv7M, MCU := STM32F4;

	CONST
		fHSI = 16000000; (* Hz *)

		(* PLLSRC *)
			HSI = 0; HSE = 1;

		(* RCCCR bits: *)
			HSION = 0; HSIRDY = 1; HSEON = 16; HSERDY = 17; HSEBYP = 18;
			CSSON = 19; PLLON = 24; PLLRDY = 25;

		(* RCCAPB1ENR bits: *)
			WWDGEN = 11; PWREN = 28;

		(* FLASHACR bits: *)
			PRFTEN = 8; ICEN = 9; DCEN = 10; ICRST = 11; DCRST = 12;

	VAR
		HCLK*,
		PCLK1*, TIMCLK1*,
		PCLK2*, TIMCLK2*,
		QCLK*,
		RCLK*: INTEGER; (* Hz *)
			(* QCLK <= 48 MHz, best is 48 MHz *)
	PROCEDURE SetSysClock (PLLSRC: INTEGER);
		CONST
			(* PWRCR bits: *)
				VOS0 = 14; VOS1 = 15; ODEN = 16; ODSWEN = 17;
			(* PWRCSR bits: *)
				ODRDY = 16; ODSWRDY = 17;
		VAR x: SET;
			id: INTEGER;
			fHSE: INTEGER; (* Hz *)
			PLLM: INTEGER;
			VOS: SET;
			HPREN, PPRE1N, PPRE2N: INTEGER;
			fVCOIn: INTEGER; (* Hz *) (* 1 MHz <= fVCOIn <= 2 MHz, up is best *)
			fVCOOut, fPLLOut: INTEGER;
			PLLN: INTEGER;
			PLLP: INTEGER; (* 2 | 4 | 6 | 8 *)
			PLLQ: INTEGER; (* 2 <= PLLQ <= 15 *)
			PLLR: INTEGER; (* 2 <= PLLR <= 7 *)
			flashLatency: INTEGER; (* WS *)
	BEGIN
		fHSE := 8000000;
		fVCOIn := 2000000;
		PLLR := 2;
		SYSTEM.GET(MCU.DBGMCUIDCODE, id); id := id MOD 1000H;
        
        IF (id = 413H) OR (id = 0) THEN (* STM32F4{0,1}{5,7} *) (* note : qemu return 0 *)
			VOS := {VOS0}; (* fHCLKmax = 168 MHz *)
			(* fPCLK2 <= 90 MHz *)
			(* fPCLK1 <= 45 MHz *)
			HPREN := 0; PPRE2N := 1; PPRE1N := 2;
			(* 50 <= PLLN <= 432 *)
				(* PLLN := 168; *)
				PLLN := 160; (* to reach I2C clock of 400 kHz *)
			(* 100 MHz <= fVCOOut <= 432 MHz *)
			PLLP := 2;
			(* QCLK := 48000000; *)
			QCLK := 40000000;
			flashLatency := 5 (* 2.7--3.6 (V), 150 < HCLK <= 168 (MHz) *)
		ELSIF id = 419H THEN (* STM32F4{2,3}x *)
			fHSE := 24000000;
			VOS := {VOS0,VOS1}; (* fHCLKmax = 180 MHz *)
			HPREN := 0; PPRE2N := 1; PPRE1N := 2;
			(* 50 <= PLLN <= 432 *)
				(* PLLN := 180; *)
				PLLN := 160; (* to reach I2C clock of 400 kHz *)
			(* 100 MHz <= fVCOOut <= 432 MHz *)
			PLLP := 2;
			(* QCLK := 48000000; *)
			QCLK := 40000000;
			flashLatency := 5 (* 2.7--3.6 (V), 150 < HCLK <= 180 (MHz) *)
		ELSIF id = 421H THEN (* STM32F446 *)
			VOS := {VOS0,VOS1}; (* fHCLKmax = 180 MHz *)
			(* fPCLK2 <= 90 MHz *)
			(* fPCLK1 <= 45 MHz *)
			HPREN := 0; PPRE2N := 1; PPRE1N := 2;
			(* 50 <= PLLN <= 432 *)
				(* PLLN := 180; *)
				PLLN := 160; (* to reach I2C clock of 400 kHz *)
			(* 100 MHz <= fVCOOut <= 432 MHz *)
			PLLP := 2;
			(* QCLK := 48000000; *)
			QCLK := 40000000;
			flashLatency := 5 (* 2.7--3.6 (V), 150 < HCLK <= 180 (MHz) *)
		ELSIF (id = 423H) OR (id = 433H) THEN (* STM32F401x{B,C,D,E} *)
			fHSE := 25000000;
			VOS := {VOS1}; (* fHCLKmax = 84 MHz *)
			(* fPCLK2 <= 84 MHz *)
			(* fPCLK1 <= 42 MHz *)
			HPREN := 0; PPRE2N := 0; PPRE1N := 1;
			fVCOIn := 1000000;
			(* 192 <= PLLN <= 432 *)
				(* PLLN := 336; *)
				PLLN := 320; (* to reach I2C clock of 400 kHz *)
			(* 192 MHz <= fVCOOut <= 432 MHz *)
			PLLP := 4;
			(* QCLK := 48000000; *)
			QCLK := 40000000;
			flashLatency := 2 (* 2.7--3.6 (V), 60 < HCLK <= 84 (MHz) *)
		ELSIF id = 431H THEN (* STM32F411x{C,E} *)
			VOS := {VOS0,VOS1}; (* fHCLKmax = 100 MHz *)
			(* fPCLK2 <= 100 MHz *)
			(* fPCLK1 <= 50 MHz *)
			HPREN := 0; PPRE2N := 0; PPRE1N := 1;
			(* 50 <= PLLN <= 432 *)
				PLLN := 100; (* to reach I2C clock of 400 kHz *)
			(* 100 MHz <= fVCOOut <= 432 MHz *)
			PLLP := 2;
			(* QCLK := 48000000; *)
			QCLK := 40000000;
			flashLatency := 3 (* 2.7--3.6 (V), 90 < HCLK <= 100 (MHz) *)
		ELSE
			REPEAT UNTIL FALSE (* HALT *)
		END;
		fVCOOut := fVCOIn * PLLN;
		fPLLOut := fVCOOut DIV PLLP;
		PLLQ := (fVCOOut - 1) DIV QCLK + 1;
		QCLK := fVCOOut DIV PLLQ;
		RCLK := fVCOOut DIV PLLR;
		HCLK := SYSTEM.LSH(fPLLOut, -HPREN);
		PCLK1 := SYSTEM.LSH(HCLK, -PPRE1N);
		PCLK2 := SYSTEM.LSH(HCLK, -PPRE2N);
		IF PPRE1N = 0 THEN
			TIMCLK1 := PCLK1
		ELSE
			TIMCLK1 := PCLK1 * 2
		END;
		IF PPRE2N = 0 THEN
			TIMCLK2 := PCLK2
		ELSE
			TIMCLK2 := PCLK2 * 2
		END;

        IF PLLSRC = HSE THEN
			(* Enable HSE *)
				SYSTEM.GET(MCU.RCCCR, x);
				SYSTEM.PUT(MCU.RCCCR, x + {HSEON});
			REPEAT UNTIL SYSTEM.BIT(MCU.RCCCR, HSERDY)
		ELSE
			REPEAT UNTIL SYSTEM.BIT(MCU.RCCCR, HSIRDY)
		END;

	END SetSysClock;

	PROCEDURE Init;
		CONST MT = 6; (* compiler-dependent *)
			(* ARMv7M.FPCCR bits: *)
				LSPEN = 30;
		VAR x: SET;
	BEGIN
		(* system_stm32f4xx.c, SystemInit: *)
			(*
			(* FPU: set CP10 and CP11 Full Access *)
				SYSTEM.GET(ARMv7M.CPACR, x);
				SYSTEM.PUT(ARMv7M.CPACR, x + {2*10,2*10+1,2*11,2*11+1});
			*)
(*
		(*
			http://www.st.com/web/en/resource/technical/document/errata_sheet/DM00037591.pdf, section 1.2

			http://www.st.com/content/ccc/resource/technical/document/errata_sheet/c3/6b/f8/32/fc/01/48/6e/DM00155929.pdf/files/DM00155929.pdf/jcr:content/translations/en.DM00155929.pdf, section 1.2
		*)

			(* Disable lazy context save of floating point state *)
				SYSTEM.GET(ARMv7M.FPCCR, x);
				SYSTEM.PUT(ARMv7M.FPCCR, x - {LSPEN});
*)

			(* RCC *)
				(* Reset clock configuration to the default reset state *)
					SYSTEM.GET(MCU.RCCCR, x);
					SYSTEM.PUT(MCU.RCCCR, x + {HSION});
				(* Reset CFGR register *)
					SYSTEM.PUT(MCU.RCCCFGR, {});
				(* Reset HSEON, CSSON and PLLON bits *)
					SYSTEM.GET(MCU.RCCCR, x);
					SYSTEM.PUT(MCU.RCCCR, x - {HSEON,CSSON,PLLON});
				(* Reset PLLCFGR register *)
					SYSTEM.PUT(MCU.RCCPLLCFGR, INTEGER(24003010H));
				(* Reset HSEBYP bit *)
					SYSTEM.GET(MCU.RCCCR, x);
					SYSTEM.PUT(MCU.RCCCR, x - {HSEBYP});
				(* Disable all interrupts *)
					SYSTEM.PUT(MCU.RCCCIR, SET32({}));
		SetSysClock(HSE);
	END Init;

BEGIN
	Init
END STM32F4System.   