(** Simple led blinker demo using the RTC wakeup for accurate longer delays *)
MODULE Test;
IMPORT SYSTEM;
IMPORT BoardConfig;
IMPORT Machine IN Micro;

CONST
    Pins = BoardConfig.Pins;
    RTC = BoardConfig.RTC;
    SysTick = BoardConfig.SysTick;

VAR
    pin : Pins.Pin;
    rtc : RTC.RTC;

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
        (* TRACE("WAKEUP"); *)
    ELSE
         (* TRACE("START"); *)
        BoardConfig.InitRTC;
        RTC.Init(rtc);
        rtc.WakeupS(3);
    END;

    REPEAT
        (* Pin config must be run after return from Idle *)
        pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
        pin.On;
        (* TRACE("ON0"); *)
        DelayMS(500);
        pin.Off;
        (* TRACE("OFF0"); *)
        Machine.SleepLight;
        (*
        SysTick.Disable;
        Machine.Idle;
        SysTick.Enable;
        *)
    UNTIL FALSE
END Test.