;------------------------------------------------------------------------------
;   14CUX Firmware Rebuild Project
;
;   File Date: 03-Jan-2014
;
;   Description:
;       This is the file that is passed to CRASM (the open source assembler).
;   The ordering of the files matches the original 14CUX code. This is to
;   enable a binary comparison with the original file in order to validate
;   our code rebuild.
;
;   29-Mar-2014     Relocated RPM table to end of data section file and
;                   deleted separate RPM table file.
;
;------------------------------------------------------------------------------

include registers.asm
include data.asm            ; RPM table is now included in data section file
include ramLocations.asm
include mpy16.asm
include reset.asm
include mainLoop.asm
include throttlePot.asm
include shutDown.asm
include mainRelay.asm
include coolant.asm
include airMass.asm
include airCond.asm
include neutralSwitch.asm
include o2Ref.asm
include roadSpeed.asm
include fuelTemp.asm
include airCond2.asm
include diagPlug.asm
include heatedScreen.asm
include mafTrim.asm
include tuneResistor.asm
include adcVectors.asm
include idleControl.asm
include purgeInt.asm
include ignitionInt.asm
include miscRoutines.asm
include purgeValve.asm
include misc1.asm
include coldStart.asm
include misc2.asm
include i2c.asm
include faults.asm
include purgeValve2.asm
include misc3.asm
include stepperMtr2.asm
IF BUILD_R3365
include defender.asm
ENDC
include serialPort.asm
IF SIMULATION_MODE
  include simulator.asm
ENDC
include vectors.asm
