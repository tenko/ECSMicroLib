# General board demo makefile
# This Makefile expects the ECSBASE environment variable set to ECS installation folder
OB := ecsd
AS := armt32asm
DAS := armt32dism
DB := dbgdwarf
LKM := linkmem
LKH := linkhex
QEMU := qemu-system-gnuarmeclipse
STFLASH := st-flash
STUTIL := st-util

# Paths for STMicroelectronics STM32CubeCLT tools.
# These paths needs to checked for your installation
ifdef MSYSTEM
	MXPROGDIR = /c/ST/STM32CubeCLT_1.22.0/STM32CubeProgrammer/bin/
	MXPROG = ${MXPROGDIR}STM32_Programmer_CLI.exe
	MXSTLINK = /c/ST/STM32CubeCLT_1.22.0/STLink-gdb-server/bin/ST-LINK_gdbserver.exe
else
	MXPROGDIR = /opt/stm32cubeclt/STM32CubeProgrammer/bin/
	MXPROG = ${MXPROGDIR}STM32_Programmer_CLI
	MXSTLINK = /opt/stm32cubeclt/STLink-gdb-server/bin/ST-LINK_gdbserver
endif

ifdef MSYSTEM
	GDB = gdb-multiarch.exe
else
	GDB = arm-none-eabi-gdb
endif

ifeq ($(ARCH), ARM)
RTS = ../micro.lib $(ECSBASE)/runtime/stdarmt32.lib $(ECSBASE)/runtime/armt32run.obf $(ECSBASE)/runtime/obarmt32run.lib
else
$(error Error: ARCH=$(ARCH) not supported)
endif

.PHONY: all
all : build/test.rom

build/%.obf: demos/%.mod
	@echo compiling $<
	@mkdir -p build
	@cd build && $(OB) -t armt32 -c $(addprefix ../, $<)

build/%.obf: demos/%.asm
	@echo compiling $<
	@mkdir -p build
	@cd build && $(AS) $(addprefix ../, $<)
	
build/test.rom: build/BoardConfig.obf build/runtime.obf $(EXTRAOBJ) build/test.obf
	@echo linking $@
	@mkdir -p build
	@cd build && $(LKM) $(RTS) $(EXTRALIB) $(notdir $^)
	@cd build && $(LKH) $(RTS) $(EXTRALIB) $(notdir $^)

build/BoardConfig.obf: boards/$(BOARD)/BoardConfig.mod boards/$(BOARD)/config.mk
	@echo building BoardConfig.mod
	@mkdir -p build
	@cp -f boards/$(BOARD)/BoardConfig.mod build/BoardConfig.mod
	@cd build && $(OB) -t armt32 -c BoardConfig.mod

build/runtime.obf:
	@echo building runtime.asm
	@mkdir -p build
	@cp -f src/$(RUNTIME) build/runtime.asm
	@sed -i -e 's/{BOOTSTART}/$(BOOTSTART)/g' build/runtime.asm
	@sed -i -e 's/{RAMSTART}/$(RAMSTART)/g' build/runtime.asm
	@sed -i -e 's/{RAMSIZE}/$(RAMSIZE)/g' build/runtime.asm
	@cd build && $(AS) runtime.asm

build/test.obf: build/BoardConfig.obf demos/$(DEMO).mod
	@echo building $(DEMO)
	@mkdir -p build
	@cp -f demos/$(DEMO).mod build/test.mod
	@cd build && $(OB) -t armt32 -c test.mod

.PHONY: cleandemo
cleandemo:
	@echo Clean demo
	@-rm -f build/test.rom build/test.obf build/BoardConfig.obf build/runtime.obf

.PHONY: flash
flash: build/test.rom
	@$(STFLASH) --connect-under-reset --format binary write build/test.rom $(FLASHSTART)

.PHONY: mxflash
mxflash: build/test.rom
	@-cp -f build/test.rom build/test.bin 
	@$(MXPROG) -c port=SWD -d build/test.bin $(FLASHSTART)

.PHONY: dis
dis: build/dis.obf build/test.rom
	@cd build && $(DAS) $(notdir $<)

.PHONY: server
server:
	@$(STUTIL) --connect-under-reset --semihosting

.PHONY: mxserver
mxserver:
	@$(MXSTLINK) -p 4242 --semihost-console-port 2333 --semihosting terminal -m 1 --swd -e -g -cp $(MXPROGDIR)

.PHONY: gdb
gdb:
	@$(GDB) -ex "target extended localhost:4242" -ex "continue"

.PHONY: gdbpy
gdbpy:
	@$(GDB) -ex "target extended localhost:4242" -ex "source tools/gdb.py" -ex "mapload build/test.map"

