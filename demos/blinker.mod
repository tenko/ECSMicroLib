(** Simple led blinker demo using the SysTick millisecond timer *)
MODULE Test;
IMPORT BoardConfig;
IMPORT Machine IN Micro;

CONST Pins = BoardConfig.Pins;

VAR pin : Pins.Pin;

BEGIN
    TRACE("START");
    BoardConfig.Init;
    
    pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
    
    REPEAT
        pin.On;
        TRACE("ON0");
        Machine.DelayMS(100);
        pin.Off;
        TRACE("OFF0");
        Machine.DelayMS(100);
    UNTIL FALSE
END Test.