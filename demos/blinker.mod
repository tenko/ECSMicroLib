(** Simple led blinker demo using the SysTick millisecond timer *)
MODULE Test;
IMPORT BoardConfig, SYSTEM;

IN Micro IMPORT ARMv7M;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;

CONST Pins = BoardConfig.Pins;

VAR pin : Pins.Pin;

BEGIN
	TRACE("START");
    BoardConfig.Init;
    
    pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);

    SysTick.Init(BoardConfig.HCLK, 1000);
    REPEAT
        pin.On;
        TRACE("ON0");
        WHILE ~SysTick.OnTimer() DO ARMv7M.WFI END;
        pin.Off;
        TRACE("OFF0");
        WHILE ~SysTick.OnTimer() DO ARMv7M.WFI END;
    UNTIL FALSE
END Test.