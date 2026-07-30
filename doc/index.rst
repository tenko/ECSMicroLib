#####
Intro
#####

This library is developed for the *ECS Oberon-2 Compiler* as a framework
to work with MCUs.

The `ECS Oberon`_ compiler is implemented according to the original
Oberon-2 `report`_ with modernizing extensions. The language is
particular suited to embedded development due to it's simplicity.

.. _ECS Oberon: https://ecs.openbrace.org/manual/manualch7.html
.. _report: https://github.com/OberonSystem3/TheOberonCompanionCD/blob/main/Papers/Oberon2.pdf?raw=true

Currently the *STM32F4*, *STM32L4* and *STM32C5* MCUs are supported and the following boards are tested:

* `NUCLEO-L432KC`_ STM32L432KC MCU 
* `STM32F407G-DISC1`_ STM32F407VG MCU
* `STM32F429I-DISC1`_ STM32F429ZI MCU
* `STM32C5-EVAL`_ STM32C551CET MCU

.. _NUCLEO-L432KC: https://www.st.com/en/evaluation-tools/nucleo-l432kc.html
.. _STM32F407G-DISC1: https://www.st.com/en/evaluation-tools/stm32f4discovery.html
.. _STM32F429I-DISC1: https://www.st.com/en/evaluation-tools/32f429idiscovery.html
.. _STM32C5-EVAL: https://github.com/tenko/STM32C5-eval-board

This documentation only cover the MCU independent generic part of the framework.

These modules needs to be replaced with the concrete implementation  for the selected MCU target
in the startup of the firmware. Example of this is found in the *BoardConfig.mod* in the boards folder.

The MCU dependent modules extend from the generic Interfaces/buses and the code can largely be written
in a MCU independent way, as is shown in the device drivers code and demos.

.. toctree::
    :maxdepth: 1
    :caption: Common
    :hidden:
    
    src/Micro.Machine.mod
    src/Micro.MachinePin.mod
    src/Micro.MachinePinExtInt.mod
    src/Micro.MachineRTC.mod
    src/Micro.Debug.mod

.. toctree::
    :maxdepth: 1
    :caption: Bus Interfaces
    :hidden:
    
    src/Micro.BusI2C.mod
    src/Micro.BusSPI.mod
    src/Micro.BusUart.mod
    src/Micro.BusOneWire.mod

.. toctree::
    :maxdepth: 1
    :caption: Device Drivers
    :hidden:
    
    src/Micro.DeviceDS18B20.mod
    src/Micro.DeviceILI9341.mod
    src/Micro.DeviceSTMPE811.mod
    
#######
Example
#######

.. literalinclude:: ../demos/blinker.mod
	:language: modula2
	
##################
Indices and tables
##################

* :ref:`genindex`
* :ref:`search`
