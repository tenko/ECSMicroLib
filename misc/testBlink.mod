MODULE Test;
IMPORT SYSTEM;

IN Micro IMPORT Trap := ARMv7MTraps;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT Pins := STM32F4Pins;

CONST
    HCLK = 16000000; (* HSI default clock *)

VAR
    pin : Pins.Pin;

PROCEDURE ClockCfg;
CONST HSION = 0; HSIRDY = 1;
VAR x : SET32;
BEGIN
    (* Switch to the 16MHz HSI oscillator. *)
	SYSTEM.GET(MCU.RCCCR, x);
	SYSTEM.PUT(MCU.RCCCR, x + {HSION});
	REPEAT UNTIL SYSTEM.BIT(MCU.RCCCR, HSIRDY);
    (* HSI as SYSCLK *)
	SYSTEM.PUT(MCU.RCCCFGR, SET32({}));
	LOOP
        SYSTEM.GET(MCU.RCCCFGR, x);
        IF x * {3,2} = {} THEN EXIT END
    END;
END ClockCfg;

BEGIN
    Trap.Init;
    Trap.debug := TRUE;
    ClockCfg;

    (* Setting up output A15 *)
    pin.Init(Pins.D, 15, Pins.output, Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
    
    SysTick.Init(HCLK, 1000);

    REPEAT
        pin.On;
        TRACE("ON0");
        WHILE ~SysTick.OnTimer() DO END;
        pin.Off;
        TRACE("OFF0");
        WHILE ~SysTick.OnTimer() DO END;
    UNTIL FALSE
END Test.