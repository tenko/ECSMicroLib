# build library
OB := ecsd
AS := armt32asm

# Installation prefix
PREFIX = /usr/local

# Achitecture (For now only ARM covering ARMv7M and ARMv8M is supported)
ARCH = ARM

ifeq ($(ARCH), ARM)
OLS += ArchArm ArchArmTraps ArchArmSysTick ArchArmInterrupt ArchArmCycleCount
else
$(error Error: ARCH=$(ARCH) not supported)
endif

OLS += Debug BusI2C BusSPI BusUart BusOneWire
OLS += Machine MachinePin MachinePinExtInt MachineRTC
OLS += DeviceDS18B20 DeviceILI9341 DeviceSTMPE811

ifeq ($(ARCH), ARM)
OLS += STM32F4 STM32F4Pins STM32F4PinsExtInt STM32F4I2C STM32F4RCC STM32F4IWDG
OLS += STM32F4SPI STM32F4Uart STM32F4OneWire
OLS += STM32L4 STM32L4RCC STM32L4Pins STM32L4Uart STM32L4OneWire
OLS += STM32C5 STM32C5RCC STM32C5Pins STM32C5PinsExtInt STM32C5Uart STM32C5RTC
else
$(error Error: ARCH=$(ARCH) not supported)
endif

MOD += $(addprefix src/, $(addprefix Micro., $(addsuffix .mod, $(OLS))))
OBF = build/stm32.obf
OBF += $(addprefix build/, $(addprefix Micro., $(addsuffix .obf, $(OLS))))
OBF += build/Micro.StaticData.obf

DOC = Debug BusI2C BusSPI BusUart BusOneWire
DOC += Machine MachinePin MachinePinExtInt MachineRTC
DOC += DeviceDS18B20 DeviceILI9341 DeviceSTMPE811

DRST += $(addprefix doc/src/, $(addprefix Micro., $(addsuffix .mod.rst, $(DOC))))

.PHONY: all
all : micro.lib

# ArchArm
ifeq ($(ARCH), ARM)
build/Micro.ArchArmInterrupt.obf : src/Micro.ArchArm.mod
build/Micro.ArchArmCycleCount.obf : src/Micro.ArchArm.mod
build/Micro.ArchArmSysTick.obf : src/Micro.ArchArm.mod
build/Micro.ArchArmTraps.obf : src/Micro.ArchArm.mod
else
$(error Error: ARCH=$(ARCH) not supported)
endif

# Devices
build/Micro.DeviceDS18B20.obf : src/Micro.BusOneWire.mod
build/Micro.DeviceILI9341.obf : src/Micro.BusSPI.mod src/Micro.MachinePin.mod src/Micro.Machine.mod
build/Micro.DeviceSTMPE811.obf : src/Micro.BusI2C.mod src/Micro.Machine.mod

ifeq ($(ARCH), ARM)
# STM32C5
build/Micro.STM32C5.obf : src/Micro.ArchArm.mod
build/Micro.STM32C5Pins.obf : src/Micro.ArchArm.mod src/Micro.STM32C5.mod src/Micro.MachinePin.mod
build/Micro.STM32C5PinsExtInt.obf : src/Micro.ArchArm.mod src/Micro.STM32C5.mod src/Micro.STM32C5Pins.mod src/Micro.MachinePinExtInt.mod
build/Micro.STM32C5RTC.obf : src/Micro.ArchArm.mod src/Micro.STM32C5.mod src/Micro.MachineRTC.mod
build/Micro.STM32C5RCC.obf : src/Micro.ArchArm.mod src/Micro.STM32C5.mod
build/Micro.STM32C5Uart.obf : src/Micro.ArchArm.mod src/Micro.BusUart.mod src/Micro.STM32C5Pins.mod src/Micro.STM32C5.mod
# STM32F4
build/Micro.STM32F4I2C.obf : src/Micro.ArchArm.mod src/Micro.BusI2C.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4IWDG.obf : src/Micro.STM32F4.mod
build/Micro.STM32F4OneWire.obf : src/Micro.BusOneWire.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4Pins.obf : src/Micro.ArchArm.mod src/Micro.STM32F4.mod src/Micro.MachinePin.mod
build/Micro.STM32F4PinsExtInt.obf : src/Micro.ArchArm.mod src/Micro.STM32F4.mod src/Micro.STM32F4Pins.mod
build/Micro.STM32F4SPI.obf : src/Micro.ArchArm.mod src/Micro.BusSPI.mod src/Micro.ArchArmSysTick.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
build/Micro.STM32F4RCC.obf : src/Micro.ArchArm.mod src/Micro.STM32F4.mod
build/Micro.STM32F4Uart.obf : src/Micro.ArchArm.mod src/Micro.BusUart.mod src/Micro.STM32F4Pins.mod src/Micro.STM32F4.mod
# STM32L4
build/Micro.STM32L4Pins.obf : src/Micro.ArchArm.mod src/Micro.STM32L4.mod src/Micro.MachinePin.mod
build/Micro.STM32L4RCC.obf : src/Micro.ArchArm.mod src/Micro.STM32L4.mod
build/Micro.STM32L4Uart.obf : src/Micro.ArchArm.mod src/Micro.BusUart.mod src/Micro.STM32L4Pins.mod src/Micro.STM32L4.mod
build/Micro.STM32L4OneWire.obf : src/Micro.BusOneWire.mod src/Micro.STM32L4Pins.mod src/Micro.STM32L4.mod
else
$(error Error: ARCH=$(ARCH) not supported)
endif

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

doc/src/%.mod.rst: src/%.mod
	@echo compiling $<
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
