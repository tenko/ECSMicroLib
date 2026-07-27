(** Config for the STM32 custom board for STM32C5
    RM0522, Reference manual STM32C5xxxx
*)
MODULE BoardConfig;

IN Micro IMPORT STM32C5;
IN Micro IMPORT STM32C5System;
IN Micro IMPORT ARMv8MSTM32SysTick0;
IN Micro IMPORT STM32C5Pins;
IN Micro IMPORT STM32C5RTC;
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
    RTC* = STM32C5RTC;
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

PROCEDURE InitSysTick*;
BEGIN ARMv8MSTM32SysTick0.Init(SYSCLK, 1000); (* ms timer *)
END InitSysTick;

PROCEDURE Init*;
BEGIN
    (* Switch to HSE 24MHz crystal *)
    STM32C5System.SetClock(STM32C5System.HSE, 24'000'000);
    HCLK := STM32C5System.HCLK;
    SYSCLK := HCLK;
    PCLK1 := HCLK;
	PCLK2 := HCLK;
    InitSysTick;
END Init;

PROCEDURE InitRTC*;
BEGIN
    STM32C5System.SetRTCClock(STM32C5System.LSE, STM32C5System.DriveHighest);
END InitRTC;

PROCEDURE InitDefault*;
BEGIN
    (* System startup default clock is HSIDIV3 *)
    STM32C5.Init;
    SYSCLK := fHSIDIV3;
    HCLK := fHSIDIV3;
    PCLK1 := fHSIDIV3;
	PCLK2 := fHSIDIV3;
	InitSysTick;
END InitDefault;

BEGIN
    InitDefault;
END BoardConfig.
