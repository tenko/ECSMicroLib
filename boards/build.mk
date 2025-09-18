# General board demo makefile
OB := ecsd
AS := armt32asm
DAS := armt32dism
DB := dbgdwarf
LKM := linkmem
LKH := linkhex
QEMU := qemu-system-gnuarmeclipse

ifdef MSYSTEM
	ECS := /c/EigenCompilerSuite
	STFLASH := st-flash.exe
	STUTIL := st-util.exe
	GDB := arm-none-eabi-gdb.exe
else
	ECS := ~/.local/lib/ecs
	STFLASH := st-flash
	STUTIL := st-util
	GDB := arm-none-eabi-gdb
endif

RTS = ../micro.lib $(ECS)/runtime/stdarmt32.lib $(ECS)/runtime/gfxarmt32.lib $(ECS)/runtime/armt32run.obf $(ECS)/runtime/obarmt32run.lib

.PHONY: all
all : build/test.rom

build/%.obf: demos/%.mod
	@echo compiling $<
	@mkdir -p build
	@cd build && cp -f $(addprefix ../, $<) .
	@cd build && $(OB) -t armt32 -c $(notdir $<)

build/%.obf: demos/%.asm
	@echo compiling $<
	@mkdir -p build
	@cd build && cp -f $(addprefix ../, $<) .
	@cd build && $(AS) $(notdir $<)
	
build/test.rom: build/test.obf build/BoardConfig.obf build/runtime.obf $(EXTRAOBJ)
	@echo linking $@
	@mkdir -p build
	@cd build && $(LKM) $(notdir $^) $(RTS)
	@cd build && $(LKH) $(notdir $^) $(RTS)

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

.PHONY: flash
flash: build/test.rom
	@$(STFLASH) --connect-under-reset --format binary write build/test.rom $(FLASHSTART)

.PHONY: dis
dis: build/dis.obf build/test.rom
	@cd build && $(DAS) $(notdir $<)

.PHONY: server
server:
	@$(STUTIL) --connect-under-reset --semihosting

.PHONY: gdb
gdb:
	@$(GDB) -ex "target extended localhost:4242" -ex "continue"
	