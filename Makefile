.SUFFIXES:
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

OB := obarmt32
AS := armt32asm
LK := linkmem
QEMU := qemu-system-gnuarmeclipse
QEMUFLAGS=--verbose --board STM32F4-Discovery --mcu STM32F407ZG --semihosting-config enable=on,target=native -d unimp,guest_errors
ECS := /c/EigenCompilerSuite/runtime

RTS = ../micro.lib ../stdarmt32.lib ../stm32f4run.obf $(ECS)/armt32run.obf $(ECS)/obarmt32run.lib

OLS += ARMv7M ARMv7MSTM32SysTick0 STM32F4 STM32F4Pins STM32F4System

MOD = $(addprefix src/, $(addprefix Micro., $(addsuffix .mod, $(OLS))))
OBF = $(addprefix build/, $(addprefix Micro., $(addsuffix .obf, $(OLS))))

.PHONY: all
all : micro.lib

build/Micro.ARMv7MSTM32SysTick0.obf : src/Micro.ARMv7M.mod
build/Micro.STM32F4System.obf : src/Micro.ARMv7M.mod src/Micro.STM32F4.mod

build/%.obf: src/%.mod
	@echo compiling $<
	@mkdir -p build
	@cd build && cp -f $(addprefix ../, $<) .
	@cd build && $(OB) $(notdir $<)

micro.lib : $(OBF)
	@echo linking $@
	@-rm $@
	@touch $@
	@linklib $@ $^

build/test.rom: misc/test.mod micro.lib
	@echo linking $@
	@mkdir -p build
	@cd build && cp -f ../misc/test.mod .
	@cd build && $(OB) test.mod
	@cd build && $(LK) test.obf $(RTS)

run: build/test.rom
	$(QEMU) $(QEMUFLAGS) --image $<

.PHONY: clean
clean:
	@echo Clean
	@-rm -rf build