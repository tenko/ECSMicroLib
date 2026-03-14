# build library
OB := ecsd
AS := armt32asm

ifdef MSYSTEM
	ECS := /c/EigenCompilerSuite/
else
	ECS := ~/.local/lib/ecs/
endif

OLS += ARMv7M ARMv7MTraps ARMv7MSTM32SysTick0 ARMv7MInterrupt ARMv7MSTM32CycleCount
OLS += Debug Pin BusI2C BusSPI BusUart BusOneWire Timing
OLS += STM32F4 STM32F4Pins STM32F4PinsExtInt STM32F4I2C STM32F4System STM32F4IWDG
OLS += ARMv7MSTM32F4WWDG STM32F4SPI STM32F4Uart STM32F4OneWire
OLS += STM32L4 STM32L4System STM32L4Pins STM32L4Uart STM32L4OneWire
OLS += DeviceDS18B20 DeviceILI9341 DeviceSTMPE811

MOD += $(addprefix src/, $(addprefix Micro., $(addsuffix .mod, $(OLS))))
OBF += $(addprefix build/, $(addprefix Micro., $(addsuffix .obf, $(OLS))))
OBF += build/Micro.StaticData.obf

DOC = Timing Pin Debug BusI2C BusSPI BusUart BusOneWire
DOC += DeviceDS18B20 DeviceILI9341 DeviceSTMPE811
DOC += STM32F4System STM32F4Pins STM32F4I2C STM32F4SPI STM32F4Uart STM32F4OneWire
DOC += STM32L4System STM32L4Pins STM32L4Uart STM32L4OneWire

DRST = $(addprefix doc/src/Micro., $(addsuffix .mod.rst, $(DOC)))

.PHONY: all
all : micro.lib

build/Micro.ARMv7MInterrupt.obf : src/Micro.ARMv7M.mod
build/Micro.ARMv7MSTM32CycleCount.obf : src/Micro.ARMv7M.mod
build/Micro.ARMv7MSTM32F4WWDG.obf : src/Micro.ARMv7M.mod src/Micro.STM32F4.mod src/Micro.ARMv7MTraps.mod
build/Micro.ARMv7MSTM32SysTick0.obf : src/Micro.ARMv7M.mod
build/Micro.ARMv7MTraps.obf : src/Micro.ARMv7M.mod
build/Micro.DeviceDS18B20.obf : src/Micro.BusOneWire.mod
build/Micro.DeviceILI9341.obf : src/Micro.BusSPI.mod src/Micro.Pin.mod src/Micro.Timing.mod
build/Micro.DeviceSTMPE811.obf : src/Micro.BusI2C.mod src/Micro.Timing.mod
build/Micro.STM32F4I2C.obf : src/Micro.ARMv7M.mod src/Micro.BusI2C.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4IWDG.obf : src/Micro.STM32F4.mod
build/Micro.STM32F4OneWire.obf : src/Micro.BusOneWire.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4Pins.obf : src/Micro.ARMv7M.mod src/Micro.STM32F4.mod src/Micro.Pin.mod
build/Micro.STM32F4PinsExtInt.obf : src/Micro.ARMv7M.mod src/Micro.STM32F4.mod src/Micro.STM32F4Pins.mod
build/Micro.STM32F4SPI.obf : src/Micro.ARMv7M.mod src/Micro.BusSPI.mod src/Micro.ARMv7MSTM32SysTick0.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4System.obf : src/Micro.ARMv7M.mod src/Micro.STM32F4.mod
build/Micro.STM32F4Uart.obf : src/Micro.ARMv7M.mod src/Micro.BusUart.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32L4Pins.obf : src/Micro.ARMv7M.mod src/Micro.STM32L4.mod src/Micro.Pin.mod
build/Micro.STM32L4System.obf : src/Micro.ARMv7M.mod src/Micro.STM32L4.mod
build/Micro.STM32L4Uart.obf : src/Micro.ARMv7M.mod src/Micro.BusUart.mod src/Micro.STM32L4Pins.mod src/Micro.STM32L4.mod
build/Micro.STM32L4OneWire.obf : src/Micro.BusOneWire.mod src/Micro.STM32L4Pins.mod src/Micro.STM32L4.mod

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

doc/src/Micro.Timing.mod.rst : src/Micro.Timing.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.Pin.mod.rst : src/Micro.Pin.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.Debug.mod.rst : src/Micro.Debug.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.BusI2C.mod.rst : src/Micro.BusI2C.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.BusSPI.mod.rst : src/Micro.BusSPI.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.BusUart.mod.rst : src/Micro.BusUart.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.BusOneWire.mod.rst : src/Micro.BusOneWire.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.DeviceDS18B20.mod.rst : src/Micro.DeviceDS18B20.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.DeviceILI9341.mod.rst : src/Micro.DeviceILI9341.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.DeviceSTMPE811.mod.rst : src/Micro.DeviceSTMPE811.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32F4System.mod.rst : src/Micro.STM32F4System.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32F4Pins.mod.rst : src/Micro.STM32F4Pins.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32F4I2C.mod.rst : src/Micro.STM32F4I2C.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32F4SPI.mod.rst : src/Micro.STM32F4SPI.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32F4Uart.mod.rst : src/Micro.STM32F4Uart.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32F4OneWire.mod.rst : src/Micro.STM32F4OneWire.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32L4System.mod.rst : src/Micro.STM32L4System.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32L4Pins.mod.rst : src/Micro.STM32L4Pins.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32L4Uart.mod.rst : src/Micro.STM32L4Uart.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.STM32L4OneWire.mod.rst : src/Micro.STM32L4OneWire.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

.PHONY: doc
doc: $(DRST)
	@echo Building doc
	@make -C doc html
	@start "" build/doc/html/index.html &
	
.PHONY: install
install: micro.lib
	@echo Install
	@cp -f micro.lib $(ECS)/runtime/
	@cp -f build/micro.*.sym $(ECS)/libraries/oberon/