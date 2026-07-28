# build library
OB := ecsd
AS := armt32asm

# Installation prefix
PREFIX = /usr/local

# Achitecture (For now only ARMv7M and ARMv8M is supported)
ARCH = ARM

OLS += ArchArm ArchArmTraps ArchArmSysTick ArchArmInterrupt ArchArmCycleCount
OLS += Debug BusI2C BusSPI BusUart BusOneWire
OLS += Machine MachinePin MachinePinExtInt MachineRTC
OLS += STM32F4 STM32F4Pins STM32F4PinsExtInt STM32F4I2C STM32F4System STM32F4IWDG
OLS += STM32F4SPI STM32F4Uart STM32F4OneWire
OLS += STM32L4 STM32L4System STM32L4Pins STM32L4Uart STM32L4OneWire
OLS += STM32C5 STM32C5System STM32C5Pins STM32C5PinsExtInt STM32C5Uart STM32C5RTC
OLS += DeviceDS18B20 DeviceILI9341 DeviceSTMPE811

MOD += $(addprefix src/, $(addprefix Micro., $(addsuffix .mod, $(OLS))))
OBF += $(addprefix build/, $(addprefix Micro., $(addsuffix .obf, $(OLS))))
OBF += build/Micro.StaticData.obf
OBF += build/stm32.obf

DOC = Debug BusI2C BusSPI BusUart BusOneWire
DOC += Machine MachinePin MachinePinExtInt MachineRTC
DOC += DeviceDS18B20 DeviceILI9341 DeviceSTMPE811

DRST = $(addprefix doc/src/Micro., $(addsuffix .mod.rst, $(DOC)))

.PHONY: all
all : micro.lib

# ArchArm
build/Micro.ArchArmInterrupt.obf : src/Micro.ArchArm.mod
build/Micro.ArchArmCycleCount.obf : src/Micro.ArchArm.mod
build/Micro.ArchArmSysTick.obf : src/Micro.ArchArm.mod
build/Micro.ArchArmTraps.obf : src/Micro.ArchArm.mod
# Devices
build/Micro.DeviceDS18B20.obf : src/Micro.BusOneWire.mod
build/Micro.DeviceILI9341.obf : src/Micro.BusSPI.mod src/Micro.MachinePin.mod src/Micro.Machine.mod
build/Micro.DeviceSTMPE811.obf : src/Micro.BusI2C.mod src/Micro.Machine.mod
# STM32C5
build/Micro.STM32C5.obf : src/Micro.ArchArm.mod
build/Micro.STM32C5Pins.obf : src/Micro.ArchArm.mod src/Micro.STM32C5.mod src/Micro.MachinePin.mod
build/Micro.STM32C5PinsExtInt.obf : src/Micro.ArchArm.mod src/Micro.STM32C5.mod src/Micro.STM32C5Pins.mod src/Micro.MachinePinExtInt.mod
build/Micro.STM32C5RTC.obf : src/Micro.ArchArm.mod src/Micro.STM32C5.mod src/Micro.MachineRTC.mod
build/Micro.STM32C5System.obf : src/Micro.ArchArm.mod src/Micro.STM32C5.mod
build/Micro.STM32C5Uart.obf : src/Micro.ArchArm.mod src/Micro.BusUart.mod src/Micro.STM32C5Pins.mod src/Micro.STM32C5.mod
# STM32F4
build/Micro.STM32F4I2C.obf : src/Micro.ArchArm.mod src/Micro.BusI2C.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4IWDG.obf : src/Micro.STM32F4.mod
build/Micro.STM32F4OneWire.obf : src/Micro.BusOneWire.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4Pins.obf : src/Micro.ArchArm.mod src/Micro.STM32F4.mod src/Micro.MachinePin.mod
build/Micro.STM32F4PinsExtInt.obf : src/Micro.ArchArm.mod src/Micro.STM32F4.mod src/Micro.STM32F4Pins.mod
build/Micro.STM32F4SPI.obf : src/Micro.ArchArm.mod src/Micro.BusSPI.mod src/Micro.ArchArmSysTick.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4System.obf : src/Micro.ArchArm.mod src/Micro.STM32F4.mod
build/Micro.STM32F4Uart.obf : src/Micro.ArchArm.mod src/Micro.BusUart.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
# STM32L4
build/Micro.STM32L4Pins.obf : src/Micro.ArchArm.mod src/Micro.STM32L4.mod src/Micro.MachinePin.mod
build/Micro.STM32L4System.obf : src/Micro.ArchArm.mod src/Micro.STM32L4.mod
build/Micro.STM32L4Uart.obf : src/Micro.ArchArm.mod src/Micro.BusUart.mod src/Micro.STM32L4Pins.mod src/Micro.STM32L4.mod
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

doc/src/Micro.Machine.mod.rst : src/Micro.Machine.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.MachinePin.mod.rst : src/Micro.MachinePin.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.MachinePinExtInt.mod.rst : src/Micro.MachinePinExtInt.mod
	@-mkdir -p doc/src
	./tools/docgen.py $< -o $@

doc/src/Micro.MachineRTC.mod.rst : src/Micro.MachineRTC.mod
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

.PHONY: doc
doc: $(DRST)
	@echo Building doc
	@make -C doc html
	@start "" build/doc/html/index.html &
	
.PHONY: install
install: micro.lib
	@echo Install
	@cp -f micro.lib $(PREFIX)/lib/ecs/runtime/
	@cp -f build/micro.*.sym $(PREFIX)/lib/ecs/libraries/oberon/
