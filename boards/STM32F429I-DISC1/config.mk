# Board specific configuration
ARCH 		:= ARM
RUNTIME 	:= stm32f429run.asm
BOOTSTART 	:= 0x00000000
RAMSTART 	:= 0x20000000
RAMSIZE 	:= 0x00010000
FLASHSTART 	:= 0x08000000

ifeq ($(DEMO),)
$(error Error: DEMO is not set. Expected blinker...)
endif

ifeq ($(DEMO), ILI9341FB)
EXTRALIB := $(ECSBASE)/runtime/gfxarmt32.lib
# EXTRAOBJ := build/background.obf
endif
