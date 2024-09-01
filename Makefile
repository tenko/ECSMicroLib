.SUFFIXES:
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

OB := ecsd
AS := armt32asm
DAS := armt32dism
LK := linkmem
QEMU := qemu-system-gnuarmeclipse
QEMUFLAGS=--verbose --board STM32F4-Discovery --mcu STM32F407ZG --semihosting-config enable=on,target=native -d unimp,guest_errors
ECS := /c/EigenCompilerSuite/runtime

RTS = ../micro.lib $(ECS)/stdarmt32.lib ../stm32f4run.obf  $(ECS)/armt32run.obf $(ECS)/obarmt32run.lib

OLS += ARMv7M ARMv7MTraps ARMv7MSTM32SysTick0 STM32F4
OLS += I2CBus CRC16CCITT8408 CRC16CCITT1021 CRC8 MemFormatters Config OneWire
OLS += STM32F4Config STM32F4Pins STM32F4System STM32F4IWDG STM32F4Flash ARMv7MSTM32F4WWDG STM32F4OneWire
OLS += DeviceDS18B20

MOD += $(addprefix src/, $(addprefix Micro., $(addsuffix .mod, $(OLS))))
OBF += $(addprefix build/, $(addprefix Micro., $(addsuffix .obf, $(OLS))))
OBF += build/Micro.StaticData.obf

.PHONY: all
all : micro.lib stm32f4run.obf

build/Micro.ARMv7MSTM32SysTick0.obf : src/Micro.ARMv7M.mod
build/Micro.STM32F4System.obf : src/Micro.ARMv7M.mod src/Micro.STM32F4.mod

build/%.obf: src/%.mod
	@echo compiling $<
	@mkdir -p build
	@cd build && cp -f $(addprefix ../, $<) .
	@cd build && $(OB) -t armt32 -c $(notdir $<)

build/%.obf: src/%.asm
	@echo compiling $<
	@mkdir -p build
	@cd build && cp -f $(addprefix ../, $<) .
	@cd build && $(AS) $(notdir $<)

micro.lib : $(OBF)
	@echo linking $@
	@-rm $@
	@touch $@
	@linklib $@ $^

stm32f4run.obf : build/stm32f4run.obf
	@cp -f build/stm32f4run.obf .

build/test.rom: misc/test.mod micro.lib stm32f4run.obf
	@echo linking $@
	@mkdir -p build
	@cd build && cp -f ../misc/test.mod .
	@cd build && $(OB) -t armt32 -c test.mod
	@cd build && $(LK) test.obf $(RTS)

dis: build/dis.obf build/test.rom
	@cd build && $(DAS) $(notdir $<)

run: build/test.rom
	$(QEMU) $(QEMUFLAGS) --image $<

.PHONY: clean
clean:
	@echo Clean
	@-rm -rf build