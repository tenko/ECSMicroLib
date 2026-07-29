# Board specific configuration
ARCH 		:= ARM
RUNTIME 	:= stm32c5run.asm
BOOTSTART 	:= 0x08000000
RAMSTART 	:= 0x20000000
RAMSIZE 	:= 0x00010000
FLASHSTART 	:= 0x08000000

ifeq ($(DEMO),)
$(error Error: DEMO is not set. Expected blinker or uartecho.)
endif
