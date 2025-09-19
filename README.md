# ECSMicroLib
ECS Oberon-2 Compiler framework for ARM32 MCUs

Most of the code is ported from Alexander V. Shiryaev's O7 Micro framework for Oberon-07
based on the Black Box compiler.

Original project [Link](https://github.com/aixp/O7)

The framework has support for I2C, SPI, Uart and OneWire protocols to
work with external devices.

## Boards

Currently supported boards:

* NUCLEO-L432KC
* STM32F407G-DISC1
* STM32F429I-DISC1

These are the boards I have on hand and are able to test.
The original framework support more MCU, but these are
removed until it is posible to test these.

Also the ECS compiler support more targets like AVR, AVR32, Xtensa.

## Example

Hello world for MCU with LED blinking.

Test.mod:

```modula-2
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
```

Building & Running

```
make BOARD=STM32F429I-DISC1 DEMO=blinker
make BOARD=STM32F429I-DISC1 DEMO=blinker flash
make BOARD=STM32F429I-DISC1 DEMO=blinker server # start stlink server
make BOARD=STM32F429I-DISC1 DEMO=blinker gdb # run in other shell
```

The Makefile uses the stlink utility to flash the firmware and uses the
GDB to start and monitor the example.

## TODO

* Documentation
* Add I2C & SPI drivers to STM32L4 MCU.
* The I2C & OneWire drivers are blocking and should be changed async.
* Add support for coroutines for cooperative multitasking.

## Note

Currently a patched version of the **ECS** compiler is needed [Link](https://github.com/tenko/ECS)  
With the next release of the **ECS** compiler these patches should be included.

The **ECSStdLib** is needed to build the library [Link](https://github.com/tenko/ECSStdLib)

The **ECSGfxLib** is needed to build some examples [Link](https://github.com/tenko/ECSGfxLib)