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

(** Set RTC Wakeup timer delay in seconds upto 36 [h] / 129600 [s]
Setting delay to <= 0 disable the wakeup timer.
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

(** Get current date and time *)
PROCEDURE (VAR rtc : RTC) Now*(VAR year, month, day, hour, min, sec : INTEGER);
CONST
	(* RTC_TR bits *)
	SU = 0; ST = 4; MNU = 8; MNT = 12;
	HU = 16; HT = 20; PM = 22;
	(* RTC_DR bits *)
	DU = 0; DT = 4; MU = 8; MT = 12;
	WDU = 13; YU = 16; YT = 20;
VAR
	x: SET32;
BEGIN
	(* Fetch time in BCD format *)
	SYSTEM.GET(MCU.RTC_TR, x);
	sec := INTEGER(x * {SU .. SU + 3});
	sec := sec + 10 * SYSTEM.LSH(INTEGER(x * {ST .. ST + 2}), -ST);
	min := SYSTEM.LSH(INTEGER(x * {MNU .. MNU + 3}), -MNU);
	min := min + 10 * SYSTEM.LSH(INTEGER(x * {MNT .. MNT + 2}), -MNT);
	hour := SYSTEM.LSH(INTEGER(x * {HU .. HU + 3}), -HU);
	hour := hour + 10 * SYSTEM.LSH(INTEGER(x * {HT .. HT + 1}), -HT);
	(* IF PM IN x THEN hour := hour + 12 END; *)
	
	(* Fetch date in BCD format *)
	SYSTEM.GET(MCU.RTC_DR, x);
	day := INTEGER(x * {DU .. DU + 3});
	day := day + 10 * SYSTEM.LSH(INTEGER(x * {DT .. DT + 1}), -DT);
	month := SYSTEM.LSH(INTEGER(x * {MU .. MU + 3}), -MU);
	month := month + 10 * SYSTEM.LSH(INTEGER(x * {MT}), -MT);
	year := SYSTEM.LSH(INTEGER(x * {YU .. YU + 3}), -YU);
	year := year + 10 * SYSTEM.LSH(INTEGER(x * {YT .. YT + 3}), -YT);
END Now;


(** Set current date and time *)
PROCEDURE (VAR rtc : RTC) SetDateTime*(year, month, day, hour, min, sec : INTEGER);
CONST
	(* RTC_ICSR bits* *)
	RSF = 5; INITF = 6; INIT = 7;
	(* RTC_TR bits *)
	SU = 0; ST = 4; MNU = 8; MNT = 12;
	HU = 16; HT = 20;
	(* RTC_DR bits *)
	DU = 0; DT = 4; MU = 8; MT = 12;
	WDU = 13; YU = 16; YT = 20; PM = 22;
VAR
	u : UNSIGNED32;
	x : SET32;
BEGIN
	(* Unlock RTC write protection *)
    SYSTEM.GET(MCU.RTC_WPR, x);
    SYSTEM.PUT(MCU.RTC_WPR, x + SET8(0CAH));
    SYSTEM.GET(MCU.RTC_WPR, x);
    SYSTEM.PUT(MCU.RTC_WPR, x + SET8(053H));
    
    (* Enter initialization mode *)
    SYSTEM.GET(MCU.RTC_ICSR, x);
    SYSTEM.PUT(MCU.RTC_ICSR, x + {INIT});
    REPEAT UNTIL SYSTEM.BIT(MCU.RTC_ICSR, INITF);
	
	(* Set time bits *)
	SYSTEM.GET(MCU.RTC_TR, u);
	(* x := x * SET32(0FFC00080H); *)
	u := UNSIGNED32(SET32(u) - SET32({SU .. SU + 3} + {ST .. ST + 2} + {MNU .. MNU + 3} + {MNT .. MNT + 2} + {HU .. HU + 3} + {HT .. HT + 1}));
	u := u + UNSIGNED32(sec MOD 10);
	u := u + SYSTEM.LSH(UNSIGNED32(sec DIV 10), ST);
	u := u + SYSTEM.LSH(UNSIGNED32(min MOD 10), MNU);
	u := u + SYSTEM.LSH(UNSIGNED32(min DIV 10), MNT);
	u := u + SYSTEM.LSH(UNSIGNED32(hour MOD 10), HU);
	u := u + SYSTEM.LSH(UNSIGNED32(hour DIV 10), HT);
	SYSTEM.PUT(MCU.RTC_TR, u);
	
	(* Set date bits *)
	SYSTEM.GET(MCU.RTC_DR, u);
	u := UNSIGNED32(SET32(u) - SET32({DU .. DU + 3} + {DT .. DT + 1} + {MU .. MU + 3} + {MT} + {YU .. YU + 3} + {YT .. YT + 3} + {PM}));
	u := u + UNSIGNED32(day MOD 10);
	u := u + SYSTEM.LSH(UNSIGNED32(day DIV 10), DT);
	u := u + SYSTEM.LSH(UNSIGNED32(month MOD 10), MU);
	u := u + SYSTEM.LSH(UNSIGNED32(month DIV 10), MT);
	u := u + SYSTEM.LSH(UNSIGNED32(year MOD 10), YU);
	u := u + SYSTEM.LSH(UNSIGNED32(year DIV 10), YT);
	SYSTEM.PUT(MCU.RTC_DR, u);
	
	(* Exit initialization mode *)
    SYSTEM.GET(MCU.RTC_ICSR, x);
    SYSTEM.PUT(MCU.RTC_ICSR, x - {INIT});
    
    (* Trigger syncronization and wait for bit *)
    SYSTEM.GET(MCU.RTC_ICSR, x);
    SYSTEM.PUT(MCU.RTC_ICSR, x - {RSF});
    REPEAT UNTIL SYSTEM.BIT(MCU.RTC_ICSR, RSF);
    
	(* Turn on RTC write protection *)
    SYSTEM.GET(MCU.RTC_WPR, x);
    SYSTEM.PUT(MCU.RTC_WPR, x + SET8(0FFH));
END SetDateTime;

END STM32C5RTC.
