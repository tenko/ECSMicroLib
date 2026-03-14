# ECSMicroLib
**[ECS](https://ecs.openbrace.org/)** Oberon-2 Compiler framework for ARM32 MCUs

Some of the code is ported from Alexander V. Shiryaev's O7 Micro framework for Oberon-07
based on the Black Box compiler.

Original project [Link](https://github.com/aixp/O7)

## Boards

Currently supported boards:

* [NUCLEO-L432KC](https://www.st.com/en/evaluation-tools/nucleo-l432kc.html) STM32L432KC MCU 
* [STM32F407G-DISC1](https://www.st.com/en/evaluation-tools/stm32f4discovery.html) STM32F407VG MCU
* [STM32F429I-DISC1](https://www.st.com/en/evaluation-tools/32f429idiscovery.html) STM32F429ZI MCU

These are the boards I have on hand and are able to test. Most **STM32F4**, **STM32L4** boards would work
if the RAM is correctly adjusted for in the config.

The original framework support further MCUs, but these are removed until it is possible to test these.

Also the **[ECS](https://ecs.openbrace.org/)** compiler support more targets like **AVR**, **AVR32**, **Xtensa**: [Link](https://ecs.openbrace.org/manual/manualpa3.html#x53-496000III) 

## Installation

Build instructions here are for a current **ArchLinux** version, but should
be possible to adapt to other **Linux** distributions.

**Windows MSYS2** (CLANG64) also can follow these instructions and
is known to work well, but is much slower than on **Linux**.

```shell
# Build and install patched version of ECS
pacman -S git make clang sdl2-compat
git clone https://github.com/tenko/ECS.git
cd ECS
make toolchain=clang all # takes some time to finish
# install to ~/.local/[bin|lib|share] or other setup of choice
make toolchain=clang prefix=~/.local install
make clean
# add to PATH variable (adapt to your shell and setup)
echo "export PATH=~/.local/bin/:~/.local/lib/ecs/tools/:$PATH" >> ~/.bashrc
cd ..

# Build and install ECSStdLib
pacman -S dos2unix
git clone https://github.com/tenko/ECSStdLib.git
cd ECSStdLib
# Build native library
make 
make install # install to ~/.local/lib
make TestMain # run library tests
make clean
# Build arm32 library
make -f Makefile.arm32t
make -f Makefile.arm32t install  # install to ~/.local/lib
# Run arm32 emulated tests. Needs xpack-qemu-arm 7.2.5
make -f Makefile.arm32t TestMain
cd ..

# Build and install ECSGfxLib
git clone https://github.com/tenko/ECSGfxLib.git
cd ECSGfxLib
# Build native library
make
make install # install to ~/.local/lib
make Tests # run library tests
make clean
# Build arm32 library
make -f Makefile.arm32t
make -f Makefile.arm32t install  # install to ~/.local/lib
cd ..

# Build and install ECSMicroLib
pacman -S arm-none-eabi-gdb stlink
git clone https://github.com/tenko/ECSMicroLib.git
cd ECSMicroLib
# Build arm32 library
make 
make install  # install to ~/.local/lib
make help # Shows help message
# Run simulated board test if xpack-qemu-arm is installed
make BOARD=STM32F407G-DISC1 DEMO=blinker sim

```

## Example

Hello world for **STM32** MCU with LED blinking.

Test.mod:

```modula-2
MODULE Test;
IMPORT BoardConfig;

CONST
    SysTick = BoardConfig.SysTick;
    Pins = BoardConfig.Pins;

VAR pin : Pins.Pin;

BEGIN
	TRACE("START");
    BoardConfig.Init;
    
    pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
    
    REPEAT
        pin.On;
        TRACE("ON0");
        SysTick.Delay(100);
        pin.Off;
        TRACE("OFF0");
        SysTick.Delay(100);
    UNTIL FALSE
END Test.
```

Building & Running

```
make BOARD=STM32F429I-DISC1 DEMO=test # saved as 'demos/test.mod'
make BOARD=STM32F429I-DISC1 DEMO=test flash
make BOARD=STM32F429I-DISC1 DEMO=test server # start stlink server
make BOARD=STM32F429I-DISC1 DEMO=test gdb # run in other shell
```

The Makefile uses the stlink utility to flash the firmware and uses the
GDB to start and monitor the example.

## TODO

* Update I2C, OneWire and SPI drivers to polling for efficient use in coroutines.
* Add more drivers to more MCU peripherals as needed.
* Add support for embedded filesystem (Squashfs and FAT16)

## Note

Complete API Documentation: [Link](https://tenko.github.io/ECSMicroLib/)  

