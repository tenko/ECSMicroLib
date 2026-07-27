# Board specific targets

ifdef MSYSTEM
	MXPROGDIR = ${USERPROFILE}/AppData/Local/stm32cube/bundles/programmer/2.22.0+st.1/bin
	MXPROG = ${USERPROFILE}/AppData/Local/stm32cube/bundles/programmer/2.22.0+st.1/bin/STM32_Programmer_CLI.exe
	MXSTLINK = ${USERPROFILE}/AppData/Local/stm32cube/bundles/stlink-gdbserver/7.13.0+st.3/bin/ST-LINK_gdbserver.exe
	MXGDB = gdb-multiarch.exe
else
	MXPROGDIR = /opt/stm32cubeprog/bin/
	MXPROG = ${MXPROGDIR}/STM32_Programmer_CLI
	MXSTLINK = /opt/stm32cubeide/plugins/com.st.stm32cube.ide.mcu.externaltools.stlink-gdb-server.linux64_2.2.500.202604010938/tools/bin/ST-LINK_gdbserver
	MXGDB = arm-none-eabi-gdb
endif

.PHONY: mxflash
mxflash: build/test.rom
	@-cp -f build/test.rom build/test.bin 
	@$(MXPROG) -c port=SWD -d build/test.bin 0x08000000

.PHONY: mxserver
mxserver:
	@$(MXSTLINK) --semihost-console-port 2333 --semihosting terminal -m 1 --swd -e -g -cp $(MXPROGDIR)

.PHONY: mxgdb
mxgdb:
	@$(MXGDB) -ex "target extended-remote localhost:61234" -ex "continue"