# build library
OB := ecsd
AS := armt32asm

ifdef MSYSTEM
	ECS := /c/EigenCompilerSuite/
else
	ECS := ~/.local/lib/ecs/
endif

OLS += ARMv7M ARMv7MTraps ARMv7MSTM32SysTick0 ARMv7MInterrupt STM32F4
OLS += Pin BusI2C BusSPI BusUart OneWire Display ADTRingBuffer
OLS += STM32F4Pins STM32F4I2C STM32F4System STM32F4IWDG
OLS += ARMv7MSTM32F4WWDG STM32F4SPI STM32F4Uart STM32F4OneWire
OLS += STM32L4 STM32L4System STM32L4Pins STM32L4Uart
OLS += DeviceDS18B20 DeviceILI9341

MOD += $(addprefix src/, $(addprefix Micro., $(addsuffix .mod, $(OLS))))
OBF += $(addprefix build/, $(addprefix Micro., $(addsuffix .obf, $(OLS))))
OBF += build/Micro.StaticData.obf

.PHONY: all
all : micro.lib

build/Micro.ARMv7MSTM32SysTick0.obf : src/Micro.ARMv7M.mod
build/Micro.STM32F4System.obf : src/Micro.ARMv7M.mod src/Micro.STM32F4.mod
build/Micro.STM32L4System.obf : src/Micro.ARMv7M.mod src/Micro.STM32L4.mod

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

.PHONY: install
install: micro.lib
	@echo Install
	@cp -f micro.lib $(ECS)/runtime/
	@cp -f build/micro.*.sym $(ECS)/libraries/oberon/