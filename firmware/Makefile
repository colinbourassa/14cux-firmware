ASM_MODULES = crasm_main.asm \
registers.asm \
rpmTable.asm \
mpy16.asm \
reset.asm \
mainLoop.asm \
throttlePot.asm \
shutDown.asm \
mainRelay.asm \
coolant.asm \
airMass.asm \
airCond.asm \
neutralSwitch.asm \
o2Ref.asm \
roadSpeed.asm \
fuelTemp.asm \
airCond2.asm \
diagPlug.asm \
heatedScreen.asm \
mafTrim.asm \
tuneResistor.asm \
adcVectors.asm \
idleControl.asm \
purgeInt.asm \
ignitionInt.asm \
miscRoutines.asm \
purgeValve.asm \
misc1.asm \
coldStart.asm \
misc2.asm \
i2c.asm \
faults.asm \
purgeValve2.asm \
misc3.asm \
stepperMtr2.asm \
serialPort.asm \
simulator.asm \
vectors.asm

FINALIZE = ../utils/finalize
FINALIZE_SRC = ../utils/finalize.c
SREC2BIN = ../utils/srec/srec2bin
SREC2BIN_SRC = ../utils/srec/srec2bin.c \
               ../utils/srec/common.c

SREC = 14cux.srec
IMAGE_UNFIXED = 14cux.bin.unfixed
IMAGE = 14cux.bin

DATA_MODULES := $(patsubst data_%.asm,%,$(wildcard data_*.asm))
define USAGE_MSG
Usage: make <config>
  where <config> is one of the following tunes:
  $(DATA_MODULES)
endef
export USAGE_MSG

all:
	@echo "$$USAGE_MSG"

R%: $(IMAGE)
	@echo " "

data.asm:
ifeq ($(filter $(MAKECMDGOALS),$(DATA_MODULES)),)
	@echo "Error, unknown tune: $(MAKECMDGOALS)"
	@exit 1
else
	ln -sf data_$(filter $(MAKECMDGOALS),$(DATA_MODULES)).asm $@
endif

$(IMAGE): cleandata $(IMAGE_UNFIXED) $(FINALIZE)
	$(FINALIZE) -d $(IMAGE_UNFIXED) $(IMAGE)

$(IMAGE_UNFIXED): $(SREC) $(SREC2BIN)
	$(SREC2BIN) -o 0xC000 $(SREC) $(IMAGE_UNFIXED)

$(SREC): data.asm $(ASM_MODULES)
	crasm -o $(SREC) -l crasm_main.asm

$(FINALIZE): $(FINALIZE_SRC)
	$(CC) -o $(FINALIZE) $(FINALIZE_SRC)

$(SREC2BIN): $(SREC2BIN_SRC)
	make -C ../utils/srec

cleandata:
	rm -f data.asm

clean:
	rm -f $(SREC) $(IMAGE) $(IMAGE_UNFIXED) $(FINALIZE) data.asm

