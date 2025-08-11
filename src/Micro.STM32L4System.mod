MODULE STM32L4System IN Micro;
(*
	Alexander Shiryaev, 2021.08
    Modified by Tenko for use with ECS

	RM0394, Reference manual STM32L41xxx/42xxx/43xxx/44xxx/45xxx/46xxx
*)
IMPORT SYSTEM;
IN Micro IMPORT ARMv7M;
IN Micro IMPORT MCU := STM32L4;

CONST
    (* Clocks *)
    fMSI* = 4000000;  (* Hz multi-speed internal oscillator *)
    fHSI* = 16000000; (* Hz high speed internal oscillator *)
    fHSE* = 24000000; (* Hz external crystal *)

    (* PLLSRC *)
    HSI* = 0; HSE* = 1;
    
    (* RCCCR bits: *)
	MSION = 0; MSIRDY = 1; HSION = 8; HSIRDY = 10;
	HSEON = 16; HSERDY = 17; HSEBYP = 18 ; CSSON = 19;
	PLLON = 24; PLLRDY = 25;

	(* RCCAPB1ENR bits: *)
	PWREN = 28;

VAR
	HCLK*,
	PCLK1*,
	PCLK2*,
	PCLK*,
	QCLK*, (* QCLK <= 48 MHz, best is 48 MHz *)
	RCLK* : INTEGER; (* Hz *)

(*
	Configures the System clock source,
		PLL Multiplier and Divider factors,
		AHB/APBx prescalers and Flash settings
	PLLSRC: HSI | HSE
	NOTE:
		should be called only once the RCC clock configuration
		is reset to the default reset state (done in Init)
*)
PROCEDURE SetPLLSysClock*(PLLSRC: INTEGER);
CONST
    fVCOIn = 8000000; (* Hz *) (* 4 MHz <= fVCOIn <= 16 MHz, up is best *)
    PLLR = 2; (* 2 <= PLLR <= 8 *)
    PLLP = 2; (* 2 <= PLLP <= 31 *)
    (* fPCLK2 <= 80 MHz *)
	(* fPCLK1 <= 80 MHz *)
	HPREN = 0; PPRE2N = 1; PPRE1N = 2;
    (* 8 <= PLLN <= 86 *)
	PLLN = 16; (* 64 MHz <= fVCOOut <= 344 MHz *)
	(* PWRCR bits: *)
	VOS0 = 9; VOS1 = 10;
	(* PWRSR2 bits: *)
	VOSF = 10;
	(* RCC_PLLCFGR bits: *)
	PLLREN = 24;
	(* FLASHACR bits: *)
	PRFTEN = 8; ICEN = 9; DCEN = 10;
    flashLatency = 4; (* 2.7--3.6 (V), 64 < HCLK <= 80 (MHz) *)
VAR
    x: SET32;
	PLLM, PLLQ, fVCOOut, fPLLOut: INTEGER;
BEGIN
    QCLK := 40000000;
    fVCOOut := fVCOIn * PLLN;
    PLLQ := (fVCOOut - 1) DIV QCLK + 1;
    PCLK := fVCOOut DIV PLLP;
    QCLK := fVCOOut DIV PLLQ;
    RCLK := fVCOOut DIV PLLR;
    HCLK := ASH(RCLK, -HPREN);
	PCLK1 := ASH(HCLK, -PPRE1N);
	PCLK2 := ASH(HCLK, -PPRE2N);

	SYSTEM.GET(MCU.RCC_CR, x);
	IF PLLSRC = HSE THEN
		(* Enable HSE *)
		SYSTEM.PUT(MCU.RCC_CR, x + {HSEON});
		REPEAT UNTIL SYSTEM.BIT(MCU.RCC_CR, HSERDY)
	ELSE
		(* Enable HSI *)
		SYSTEM.PUT(MCU.RCC_CR, x + {HSION});
		REPEAT UNTIL SYSTEM.BIT(MCU.RCC_CR, HSIRDY)
	END;
	
    (* Enable PWR power *)
    SYSTEM.GET(MCU.RCC_APB1ENR1, x);
    SYSTEM.PUT(MCU.RCC_APB1ENR1, x + {PWREN});

    (* Select the Voltage Range 1 *)
    SYSTEM.GET(MCU.PWR_CR1, x);
    SYSTEM.PUT(MCU.PWR_CR1, x - {VOS1} + {VOS0});
    REPEAT UNTIL ~SYSTEM.BIT(MCU.PWR_SR2, VOSF);

    SYSTEM.GET(MCU.RCC_CFGR, x);
	SYSTEM.PUT(MCU.RCC_CFGR, x - {4..7}
		+ SET32((HPREN + 7) * 10H));

	SYSTEM.GET(MCU.RCC_CFGR, x);
	SYSTEM.PUT(MCU.RCC_CFGR, x - {11,12,13}
		+ SET32((PPRE2N + 3) * 800H));

	SYSTEM.GET(MCU.RCC_CFGR, x);
	SYSTEM.PUT(MCU.RCC_CFGR, x - {8,9,10}
		+ SET32((PPRE1N + 3) * 100H));
		
    (* Configure the main PLL *)
	IF PLLSRC = HSE THEN PLLM := fHSE DIV fVCOIn
	ELSE PLLM := fHSI DIV fVCOIn
	END; (* 1 <= PLLM <= 8 *)
    
    SYSTEM.PUT(MCU.RCC_PLLCFGR, 2 + PLLSRC
    	+ (PLLM - 1) * 10H + PLLN * 100H
		+ (PLLQ DIV 2 - 1) * 200000H
		+ 1000000H (* PLLREN *)
		+ (PLLR DIV 2 - 1) * 2000000H
		+ PLLP * 8000000H);
		
    (* Enable the main PLL *)
	SYSTEM.GET(MCU.RCC_CR, x);
	SYSTEM.PUT(MCU.RCC_CR, x + {PLLON});
	REPEAT UNTIL SYSTEM.BIT(MCU.RCC_CR, PLLRDY);
	
	(* Configure Flash prefetch, Instruction cache, Data cache and wait state *)
	SYSTEM.PUT(MCU.FLASH_ACR, {PRFTEN,ICEN,DCEN}
				+ SET32(flashLatency));

	(* Select the main PLL as system clock source *)
	SYSTEM.GET(MCU.RCC_CFGR, x);
	SYSTEM.PUT(MCU.RCC_CFGR, x - {0,1});
	SYSTEM.GET(MCU.RCC_CFGR, x);
	SYSTEM.PUT(MCU.RCC_CFGR, x + {0,1});
	REPEAT SYSTEM.GET(MCU.RCC_CFGR, x) UNTIL x * {2,3} = {2,3};
END SetPLLSysClock;

PROCEDURE Init*;
VAR x: SET32;
BEGIN
    (* RCC *)
    (* Reset clock configuration to the default reset state *)
    SYSTEM.GET(MCU.RCC_CR, x);
    SYSTEM.PUT(MCU.RCC_CR, x + {MSION});
    (* Reset CFGR register *)
    SYSTEM.PUT(MCU.RCC_CFGR, SET32({}));
    (* Reset HSEON, CSSON , and PLLON bits *)
    SYSTEM.GET(MCU.RCC_CR, x);
    SYSTEM.PUT(MCU.RCC_CR, x - {HSEON,CSSON,PLLON});
    (* Reset HSEBYP bit *)
	SYSTEM.GET(MCU.RCC_CR, x);
	SYSTEM.PUT(MCU.RCC_CR, x - {HSEBYP});
	(* Disable all interrupts *)
	SYSTEM.PUT(MCU.RCC_CIER, SET32({}));
    (* Default startup clock *)
	HCLK := fMSI;
END Init;

END STM32L4System.