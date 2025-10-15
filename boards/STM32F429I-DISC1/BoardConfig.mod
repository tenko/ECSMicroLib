(** Config for the STM32 board STM32F429I-DISC1

		RM0090, Reference manual,
			STM32F42xxx, STM32F43xxx
*)
MODULE BoardConfig;

IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT STM32F4Pins;
IN Micro IMPORT STM32F4Uart := STM32F4Uart(1);
IN Micro IMPORT STM32F4I2C;
IN Micro IMPORT STM32F4SPI5 := STM32F4SPI(5);
IN Micro IMPORT STM32F4System;

CONST
    (* Board user led 1 & 2 + button *)
    USER_LED1_PORT* = 6; (* Port G *)
    USER_LED1_PIN* = 13; (* LD3 Green Led *)
    USER_LED2_PORT* = 6; (* Port G *)
    USER_LED2_PIN* = 14; (* LD4 Red Led *)
    USER_BUTTON1_PORT* = 0; (* Port A *)
    USER_BUTTON1_PIN* = 0; (* B1 Blue PushButton *)
    TOUCH_INT_PORT* = 0; (* Port A *)
    TOUCH_INT_PIN* = 15; (* INT STMPE811 *)
    
    Pins* = STM32F4Pins;
    Uart* = STM32F4Uart;
    I2C* = STM32F4I2C;
    SPI5* = STM32F4SPI5;
    
    (* Clocks *)
    fHSE = 8000000; (* Hz external crystal *)

VAR
	HCLK*,
	PCLK1*, TIMCLK1*,
	PCLK2*, TIMCLK2*,
	QCLK*, (* QCLK <= 48 MHz, best is 48 MHz *)
	RCLK*: INTEGER; (* Hz *)

PROCEDURE InitUart*(VAR bus : Uart.Bus; baud, parity, stopBits : INTEGER);
VAR par : Uart.InitPar;
BEGIN
    par.RXPinPort := Pins.A; par.RXPinN := 10; par.RXPinAF := Pins.AF7;
    par.TXPinPort := Pins.A; par.TXPinN := 9;  par.TXPinAF := Pins.AF7;
    IF HCLK = STM32F4System.fHSI THEN 
        par.UCLK := HCLK;
    ELSE
        par.UCLK := PCLK2;
    END;
    par.baud := baud;
    par.parity := parity;
    par.stopBits := stopBits;
    par.disableReceiver := FALSE;
    Uart.Init(bus, par);
END InitUart;

PROCEDURE InitSTMPE811I2C* (VAR bus : I2C.Bus);
VAR
    par: I2C.InitPar;
BEGIN
    par.n := 3;
    par.SCLPinPort := Pins.A;
    par.SCLPinN := 8;
    par.SCLPinAF := Pins.AF4;
    par.SDAPinPort := Pins.C;
    par.SDAPinN := 9;
    par.SDAPinAF := Pins.AF4;
    par.PCLK1 := PCLK1;
    par.freq := 100000;
    par.getTicks := SysTick.GetTicks;
    par.timeout := 5000;
    I2C.Init(bus, par);
END InitSTMPE811I2C;

PROCEDURE InitI3G4250DSPI* (VAR bus : SPI5.Bus);
VAR
    par: SPI5.InitPar;
BEGIN
    par.SCKPinPort := Pins.F;
    par.SCKPinN := 7;
    par.SCKPinAF := Pins.AF5;
    par.MISOPinPort := Pins.F;
    par.MISOPinN := 8;
    par.MISOPinAF := Pins.AF5;
    par.MOSIPinPort := Pins.F;
    par.MOSIPinN := 9;
    par.MOSIPinAF := Pins.AF5;
    par.pullType := SPI5.noPull;
    par.br := 7;
    par.cPha := FALSE;
    par.cPol := FALSE;
    par.configNSS := FALSE;
    SPI5.Init(bus, par);
END InitI3G4250DSPI;

PROCEDURE InitILI9341SPI* (VAR bus : SPI5.Bus; VAR rst, cs, dc : Pins.Pin);
VAR
    par: SPI5.InitPar;
BEGIN
    par.SCKPinPort := Pins.F;
    par.SCKPinN := 7;
    par.SCKPinAF := Pins.AF5;
    par.MISOPinPort := -1;
    par.MOSIPinPort := Pins.F;
    par.MOSIPinN := 9;
    par.MOSIPinAF := Pins.AF5;
    par.pullType := SPI5.noPull;
    par.br := 0;
    par.cPha := FALSE;
    par.cPol := FALSE;
    par.configNSS := FALSE;
    SPI5.Init(bus, par);
    
    rst.Init(Pins.A, 7, Pins.output, Pins.pushPull, Pins.low, Pins.noPull, Pins.AF0);
    rst.On;
    cs.Init(Pins.C, 2, Pins.output, Pins.pushPull, Pins.low, Pins.noPull, Pins.AF0);
    cs.On;
    dc.Init(Pins.D, 13, Pins.output, Pins.pushPull, Pins.low, Pins.noPull, Pins.AF0);
    dc.On;
END InitILI9341SPI;

PROCEDURE Init*;
BEGIN
    STM32F4System.Init;
    STM32F4System.SetPLLSysClock(STM32F4System.HSE, fHSE);
    HCLK := STM32F4System.HCLK;
	PCLK1 := STM32F4System.PCLK1;
	TIMCLK1 := STM32F4System.TIMCLK1;
	PCLK2 := STM32F4System.PCLK2;
	TIMCLK2 := STM32F4System.TIMCLK2;
	QCLK := STM32F4System.QCLK;
	RCLK := STM32F4System.RCLK;
END Init;

BEGIN
    HCLK := STM32F4System.fHSI;
END BoardConfig.
