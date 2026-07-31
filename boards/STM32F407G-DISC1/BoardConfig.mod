(** Config for the STM32 board STM32F407G-DISC1

		RM0090, Reference manual,
			STM32F405xx/07xx, STM32F415xx/17xx,
			STM32F42xxx, STM32F43xxx
*)
MODULE BoardConfig;

IN Micro IMPORT ArchArmSysTick;
IN Micro IMPORT STM32F4;
IN Micro IMPORT STM32F4Pins;
IN Micro IMPORT STM32F4ExtInt0 := STM32F4PinsExtInt(0);
IN Micro IMPORT STM32F4Uart := STM32F4Uart(2);
IN Micro IMPORT STM32F4OneWire;
IN Micro IMPORT STM32F4RCC;

CONST
    Board* = "STM32F407G-DISC1";
    MCU* = "STM32F407VG";
    (* Board user led 1 *)
    USER_LED1_PORT* = 3; (* Port D *)
    USER_LED1_PIN* = 15;
    USER_BUTTON1_PORT* = 0; (* Port A *)
    USER_BUTTON1_PIN* = 0; (* B1 Blue PushButton *)
    
    SysTick* = ArchArmSysTick;
    Pins* = STM32F4Pins;
    ExtIntButton1* = STM32F4ExtInt0;
    Uart* = STM32F4Uart;
    OWire* = STM32F4OneWire;
    
    (* Clocks *)
    fHSE = 8000000; (* Hz external crystal *)

VAR
	HCLK*,
	PCLK1*, TIMCLK1*,
	PCLK2*, TIMCLK2*,
	QCLK*, (* QCLK <= 48 MHz, best is 48 MHz *)
	RCLK*: INTEGER; (* Hz *)

(* No pullup needed here *)
PROCEDURE InitOWire*(VAR bus : OWire.Bus);
VAR par : OWire.InitPar;
BEGIN
    par.n := OWire.USART2;
    par.TXRXPinPort := Pins.A;
    par.TXRXPinN := 2;
    par.UCLK := PCLK1;
    par.timeout := 1000;
    OWire.Init(bus, par);
    bus.Enable;
END InitOWire;

(* USB to UART bridge needed to connect to PC *)
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

(* Setup HSE clock *)
PROCEDURE Init*;
BEGIN
    STM32F4RCC.SetPLLSysClock(STM32F4RCC.HSE, fHSE);
    HCLK := STM32F4RCC.HCLK;
	PCLK1 := STM32F4RCC.PCLK1;
	TIMCLK1 := STM32F4RCC.TIMCLK1;
	PCLK2 := STM32F4RCC.PCLK2;
	TIMCLK2 := STM32F4RCC.TIMCLK2;
	QCLK := STM32F4RCC.QCLK;
	RCLK := STM32F4RCC.RCLK;
END Init;

(* Setup with default clock at reset *)
BEGIN
    STM32F4.Init;
    HCLK := STM32F4RCC.fHSI;
    PCLK1 := STM32F4RCC.fHSI;
	TIMCLK1 := STM32F4RCC.fHSI;
	PCLK2 := STM32F4RCC.fHSI;
	TIMCLK2 := STM32F4RCC.fHSI;
	QCLK := STM32F4RCC.fHSI;
	RCLK := STM32F4RCC.fHSI;
END BoardConfig.
