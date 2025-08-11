# Board specific configuration
RUNTIME 	:= stm32f4run.asm
BOOTSTART 	:= 0x00000000
RAMSTART 	:= 0x20000000
RAMSIZE 	:= 0x00008000
FLASHSTART 	:= 0x08000000
QEMUFLAGS := --verbose --board STM32F4-Discovery --mcu STM32F407ZG --semihosting-config enable=on,target=native -d unimp,guest_errors

ifeq ($(DEMO),)
$(error Error: DEMO is not set. Expected blinker.)
endif
