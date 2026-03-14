(** Config for the STM32 board NUCLEO-L432KC
    RM0394, Reference manual STM32L41xxx/42xxx/43xxx/44xxx/45xxx/46xxx
*)
MODULE BoardConfig;

IN Micro IMPORT ARMv7MSTM32SysTick0;
IN Micro IMPORT STM32L4Pins;
IN Micro IMPORT STM32L4Uart := STM32L4Uart(2);
IN Micro IMPORT STM32L4OneWire;
IN Micro IMPORT STM32L4System;

CONST
    Board* = "NUCLEO-L432KC";
    MCU* = "STM32L432KC";
    (* Board user led 1 *)
    USER_LED1_PORT* = 1; (* Port B *)
    USER_LED1_PIN* = 3;
    
    SysTick* = ARMv7MSTM32SysTick0;
    Pins* = STM32L4Pins;
    Uart* = STM32L4Uart;
    OWire* = STM32L4OneWire;
    
    (* Default clock *)
    fMSI = 4000000;  (* Hz multi-speed internal oscillator *)
	
VAR
	HCLK*,
	PCLK1*,
	PCLK2*,
	PCLK*,
	QCLK*,
	RCLK* : INTEGER; (* Hz *)

(* OWire on USART1. Note it needs external pull-up resistor, typical 10K *)
PROCEDURE InitOWire*(VAR bus : OWire.Bus);
VAR par : OWire.InitPar;
BEGIN
    par.n := OWire.USART1;
    par.TXRXPinPort := Pins.A;
    par.TXRXPinN := 9;
    par.UCLK := PCLK2;
    par.timeout := 1000;
    OWire.Init(bus, par);
    bus.Enable;
END InitOWire;

(* USART2 is connected to ST-Link interface *)
PROCEDURE InitUart*(VAR bus : Uart.Bus; baud, parity, stopBits : INTEGER);
VAR par : Uart.InitPar;
BEGIN
    par.RXPinPort := Pins.A; par.RXPinN := 15; par.RXPinAF := Pins.AF3;
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
    STM32L4System.Init;
	STM32L4System.SetPLLSysClock(STM32L4System.HSI);
	HCLK := STM32L4System.HCLK;
	PCLK1 := STM32L4System.PCLK1;
	PCLK2 := STM32L4System.PCLK2;
	PCLK := STM32L4System.PCLK;
	QCLK := STM32L4System.QCLK;
	RCLK := STM32L4System.RCLK;
	ARMv7MSTM32SysTick0.Init(HCLK, 1000);
END Init;

BEGIN
    (* System startup defaults *)
    HCLK := fMSI;
    PCLK1 := fMSI;
	PCLK2 := fMSI;
	PCLK := fMSI;
	QCLK := fMSI;
	RCLK := fMSI;
	ARMv7MSTM32SysTick0.Init(HCLK, 1000);
END BoardConfig.
