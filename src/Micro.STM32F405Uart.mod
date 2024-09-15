(**
Alexander Shiryaev, 2016.09, 2017.04, 2019.10, 2020.12
Modified by Tenko for use with ECS

STM32F405 U[S]ART support
*)
MODULE STM32F405Uart (n) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT STM32F4Uart;

CONST
    isr = SEL(n = 1, "isr_usart1", SEL(n = 2, "isr_usart1", SEL(n = 3, "isr_usart3", SEL(n = 4, "isr_uart4", SEL(n = 5, "isr_uart5", "isr_usart6")))));

PROCEDURE InterruptHandler [isr] ();
BEGIN
    IF STM32F4Uart.bus = NIL THEN RETURN END;
    STM32F4Uart.bus.Interrupt
END InterruptHandler;

END STM32F405Uart.