#####
Intro
#####

This library is developed for the *ECS Oberon-2 Compiler* as a framework
to work with MCUs.

The `ECS Oberon`_ compiler is implemented according to the original
Oberon-2 `report`_ with modernizing extensions. The language is
particular suited to embedded development due to it's simplicity.

.. _ECS Oberon: https://ecs.openbrace.org/manual/manualch7.html
.. _report: https://www.ssw.uni-linz.ac.at/Research/Papers/Oberon2.pdf

Currently the *STM32F4*, *STM32L4* MCUs are supported and the following
boards are tested:

* `NUCLEO-L432KC`_ STM32L432KC MCU 
* `STM32F407G-DISC1`_ STM32F407VG MCU
* `STM32F429I-DISC1`_ STM32F429ZI MCU

.. _NUCLEO-L432KC: https://www.st.com/en/evaluation-tools/nucleo-l432kc.html
.. _STM32F407G-DISC1: https://www.st.com/en/evaluation-tools/stm32f4discovery.html
.. _STM32F429I-DISC1: https://www.st.com/en/evaluation-tools/32f429idiscovery.html

.. toctree::
    :maxdepth: 1
    :caption: Generic:
    :hidden:
    
    src/Micro.Timing.mod
    src/Micro.Pin.mod
    src/Micro.Debug.mod
    src/Micro.BusI2C.mod
    src/Micro.BusSPI.mod
    src/Micro.BusUart.mod
    src/Micro.BusOneWire.mod
    src/Micro.DeviceDS18B20.mod
    src/Micro.DeviceILI9341.mod
    src/Micro.DeviceSTMPE811.mod

.. toctree::
    :maxdepth: 1
    :caption: STM32F4:
    :hidden:

    src/Micro.STM32F4System.mod
    src/Micro.STM32F4Pins.mod
    src/Micro.STM32F4I2C.mod
    src/Micro.STM32F4SPI.mod
    src/Micro.STM32F4Uart.mod
    src/Micro.STM32F4OneWire.mod
 
.. toctree::
    :maxdepth: 1
    :caption: STM32L4:
    :hidden:
    
    src/Micro.STM32L4System.mod
    src/Micro.STM32L4Pins.mod
    src/Micro.STM32L4Uart.mod
    src/Micro.STM32L4OneWire.mod
    
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
