(** Simple led blinker demo using the SysTick millisecond timer *)
MODULE Test;
IMPORT BoardConfig;
IMPORT Machine IN Micro;

CONST
    Debug = TRUE; (* Set Debug = FALSE to allow to run demo without debugger *)
    Pins = BoardConfig.Pins;

VAR pin : Pins.Pin;

BEGIN
    IF Debug THEN TRACE("START") END;
    BoardConfig.Init;
    
    pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
    
    REPEAT
        pin.On;
        IF Debug THEN TRACE("ON0") END;
        Machine.DelayMS(100);
        pin.Off;
        IF Debug THEN TRACE("OFF0") END;
        Machine.DelayMS(100);
    UNTIL FALSE
END Test.