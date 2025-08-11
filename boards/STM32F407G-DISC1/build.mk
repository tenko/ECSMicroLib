# Board specific targets
.PHONY: sim
sim: build/test.rom
	$(QEMU) $(QEMUFLAGS) --image $<