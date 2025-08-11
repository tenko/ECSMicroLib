(** Config for the STM32 board NUCLEO-L432KC
    RM0394, Reference manual STM32L41xxx/42xxx/43xxx/44xxx/45xxx/46xxx
*)
MODULE BoardConfig;

IN Micro IMPORT STM32L4Pins;
IN Micro IMPORT STM32L4System;

CONST
    (* Board user led 1 *)
    USER_LED1_PORT* = 1; (* Port B *)
    USER_LED1_PIN* = 3;

    Pins* = STM32L4Pins;
    
    (* Default clock *)
    fMSI = 4000000;  (* Hz multi-speed internal oscillator *)
	
VAR
	HCLK*,
	PCLK1*,
	PCLK2*,
	PCLK*,
	QCLK*,
	RCLK* : INTEGER; (* Hz *)

PROCEDURE Init*;
BEGIN
    STM32L4System.Init;
	STM32L4System.SetPLLSysClock(STM32L4System.HSI);
	HCLK := STM32L4System.HCLK;
	PCLK1 := STM32L4System.PCLK1;
	PCLK2 := STM32L4System.PCLK2;
	PCLK := STM32L4System.PCLK;
	QCLK := STM32L4System.QCLK;
	RCLK := STM32L4System.RCLK;
END Init;

BEGIN
    HCLK := fMSI;
END BoardConfig.
