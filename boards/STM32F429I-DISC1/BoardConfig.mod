(** Config for the STM32 board STM32F429I-DISC1

		RM0090, Reference manual,
			STM32F42xxx, STM32F43xxx
*)
MODULE BoardConfig;

IN Micro IMPORT STM32F4Pins;
IN Micro IMPORT STM32F4System;

CONST
    (* Board user led 1 & 2 + button *)
    USER_LED1_PORT* = 6; (* Port G *)
    USER_LED1_PIN* = 13; (* LD3 Green Led *)
    USER_LED2_PORT* = 6; (* Port G *)
    USER_LED2_PIN* = 14; (* LD4 Red Led *)
    USER_BUTTON1_PORT* = 0; (* Port A *)
    USER_BUTTON1_PIN* = 0; (* B1 Blue PushButton *)

    Pins* = STM32F4Pins;
    
    (* Clocks *)
    fHSE = 8000000; (* Hz external crystal *)

VAR
	HCLK*,
	PCLK1*, TIMCLK1*,
	PCLK2*, TIMCLK2*,
	QCLK*, (* QCLK <= 48 MHz, best is 48 MHz *)
	RCLK*: INTEGER; (* Hz *)

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
