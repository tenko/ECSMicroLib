# ECSMicroLib
**[ECS](https://ecs.openbrace.org/)** Oberon-2 Compiler framework for ARM32 MCUs

Some of the code is ported from Alexander V. Shiryaev's [O7 Micro](https://github.com/aixp/O7) framework for *Oberon-07*
based on the *Black Box* compiler.

**Features**

- *MCU* independent modules for hardware access : [Machine](https://tenko.github.io/ECSMicroLib/src/Micro.Machine.mod.html), [MachinePin](https://tenko.github.io/ECSMicroLib/src/Micro.MachinePin.mod.html), , [MachinePinExtInt](https://tenko.github.io/ECSMicroLib/src/Micro.MachinePinExtInt.mod.html) and [MachineRTC](https://tenko.github.io/ECSMicroLib/src/Micro.MachineRTC.mod.html).
- *MCU* independent bus modules for devices : [BusI2C](https://tenko.github.io/ECSMicroLib/src/Micro.BusI2C.mod.html), [BusOneWire](https://tenko.github.io/ECSMicroLib/src/Micro.BusOneWire.mod.html), [BusSPI](https://tenko.github.io/ECSMicroLib/src/Micro.BusSPI.mod.html) and [BusUart](https://tenko.github.io/ECSMicroLib/src/Micro.BusUart.mod.html).
- *Debug CLI* interface module : [Debug](https://tenko.github.io/ECSMicroLib/src/Micro.Debug.mod.html).
- *MCU* independent drivers for devices : [DeviceDS18B20](https://tenko.github.io/ECSMicroLib/src/Micro.DeviceDS18B20.mod.html), [DeviceILI9341](https://tenko.github.io/ECSMicroLib/src/Micro.DeviceILI9341.mod.html) and [DeviceSTMPE811](https://tenko.github.io/ECSMicroLib/src/Micro.DeviceSTMPE811.mod.html).
- A fairly complete standard library in [ECSStdLib](https://github.com/tenko/ECSStdLib) is available.
- Coroutines is supported through the standard library. Ref. the example in *demos/taks.mod*.

**Why Oberon-2?**

[ECSOberon](https://ecs.openbrace.org/) has a number of benefits for *MCU* firmware applications:

- Simplest possible language (the [language report](https://github.com/OberonSystem3/TheOberonCompanionCD/blob/main/Papers/Oberon2.pdf?raw=true) is 20 pages), yet supporting 
  object oriented design with single inheritance.
- The language has the bit *SET* type which makes fiddling with bit register of the *MCU* very easy and natural.
- The *ECSOberon* language is updated with manual allocation, unsigned types, variable pointers, packages and simple templates.
  Making the language more practical for system programming and *MCUs* than the original *Oberon-2* implementation.
- No header files to worry about. The visibility of the code elements is defined directly in the module.
- The module and package concept keeps the code cleanly segregated and avoid the problem with colliding names in *C*.
- The [documentation](https://ecs.openbrace.org/manual/) is excellent and reported bugs is fixed quickly.

The drawbacks of *ECSOberon*:

- *Oberon-2* is a verbose language and require upper case keyword.
  However with an *IDE* and auto-completion this is a minor issue in my opinion.
- No support for a pre-processor. Some cases can be solved with help of templates, but otherwise
  this must be solved with shell scripts.
  However this omission keeps the code base readable in my opinion.
- Not much existing code exists and many things must be implemented from scratch.
  Code from the original [OberonSystem 3](https://github.com/OberonSystem3) or from [BlackBox Component Builder](https://blackbox.oberon.org/) could be reused.
  
  This is the major drawback in my opinion.

## Boards

Currently supported boards:

* [NUCLEO-L432KC](https://www.st.com/en/evaluation-tools/nucleo-l432kc.html) STM32L432KC MCU 
* [STM32F407G-DISC1](https://www.st.com/en/evaluation-tools/stm32f4discovery.html) STM32F407VG MCU
* [STM32F429I-DISC1](https://www.st.com/en/evaluation-tools/32f429idiscovery.html) STM32F429ZI MCU
* [STM32C5-EVAL](https://github.com/tenko/STM32C5-eval-board) STM32C551CET MCU

These are the boards I have on hand and are able to test. Most *STM32F4*, *STM32L4*, *STM32C5*
boards/*MCU* would work if the *RAM* is correctly adjusted for in the config.

Note that the *STM32C5 MCU* familiy is new and I could only get the *STMicroelectronics* original software
and hardware to work with flashing the device.
The *CLI* version of the tools in [STM32CubeCLT](https://www.st.com/en/development-tools/stm32cubeclt.html) is recommended
and the paths in *boards/build.mk* must be verified for your installation.
The *Makefile* target is then *mxflash*, *mxserver* for *STM32C5* support.

The [ECS](https://ecs.openbrace.org/) compiler support more targets like *AVR*, *AVR32*, *Xtensa* so
it should be possible to support more architectures.

## Installation

Build instructions here are for a current *ArchLinux* version, but should
be possible to adapt to other *Linux* distributions.

*Windows MSYS2 (CLANG64)* also can follow these instructions and
is known to work well, but is much slower than on *Linux*.

Alternative on the **Windows** platform is just to download the official installer.

```shell
# Build and install patched version of ECS
pacman -S wget make clang sdl2-compat
wget https://software.openbrace.org/attachments/download/418/ecs-2026.08.10.tar.gz
tar -xavf ecs-2026.08.10.tar.gz
cd ecs
sed -i 's/@cp $(wildcard $(pdf))/#@cp $(wildcard $(pdf))/g' makefile # avoid stop on PDF installation
make -j 4 toolchain=clang all # adjust j argument to your CPU core count
# install to ~/.local/[bin|lib|share] or other setup of choice
make toolchain=clang prefix=~/.local install
make clean
# add to PATH variable (adapt to your shell and setup)
echo 'export PATH=~/.local/bin/:~/.local/lib/ecs/tools/:$PATH' >> ~/.bashrc
echo 'export ECSBASE=~/.local/lib/ecs/' >> ~/.bashrc
cd ..

# Build and install ECSStdLib
pacman -S dos2unix
git clone https://github.com/tenko/ECSStdLib.git
cd ECSStdLib
# Build arm32 library
make -f Makefile.arm32t
make -f Makefile.arm32t PREFIX=~/.local install  # install to ~/.local/lib
# Run arm32 emulated tests. Needs xpack-qemu-arm 7.2.5
make -f Makefile.arm32t TestMain
cd ..

# Build and install ECSMicroLib
pacman -S arm-none-eabi-gdb stlink # gdb-multiarch on MSYS2
git clone https://github.com/tenko/ECSMicroLib.git
cd ECSMicroLib
# Build arm32 library
make 
make PREFIX=~/.local install  # install to ~/.local/lib
make help # Shows help message
# Run simulated board test if xpack-qemu-arm is installed
make BOARD=STM32F407G-DISC1 DEMO=blinker sim

```

## Example

Hello world for *STM32* MCU with LED blinking.

Test.mod (saved as *demos/test.mod*):

```modula-2
MODULE Test;
IMPORT BoardConfig;
IMPORT Machine IN Micro;

CONST
    Debug = TRUE; (* Set Debug = FALSE to allow to run demo without debugger *)
    Pins = BoardConfig.Pins;

VAR pin : Pins.Pin;

BEGIN
    IF Debug THEN TRACE("START") END;
    BoardConfig.Init;
    
    pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
    
    REPEAT
        pin.On;
        IF Debug THEN TRACE("ON0") END;
        Machine.DelayMS(100);
        pin.Off;
        IF Debug THEN TRACE("OFF0") END;
        Machine.DelayMS(100);
    UNTIL FALSE
END Test.
```

Building & Running:

```
make BOARD=STM32F429I-DISC1 DEMO=test
make BOARD=STM32F429I-DISC1 DEMO=test flash
make BOARD=STM32F429I-DISC1 DEMO=test server
make BOARD=STM32F429I-DISC1 DEMO=test gdb # run in other shell
```

The *Makefile* uses the *stlink* utility to flash the firmware and uses the
*GDB* to start and monitor the example.

## Debugging

Support for debugging is limited as the output files are raw binaries and no *.elf* with debug information is available.

However there is an *GDB* extension in *tools/gdb.py* which supports loading of symbols from the *.map* files
generated by the compiler. A custom stop handler is installed which prints out the procedure where the current *PC* was stopped.
The new *mapinfo* command find symbol names, prints output depending on the symbol type and support auto completion.

Example session:
```
make BOARD=STM32F429I-DISC1 DEMO=blinker gdbpy
Map file 'build/test.map' parsed. 218 items added.
(gdb) continue
Continuing.
^C
Program received signal SIGINT, Interrupt.
0x00000bae in ?? ()
Stopped execution at offset 2 in PROCEDURE delay_idle
(gdb) mapinfo delay_idle
Dump of assembler code from 0xbac to 0xbb0:
   0x00000bac:  bf30            wfi
=> 0x00000bae:  4770            bx      lr
End of assembler dump.
```
## Editors

There is setup for [cudatext](https://cudatext.github.io/) and [micro](https://micro-editor.github.io/) editors
in the *tools/editors* folder.

## TODO

* Add missing drivers for *STM32L4* and *STM32C5 MCUs*.
* Update *I2C*, *OneWire* and *SPI* drivers to polling for efficient use in coroutines.
* Add support for a embedded filesystem (*Squashfs* and/or *FAT16*)

## Documentation

Complete API Documentation: [Link](https://tenko.github.io/ECSMicroLib/)  

