(** Config for the STM32 custom board for STM32C5
    RM0522, Reference manual STM32C5xxxx
*)
MODULE BoardConfig;

IN Micro IMPORT ARMv8MSTM32SysTick0;
IN Micro IMPORT STM32C5Pins;

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
    
    (* Default clock *)
    fHSIDIV3 = 48000000;  (* Hz internal oscillator *)
	
VAR
    SYSCLK*,
    HCLK*,
	PCLK1*,
	PCLK2*: INTEGER; (* Hz *)

PROCEDURE Init*;
BEGIN
END Init;

BEGIN
    (* System startup defaults *)
    SYSCLK := fHSIDIV3;
    HCLK := fHSIDIV3;
    PCLK1 := fHSIDIV3;
	PCLK2 := fHSIDIV3;
	ARMv8MSTM32SysTick0.Init(SYSCLK, 1000);
END BoardConfig.
