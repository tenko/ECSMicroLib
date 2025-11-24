(** Config for the STM32 board STM32F407G-DISC1

		RM0090, Reference manual,
			STM32F405xx/07xx, STM32F415xx/17xx,
			STM32F42xxx, STM32F43xxx
*)
MODULE BoardConfig;

IN Micro IMPORT STM32F4Pins;
IN Micro IMPORT STM32F4Uart := STM32F4Uart(2);
IN Micro IMPORT STM32F4System;

CONST
    Board = "STM32F407G-DISC1";
    MCU = "STM32F407VG";
    (* Board user led 1 *)
    USER_LED1_PORT* = 3; (* Port D *)
    USER_LED1_PIN* = 15;

    Pins* = STM32F4Pins;
    Uart* = STM32F4Uart;
    
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
    par.RXPinPort := Pins.A; par.RXPinN := 3; par.RXPinAF := Pins.AF7;
    par.TXPinPort := Pins.A; par.TXPinN := 2;  par.TXPinAF := Pins.AF7;
    par.UCLK := PCLK1;
    par.baud := baud;
    par.parity := parity;
    par.stopBits := stopBits;
    par.disableReceiver := FALSE;
    Uart.Init(bus, par);
END InitUart;

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
