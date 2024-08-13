MODULE Blinker;
IMPORT SYSTEM;

IN Micro IMPORT Sys := STM32F4System;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT Pin := STM32F4Pins;
IN Micro IMPORT ARMv7MTraps;

VAR
    x : SYSTEM.ADDRESS;
BEGIN
    ARMv7MTraps.Init;
    Pin.Configure(Pin.D, 15, Pin.output, Pin.pushPull, Pin.medium, Pin.noPull, Pin.AF0);
    SysTick.Init(4000000, 1000);
    REPEAT
        TRACE("ON");
        SYSTEM.PUT(MCU.GPIODBSRR, {15}); (* PD15 *)
        WHILE ~SysTick.OnTimer() DO END;
        TRACE("OFF");
        SYSTEM.PUT(MCU.GPIODBSRR, {15 + 16}); (* ~PD15 *)
        WHILE ~SysTick.OnTimer() DO END;
    UNTIL FALSE
END Blinker.