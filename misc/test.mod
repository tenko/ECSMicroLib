MODULE Blinker;
IMPORT SYSTEM;

IN Micro IMPORT Sys := STM32F4System;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT Pins := STM32F4Pins;

VAR
    x : SYSTEM.ADDRESS;
    pin : Pins.Pin;
BEGIN
    pin.Init(Pins.D, 15, Pins.output, Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
    SysTick.Init(4000000, 1000);
    REPEAT
        TRACE("ON");
        pin.On;
        WHILE ~SysTick.OnTimer() DO END;
        TRACE("OFF");
        pin.Off;
        WHILE ~SysTick.OnTimer() DO END;
    UNTIL FALSE
END Blinker.