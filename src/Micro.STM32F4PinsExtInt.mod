(**
External pin interrupt. N parameter is pin number and must match
pin number in Init procedure,
*)
MODULE STM32F4PinsExtInt (N*) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ARMv7M;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT Pins := STM32F4Pins;

CONST
    Isr = SEL(N = 0, "isr_exti0", SEL(N = 1, "isr_exti1", SEL(N = 2, "isr_exti2",
          SEL(N = 3, "isr_exti3", SEL(N = 4, "isr_exti4", SEL(N < 10, "isr_exti9_5", "isr_exti15_10"))))));

    Int = SEL(N = 0, MCU.EXTI0Int, SEL(N = 1, MCU.EXTI1Int, SEL(N = 2, MCU.EXTI2Int,
          SEL(N = 3, MCU.EXTI3Int, SEL(N = 4, MCU.EXTI4Int, SEL(N < 10, MCU.EXTI95Int, MCU.EXTI1510Int))))));

TYPE
    ADDRESS = SYSTEM.ADDRESS;

VAR
    count- : UNSIGNED32;
    flag : BOOLEAN;
    isrHandle : PROCEDURE;

PROCEDURE InterruptHandler [Isr] ();
VAR x: SET32;
BEGIN
	SYSTEM.GET(MCU.EXTI_PR, x);
	IF N IN x THEN
        INC(count);
        flag := TRUE;
        IF isrHandle # NIL THEN isrHandle() END;
        SYSTEM.PUT(MCU.EXTI_PR, x + {N});
    END;
END InterruptHandler;

(** Set ISR handle *)
PROCEDURE SetHandle*(handle : PROCEDURE);
BEGIN isrHandle := handle
END SetHandle;

(** Check if interrupt is triggered. Clear flag if set. *)
PROCEDURE OnTrigger* (): BOOLEAN;
VAR res: BOOLEAN;
BEGIN
	res := flag; IF res THEN flag := FALSE END;
    RETURN res
END OnTrigger;

(** Software trigger of interrupt *)
PROCEDURE Trigger*;
VAR x: SET32;
BEGIN
	SYSTEM.GET(MCU.EXTI_SWIER, x);
	SYSTEM.PUT(MCU.EXTI_SWIER, x - {N});
    SYSTEM.PUT(MCU.EXTI_SWIER, x + {N});
END Trigger;

(** Disable interrupt *)
PROCEDURE Disable*;
BEGIN
	SYSTEM.PUT(ARMv7M.NVICICER0 + (Int DIV 32) * 4, SET32({Int MOD 32}));
	ARMv7M.ISB;
END Disable;

(** Enable interrupt *)
PROCEDURE Enable*;
BEGIN
	SYSTEM.PUT(ARMv7M.NVICISER0 + (Int DIV 32) * 4, SET32({Int MOD 32}));
END Enable;

(** Initialize interrupt on pin. Interrups is disabled. *)
PROCEDURE Init* (pin- : Pins.Pin; risingEdge, fallingEdge: BOOLEAN);
CONST
   (* RCC_APB2ENR bits: *)
   SYSCFGEN = 14;
VAR
    x: SET32;
    ofs : INTEGER;
    reg : ADDRESS;
BEGIN
    ASSERT(pin.pin = N);
    ASSERT(pin.port <= Pins.I);
	count := 0;
	flag := FALSE;
	isrHandle := NIL;
	(* Disable interrupt *)
    Disable();
	(* enable clock for SYSCFG *)
    SYSTEM.GET(MCU.RCC_APB2ENR, x);
    SYSTEM.PUT(MCU.RCC_APB2ENR, x + {SYSCFGEN});
    (* SYSCFG external interrupt configuration *)
    IF N < 4 THEN
        reg := MCU.SYSCFG_EXTICR1;
        ofs := 4*N;
    ELSIF N < 8 THEN
        reg := MCU.SYSCFG_EXTICR2;
        ofs := 4*(N - 4);
    ELSIF N < 12 THEN
        reg := MCU.SYSCFG_EXTICR3;
        ofs := 4*(N - 8);
    ELSE
        reg := MCU.SYSCFG_EXTICR4;
        ofs := 4*(N - 12);
    END;
    SYSTEM.GET(reg, x);
    SYSTEM.PUT(reg, x - SET32({(0+ofs) .. (3+ofs)}) + SET32(SYSTEM.LSH(pin.port, ofs)));
    (* Interrupt mask register *)
    SYSTEM.GET(MCU.EXTI_IMR, x);
    SYSTEM.PUT(MCU.EXTI_IMR, x + {N});
    (* Event mask register *)
    SYSTEM.GET(MCU.EXTI_EMR, x);
    SYSTEM.PUT(MCU.EXTI_EMR, x - {N});
    (* risingEdge *)
    SYSTEM.GET(MCU.EXTI_RTSR, x);
    IF risingEdge THEN
        SYSTEM.PUT(MCU.EXTI_RTSR, x + {N});
    ELSE
        SYSTEM.PUT(MCU.EXTI_RTSR, x - {N});
    END;
    (* fallingEdge *)
    SYSTEM.GET(MCU.EXTI_RTSR, x);
    IF fallingEdge THEN
        SYSTEM.PUT(MCU.EXTI_FTSR, x + {N});
    ELSE
        SYSTEM.PUT(MCU.EXTI_FTSR, x - {N});
    END;
END Init;

END STM32F4PinsExtInt.