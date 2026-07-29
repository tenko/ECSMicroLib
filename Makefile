.SUFFIXES:
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

ifeq ($(BOARD),)
$(BOARD is not set. Building library.)
include build.mk
else
include boards/$(BOARD)/config.mk
include boards/build.mk
include boards/$(BOARD)/build.mk
endif

.PHONY: help
help:
	@echo By default only the library is built.
	@echo To build demos, set the BOARD to one of:
	@echo "   NUCLEO-L432KC, STM32C5-EVAL, STM32F407G-DISC1 or STM32F429I-DISC1"
	@echo Example run simulation and the blinker demo:
	@echo "   make BOARD=STM32F407G-DISC1 DEMO=blinker sim"
	@echo Example to flash demo binary:
	@echo "   make BOARD=STM32F407G-DISC1 DEMO=blinker flash"
	@echo Example start GDB server:
	@echo "   make BOARD=STM32F407G-DISC1 DEMO=blinker server"
	@echo Example start GDB and connect to GDB server:
	@echo "   make BOARD=STM32F407G-DISC1 DEMO=blinker gdb"
	@echo Clean demo files only:
	@echo "   make BOARD=STM32F407G-DISC1 DEMO=blinker cleandemo"
	@echo To use the STMicroelectronics prefix the flash, server and gdb target with "mx".
	@echo Remember to verify the tool paths in the file boards/build.mk to match your installation.

.PHONY: clean
clean:
	@echo Clean
	@-rm micro.lib
	@-rm -rf build
	@-rm -rf doc/src