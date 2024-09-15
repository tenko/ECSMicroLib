.SUFFIXES:
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

OB := ecsd
AS := armt32asm
DAS := armt32dism
LK := linkmem
QEMU := qemu-system-gnuarmeclipse
QEMUFLAGS=--verbose --board STM32F4-Discovery --mcu STM32F407ZG --semihosting-config enable=on,target=native -d unimp,guest_errors
ECS := /c/EigenCompilerSuite/runtime
MCU := stm32l4

RTS = ../micro.lib $(ECS)/stdarmt32.lib ../$(MCU)run.obf  $(ECS)/armt32run.obf $(ECS)/obarmt32run.lib

OLS += ARMv7M ARMv7MTraps ARMv7MSTM32SysTick0 STM32F4 STM32L4
OLS += BusI2C BusSPI BusUart OneWire CRC16CCITT8408 CRC16CCITT1021 CRC8 MemFormatters Config
OLS += STM32F4Config STM32F4Pins STM32F4System STM32F4IWDG STM32F4Flash ARMv7MSTM32F4WWDG
OLS += STM32F4SPI1 STM32F4Uart STM32F4OneWire STM32F405Uart
OLS += STM32L4Pins
OLS += DeviceDS18B20

MOD += $(addprefix src/, $(addprefix Micro., $(addsuffix .mod, $(OLS))))
OBF += $(addprefix build/, $(addprefix Micro., $(addsuffix .obf, $(OLS))))
OBF += build/Micro.StaticData.obf

.PHONY: all
all : micro.lib $(MCU)run.obf

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

$(MCU)run.obf : build/$(MCU)run.obf
	@cp -f build/$(MCU)run.obf .

build/test.rom: misc/test.mod micro.lib $(MCU)run.obf
	@echo linking $@
	@mkdir -p build
	@cd build && cp -f ../misc/test.mod .
	@cd build && $(OB) -t armt32 -c test.mod
	@cd build && $(LK) test.obf $(RTS)

dis: build/dis.obf build/test.rom
	@cd build && $(DAS) $(notdir $<)

run: build/test.rom
	$(QEMU) $(QEMUFLAGS) --image $<

.PHONY: install
install: micro.lib $(MCU)run.obf
	@echo Install
	@cp -f micro.lib /c/EigenCompilerSuite/runtime/
	@cp -f $(MCU)run.obf /c/EigenCompilerSuite/runtime/
	@cp -f build/micro.*.sym /c/EigenCompilerSuite/libraries/oberon/

.PHONY: clean
clean:
	@echo Clean
	@-rm -rf build