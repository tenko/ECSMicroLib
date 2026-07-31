MODULE STM32C5RTC IN Micro;
IMPORT SYSTEM;
IN Micro IMPORT ArchArm, MCU := STM32C5, MachineRTC;

CONST
    Int = MCU.RTCInt;

TYPE
	RTC* = RECORD (MachineRTC.RTC)
	END;

(** Initialize RTC. A RTC clock must be started *)
PROCEDURE Init* (VAR rtc : RTC);
CONST
	(* RTC clock *)
	LSI = 2; LSE = 1;
	(* RCC_APB3ENR bits: *)
	RTCAPBEN = 21;
	(* PWR_RTCCR bits: *)
	DRTCP = 0;
	(* RCC_RTCCR bits: *)
	LSERDY = 1; RTCSEL0 = 8; RTCEN = 15;
VAR
	src : INTEGER;
	x: SET32;
BEGIN
	(* Enable RTC APB3 interface clock *)
	SYSTEM.GET(MCU.RCC_APB3ENR, x);
    SYSTEM.PUT(MCU.RCC_APB3ENR, x + {RTCAPBEN});
	(* Disable RTC domain write protection *)
	SYSTEM.GET(MCU.PWR_RTCCR, x);
    SYSTEM.PUT(MCU.PWR_RTCCR, x + {DRTCP});
	(* Select source. LSE selected first if available *)
	IF SYSTEM.BIT(MCU.RCC_RTCCR, LSERDY) THEN
		 src := LSE;
	ELSE src := LSI END;
	(* Set RTC clock source *)
	SYSTEM.GET(MCU.RCC_RTCCR, x);
	SYSTEM.PUT(MCU.RCC_RTCCR, x - {RTCSEL0 + 1, RTCSEL0} + SET32(src * 256));
	(* Enable RTC *)
	SYSTEM.GET(MCU.RCC_RTCCR, x);
    SYSTEM.PUT(MCU.RCC_RTCCR, x + {RTCEN});
END Init;

PROCEDURE InterruptHandler ["isr_rtc"] ();
CONST CWUTF = 2;
VAR x: SET32;
BEGIN
    (* Clear pending interrupt flag *)
	SYSTEM.GET(MCU.RTC_SCR, x);
    SYSTEM.PUT(MCU.RTC_SCR, x + {CWUTF});
END InterruptHandler;

(* Disable interrupt *)
PROCEDURE DisableIRQ;
BEGIN ArchArm.IRQDisable(Int)
END DisableIRQ;

(* Enable interrupt *)
PROCEDURE EnableIRQ;
BEGIN
    ArchArm.IRQSetPriority(Int, MCU.RTCPriority);
    ArchArm.IRQEnable(Int)
END EnableIRQ;

(** Set RTC Wakeup timer delay in seconds.
Setting delay to 0 disable the wakeup timer.
*)
PROCEDURE (VAR rtc : RTC) WakeupS*(delay : INTEGER);
CONST
    (* RTC_SCR bits *)
    CWUTF = 2;
    (* RTC_ICSR bits: *)
    WUTWF = 2; INITF = 6; INIT = 7;
    (* RTC_CR bits: *)
    WUCKSEL0 = 0; WUTE = 10; WUTIE = 14;
    (* EXTI_IMR1 flags *)
    IM17 = 17;
VAR x: SET32;
BEGIN
    ASSERT(delay >= 0);
    ASSERT(delay < 36 * 60 * 60);
    (* Disable interrupt *)
    DisableIRQ;
    (* Unlock RTC write protection *)
    SYSTEM.GET(MCU.RTC_WPR, x);
    SYSTEM.PUT(MCU.RTC_WPR, x + SET8(0CAH));
    SYSTEM.GET(MCU.RTC_WPR, x);
    SYSTEM.PUT(MCU.RTC_WPR, x + SET8(053H));
    (* Stop wakeup timer *)
    SYSTEM.GET(MCU.RTC_CR, x);
    SYSTEM.PUT(MCU.RTC_CR, x - {WUTE});
    REPEAT UNTIL SYSTEM.BIT(MCU.RTC_ICSR, WUTWF);
	IF delay > 0 THEN
		(* Set wakeup clock source to 1s timer *)
		SYSTEM.GET(MCU.RTC_CR, x);
		SYSTEM.PUT(MCU.RTC_CR, x - {WUCKSEL0 + 2 .. WUCKSEL0} + SET32(4));
		(* Set wakeup period *)
		SYSTEM.PUT(MCU.RTC_WUTR, SET32(delay - 1));
		(* Enable wakeup timer and interrupt *)
		REPEAT UNTIL SYSTEM.BIT(MCU.RTC_ICSR, WUTWF);
		SYSTEM.GET(MCU.RTC_CR, x);
		SYSTEM.PUT(MCU.RTC_CR, x + {WUTE, WUTIE});
	END;
    (* Turn on RTC write protection *)
    SYSTEM.GET(MCU.RTC_WPR, x);
    SYSTEM.PUT(MCU.RTC_WPR, x + SET8(0FFH));
	IF delay = 0 THEN
		(* Disable wakeup interrupt *)
		SYSTEM.GET(MCU.EXTI_IMR1, x);
		SYSTEM.PUT(MCU.EXTI_IMR1, x - {IM17});
		(* Event mask register *)
		SYSTEM.GET(MCU.EXTI_EMR1, x);
		SYSTEM.PUT(MCU.EXTI_EMR1, x - {IM17});
		RETURN;
	END;
    (* Enable wakeup interrupt *)
    SYSTEM.GET(MCU.EXTI_IMR1, x);
    SYSTEM.PUT(MCU.EXTI_IMR1, x + {IM17});
    (* Event mask register *)
    SYSTEM.GET(MCU.EXTI_EMR1, x);
    SYSTEM.PUT(MCU.EXTI_EMR1, x - {IM17});
    (* Enable interrupt *)
    EnableIRQ;
    (* Clear pending interrupt flag *)
	SYSTEM.GET(MCU.RTC_SCR, x);
    SYSTEM.PUT(MCU.RTC_SCR, x + {CWUTF});
END WakeupS;

END STM32C5RTC.
