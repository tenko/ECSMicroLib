# Board specific configuration
RUNTIME 	:= stm32l4run.asm
BOOTSTART 	:= 0x00000000
RAMSTART 	:= 0x20000000
RAMSIZE 	:= 0x00008000
FLASHSTART 	:= 0x08000000

ifeq ($(DEMO),)
$(error Error: DEMO is not set. Expected blinker.)
endif
