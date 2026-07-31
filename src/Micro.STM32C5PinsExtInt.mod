(**
External pin interrupt. N parameter is pin number and must match
pin number in Init procedure.
*)
MODULE STM32C5PinsExtInt (N*) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ArchArm;
IN Micro IMPORT MCU := STM32C5;
IN Micro IMPORT Pins := STM32C5Pins;
IN Micro IMPORT MachinePinExtInt;

CONST
    Isr = SEL(N = 0, "isr_exti0", SEL(N = 1, "isr_exti1", SEL(N = 2, "isr_exti2", SEL(N = 3, "isr_exti3",
          SEL(N = 4, "isr_exti4", SEL(N = 5, "isr_exti5", SEL(N = 6, "isr_exti6", SEL(N = 7, "isr_exti7",
          SEL(N = 8, "isr_exti8", SEL(N = 9, "isr_exti9", SEL(N = 10, "isr_exti10", SEL(N = 11, "isr_exti11",  
          SEL(N = 12, "isr_exti12", SEL(N = 13, "isr_exti13", SEL(N = 14, "isr_exti14", "isr_exti15"))))))))))))))); 

    Int = SEL(N = 0, MCU.EXTI0Int, SEL(N = 1, MCU.EXTI1Int, SEL(N = 2, MCU.EXTI2Int, SEL(N = 3, MCU.EXTI3Int, 
          SEL(N = 4, MCU.EXTI4Int, SEL(N = 5, MCU.EXTI5Int, SEL(N = 6, MCU.EXTI6Int, SEL(N = 7, MCU.EXTI7Int,
          SEL(N = 8, MCU.EXTI8Int, SEL(N = 9, MCU.EXTI9Int, SEL(N = 10, MCU.EXTI10Int, SEL(N = 11, MCU.EXTI11Int,
          SEL(N = 12, MCU.EXTI12Int, SEL(N = 13, MCU.EXTI13Int, SEL(N = 14, MCU.EXTI14Int,  MCU.EXTI15Int)))))))))))))));

TYPE
    ADDRESS = SYSTEM.ADDRESS;
    PinExtInt* = RECORD (MachinePinExtInt.PinExtInt) END;
    PtrPinExtInt = POINTER TO VAR PinExtInt;

(** Pointer for access to PinExtInt in ISR *)
VAR pinExtInt : PtrPinExtInt;

PROCEDURE InterruptHandler [Isr] ();
VAR x: SET32;
BEGIN
    IF pinExtInt = NIL THEN RETURN END;
	SYSTEM.GET(MCU.EXTI_RPR1, x);
	IF N IN x THEN (* Rising edge *)
        INC(pinExtInt.count);
        pinExtInt.flag := TRUE;
        IF pinExtInt.isrHandle # NIL THEN pinExtInt.isrHandle() END;
        SYSTEM.PUT(MCU.EXTI_RPR1, x + {N});
    END;
    SYSTEM.GET(MCU.EXTI_FPR1, x);
	IF N IN x THEN (* Falling edge *)
        INC(pinExtInt.count);
        pinExtInt.flag := TRUE;
        IF pinExtInt.isrHandle # NIL THEN pinExtInt.isrHandle() END;
        SYSTEM.PUT(MCU.EXTI_FPR1, x + {N});
    END;
END InterruptHandler;

(** Software trigger of interrupt *)
PROCEDURE (VAR ext : PinExtInt) Trigger*;
VAR x: SET32;
BEGIN
	SYSTEM.GET(MCU.EXTI_SWIER1, x);
    SYSTEM.PUT(MCU.EXTI_SWIER1, x + {N});
END Trigger;

(** Disable interrupt *)
PROCEDURE (VAR ext : PinExtInt) Disable*;
BEGIN ArchArm.IRQDisable(Int)
END Disable;

(** Enable interrupt *)
PROCEDURE (VAR ext : PinExtInt) Enable*;
BEGIN ArchArm.IRQEnable(Int)
END Enable;

(** Initialize interrupt on pin. Interrups is disabled. *)
PROCEDURE (VAR ext : PinExtInt) Init* (pin- : Pins.Pin; risingEdge, fallingEdge: BOOLEAN);
VAR
    x: SET32;
    reg : ADDRESS;
    ofs : INTEGER;
BEGIN
    ASSERT(pin.pin = N);
    pinExtInt := PTR(ext);
	ext.count := 0;
	ext.flag := FALSE;
	(* Disable interrupt *)
    ext.Disable();
    (* Interrupt selection register *)
    IF N < 4 THEN
        reg := MCU.EXTI_EXTICR1;
        ofs := 8*N;
    ELSIF N < 8 THEN
        reg := MCU.EXTI_EXTICR2;
        ofs := 8*(N - 4);
    ELSIF N < 12 THEN
        reg := MCU.EXTI_EXTICR3;
        ofs := 8*(N - 8);
    ELSE
        reg := MCU.EXTI_EXTICR4;
        ofs := 8*(N - 12);
    END;
    SYSTEM.GET(reg, x);
    SYSTEM.PUT(reg, x - SET32({(0+ofs) .. (7+ofs)}) + SET32(SYSTEM.LSH(pin.port, ofs)));
    (* Interrupt mask register *)
    SYSTEM.GET(MCU.EXTI_IMR1, x);
    SYSTEM.PUT(MCU.EXTI_IMR1, x + {N});
    (* Event mask register *)
    SYSTEM.GET(MCU.EXTI_EMR1, x);
    SYSTEM.PUT(MCU.EXTI_EMR1, x - {N});
    (* risingEdge *)
    SYSTEM.GET(MCU.EXTI_RTSR1, x);
    IF risingEdge THEN
        SYSTEM.PUT(MCU.EXTI_RTSR1, x + {N});
    ELSE
        SYSTEM.PUT(MCU.EXTI_RTSR1, x - {N});
    END;
    (* fallingEdge *)
    SYSTEM.GET(MCU.EXTI_FTSR1, x);
    IF fallingEdge THEN
        SYSTEM.PUT(MCU.EXTI_FTSR1, x + {N});
    ELSE
        SYSTEM.PUT(MCU.EXTI_FTSR1, x - {N});
    END;
END Init;

END STM32C5PinsExtInt.