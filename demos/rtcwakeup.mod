(**
    Simple led blinker demo using the RTC wakeup for accurate longer delays.
    
    Note that SleepLight and SleepDeep will power down the MCU and the debugger
    will be disconnected.
*)
MODULE Test;

IMPORT SYSTEM;
IMPORT BoardConfig;
IN Std IMPORT Const, OSStream;
IN Micro IMPORT Machine;

CONST
    Debug = TRUE; (* Set Debug = FALSE to allow to run demo without debugger *)
    Pins = BoardConfig.Pins;
    RTC = BoardConfig.RTC;
    SysTick = BoardConfig.SysTick;
    Sleep = 0; (* 0, 1 or 2 *)

VAR
    pin : Pins.Pin;
    rtc : RTC.RTC;
    year, month, day: INTEGER;
    hour, min, sec: INTEGER;

(* Busy loop delay as I could not get SysTick to work afer wakeup *)
PROCEDURE DelayMS(delay : LENGTH);
VAR
    i, j : LENGTH;
BEGIN
    FOR i := 0 TO delay - 1 DO
        FOR j := 0 TO 9600 DO
            SYSTEM.ASM("nop");
        END;
    END;
END DelayMS;

BEGIN
    IF Machine.resetCause = Machine.RESET_DEEPSLEEP THEN
        IF Debug THEN TRACE("WAKEUP") END;
        BoardConfig.InitDefault;
        rtc.Now(year, month, day, hour, min, sec);
    ELSE
        IF Debug THEN TRACE("START") END;
        BoardConfig.InitRTC;
        RTC.Init(rtc);
        rtc.WakeupS(3);
        rtc.SetDateTime(2026,10,12,16,43,20);
    END;
	
    REPEAT
        (* Pin config must be run after return from Idle *)
        pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
        pin.On;

		rtc.Now(year, month, day, hour, min, sec);
		IF Debug THEN
			OSStream.StdOut.FormatInteger(INTEGER(hour), 2, Const.Zero);
	    	OSStream.StdOut.WriteString(":");
	    	OSStream.StdOut.FormatInteger(INTEGER(min), 2, Const.Zero);
	    	OSStream.StdOut.WriteString(":");
	    	OSStream.StdOut.FormatInteger(INTEGER(sec), 2, Const.Zero);
	    	OSStream.StdOut.WriteNL;
    	END;
    	
        IF Debug THEN TRACE("ON0") END;
        DelayMS(500);
        pin.Off;
        IF Debug THEN TRACE("OFF0") END;
        
        IF Sleep = 0 THEN
            SysTick.Disable;
            Machine.Idle;
            SysTick.Enable;
        ELSIF Sleep = 1 THEN
            Machine.SleepLight;
            BoardConfig.InitDefault;
        ELSE
            Machine.SleepDeep; (* TODO : currently does not work *)
            (* Wakeup triggers reset *)
        END;
    UNTIL FALSE
END Test.