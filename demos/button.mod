MODULE Test;
IMPORT BoardConfig;

IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;

CONST
    Pins = BoardConfig.Pins;
    ExtInt = BoardConfig.ExtIntButton1;

VAR led, btn : Pins.Pin;

BEGIN
	TRACE("START");
    BoardConfig.Init;
    
    led.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);

    btn.Init(BoardConfig.USER_BUTTON1_PORT, BoardConfig.USER_BUTTON1_PIN, Pins.input,
             FALSE, 0, Pins.noPull, Pins.AF0);

    ExtInt.Init(btn, TRUE, FALSE);
    ExtInt.Enable;
    
    SysTick.Init(BoardConfig.HCLK, 1000);
    REPEAT
        IF ExtInt.OnTrigger() THEN
            led.Toggle;
        END;
        SysTick.Delay(5);
    UNTIL FALSE
END Test.