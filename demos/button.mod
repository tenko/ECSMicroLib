(** Simple demo of using an external interrupt to detect button edge event *)
MODULE Test;
IMPORT BoardConfig;
IMPORT Machine IN Micro;

CONST
    Debug = TRUE; (* Set Debug = FALSE to allow to run demo without debugger *)
    Pins = BoardConfig.Pins;
    ExtInt = BoardConfig.ExtIntButton1;

VAR 
    led, btn : Pins.Pin;
    ext : ExtInt.PinExtInt;

BEGIN
	IF Debug THEN TRACE("START") END;
    BoardConfig.Init;
    
    led.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);

    btn.Init(BoardConfig.USER_BUTTON1_PORT, BoardConfig.USER_BUTTON1_PIN, Pins.input,
             FALSE, 0, Pins.noPull, Pins.AF0);

    ext.Init(btn, TRUE, FALSE);
    ext.Enable;
    
    REPEAT
        Machine.Idle;
        IF ext.OnTrigger() THEN
            led.Toggle;
        END;
    UNTIL FALSE
END Test.