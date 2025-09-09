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
	@echo By default the library is built.
	@echo To build demos, set the BOARD to one of:
	@echo NUCLEO-L432KC, STM32F407G-DISC1 or STM32F429I-DISC1
	@echo example : make BOARD=STM32F407G-DISC1 DEMO=blinker sim

.PHONY: clean
clean:
	@echo Clean
	@-rm micro.lib
	@-rm -rf build