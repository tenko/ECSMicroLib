# Board specific configuration
RUNTIME 	:= stm32f429run.asm
BOOTSTART 	:= 0x00000000
RAMSTART 	:= 0x20000000
RAMSIZE 	:= 0x00010000
FLASHSTART 	:= 0x08000000

EXTRAOBJ := build/background.obf

ifeq ($(DEMO),)
$(error Error: DEMO is not set. Expected blinker...)
endif
