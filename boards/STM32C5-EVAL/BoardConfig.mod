(** Config for the STM32 custom board for STM32C5
    RM0522, Reference manual STM32C5xxxx
*)
MODULE BoardConfig;

IN Micro IMPORT STM32C5System;
IN Micro IMPORT ARMv8MSTM32SysTick0;
IN Micro IMPORT STM32C5Pins;
IN Micro IMPORT STM32C5ExtInt8 := STM32C5PinsExtInt(8);
IN Micro IMPORT STM32C5Uart := STM32C5Uart(1);

CONST
    Board* = "NUCLEO-L432KC";
    MCU* = "STM32C551CE";

    (* Board user led 1 *)
    USER_LED1_PORT* = 1; (* Port B *)
    USER_LED1_PIN* = 9;

    (* Board user button *)
    USER_BUTTON1_PORT* = 1; (* Port B *)
    USER_BUTTON1_PIN* = 8;
    
    SysTick* = ARMv8MSTM32SysTick0;
    Pins* = STM32C5Pins;
    ExtIntButton1* = STM32C5ExtInt8;
    Uart* = STM32C5Uart;

    (* Default clock *)
    fHSIDIV3 = 48000000;  (* Hz internal oscillator *)
	
VAR
    SYSCLK*,
    HCLK*,
	PCLK1*,
	PCLK2*: INTEGER; (* Hz *)

PROCEDURE InitUart*(VAR bus : Uart.Bus; baud, parity, stopBits : INTEGER);
VAR par : Uart.InitPar;
BEGIN
    par.RXPinPort := Pins.A; par.RXPinN := 7; par.RXPinAF := Pins.AF7;
    par.TXPinPort := Pins.A; par.TXPinN := 6;  par.TXPinAF := Pins.AF7;
    par.UCLK := PCLK1;
    par.baud := baud;
    par.parity := parity;
    par.stopBits := stopBits;
    par.disableReceiver := FALSE;
    Uart.Init(bus, par);
END InitUart;

PROCEDURE Init*;
BEGIN
    (* Switch to HSE 24MHz crystal *)
    STM32C5System.SetClock(STM32C5System.HSE, 24'000'000);
    HCLK := STM32C5System.HCLK;
    SYSCLK := HCLK;
    PCLK1 := HCLK;
	PCLK2 := HCLK;
    ARMv8MSTM32SysTick0.Init(SYSCLK, 1000);
END Init;

BEGIN
    (* System startup defaults *)
    SYSCLK := fHSIDIV3;
    HCLK := fHSIDIV3;
    PCLK1 := fHSIDIV3;
	PCLK2 := fHSIDIV3;
	ARMv8MSTM32SysTick0.Init(SYSCLK, 1000);
END BoardConfig.
