;------------------------------------------------------------------------------
;   14CUX Firmware Rebuild Project
;
;   File Date: 14-Nov-2013
;
;   Description:    RAM Variables
;
;   There are two areas of RAM.
;
;   MPU: $0040 to $00FF  (192 bytes)
;   PAL: $2000 to $20FF  (128 bytes)
;
;   Of the MPU's 192 bytes of RAM, the first 32 bytes are battery-backed or
;   preserved using a small amount of battery current. Of these 32 bytes, only
;   the first 20 bytes are actually used in this way, the remainder is treated
;   like normal RAM and cleared to zero on startup.
;
;   It should be noted that the MPU internal memory is actually faster than
;   the external PAL memory. This is because the internal memory can be
;   accessed using direct addressing instead of extended addressing. See the
;   Motorola documentation for more info on this.
;
;   Explanation of codes:
;   (R) RoverGauge reads this location periodically
;   (W) RoverGauge writes this location for special functions
;
;   (F) Fast changing value (fuel map row & col)
;   (M) Medium changing value (road speed)
;   (S) Slow changing value (temperatures)
;   (N) Non-changing value (changes only with map change, fuel map scalar, etc.)
;
;   * = Moveable. All hard-codes references have been replaced with this variable
;   x = Same as above but do NOT move for other reasons (indexing, 2-byte R/W, etc)
;
;------------------------------------------------------------------------------

; The 19 bytes of battery saved RAM are mirrored at location X2060. It's not
; clear why this was done or if it's even necessary.
batteryBackedRAM    = $0040
externalRAMCopy     = $2060
sizeOfRAMBackup     = $0013


; *** Internal RAM (192 bytes) ***

secondaryLambdaR    = $0040 ; used during lambda calculations
longLambdaTrimR     = $0042 ; (R) 16-bit, long term trim
secondaryLambdaL    = $0044 ;
longLambdaTrimL     = $0046 ; (R) 16-bit, long term trim
hiFuelTemperature   = $0048 ;
faultBits_49        = $0049 ;x(R)
faultBits_4A        = $004A ;x(R)
faultBits_4B        = $004B ;x(R)
faultBits_4C        = $004C ;x(R)
faultBits_4D        = $004D ;x(R)
faultBits_4E        = $004E ;x(R)
stprMtrSavedValue   = $004F ;x    related to stepper motor and saved in battery backed memory
fuelMapNumberBackup = $0050 ;
throttlePotMinimum  = $0051 ; (R) 16-bit
throttlePotMinCopy  = $0053 ;
ramChecksum         = $0053 ; note that this location is used twice

mainVoltageAdj      = $0055 ;*(R) 16-bit
mafDirectLo         = $0057 ;*(R) 16-bit
mafDirectHi         = $0059 ;*    16-bit
fuelMapLoadIdx      = $005B ;*(R) row index, $70 max value
fuelMapSpeedIdx     = $005C ;*(R) col index
tpsDirectionAndRate = $005D ;*    16-bit, throttle pot direction & rate (1024 +/-)
throttlePot         = $005F ;*(R) 16-bit, TPS value, X005F is end of actual preserved area

throttlePot24bit    = $0061 ;*    24-bit, looks like TPS value scaled up by 256
tp24_Byte2          = $0062 ;*
o2ReferenceSense    = $0064 ;*    reference voltage for Lambda sensors (typically 23 or 24 decimal)
shortLambdaTrimR    = $0065 ; (R) 16-bit, short term trim ($8000 +/-)
shortLambdaTrimL    = $0067 ; (R) 16-bit, short term trim ($8000 +/-)
tmpFaultCodeStorage = $0067 ;     dual use byte, used for fault code storage only during startup
shortTrimAddValue   = $0069 ;     this value calculated from airflow and table at XC1CA
coolantTempCount    = $006A ;*(R) engine coolant temperature (ECT) count Value
coolantTempAdjust   = $006B ;*    ECT based fueling adjustment (value decreases during warmup)
tpMinCounter        = $006C ;*    this counter is used to slow down the TPmin adjustment
iacPosition         = $006D ;*(R) stepper motor position (0 = fully open, 180 = fully closed)
iacvEctValue        = $006E ;*    value is function of ECT (approx 100 to 160 during warmup)
iacvObsolete        = $006F ;*    value added to X006E but stays zero, can delete
unused0             = $0070 ;*    (unused)
iacvValue0          = $0071 ;*    used as stepper motor control value
iacvValue1          = $0072 ;*    used as stepper motor control value
iacvValue2          = $0073 ;*    used as stepper motor control value
iacvDriveValue      = $0074 ;*    stepper motor drive value (1 of 4 possible values)
iacMotorStepCount   = $0075 ;*(W) write only, absolute value of stepper motor correction steps
adcMuxTablePtr      = $0076 ;*    16-bit, index value for ADC table
adcMuxTableStart    = $0078 ;*    16-bit, pointer to current ADC control table
ignPeriod           = $007A ;*(R) 16-bit, ignition period, 2uSec increments, instantaneous
ignPeriodFiltered   = $007C ;*    16-bit, ignition period, 2uSec increments, filtered
engineRPM           = $007E ;*    16-bit, engine RPM, clipped at 1950
uncompFuelInjValue  = $0080 ;*    16-bit, in process, both banks
compedFuelInjValue  = $0082 ;*    16-bit, final injector value, exc. for Lambda trim
timer1value         = $0084 ;*    used for 1 Hz countdown timer 1
bits_0085           = $0085 ;     used as bits
bits_0086           = $0086 ;     used as bits
bits_0087           = $0087 ;     used as bits
bits_0088           = $0088 ;     used as bits
bits_0089           = $0089 ;*    used as bits
bits_008A           = $008A ;     used as bits
bits_008B           = $008B ;     used as bits
bits_008C           = $008C ;*    used as bits
bits_008D           = $008D ;*    used as bits
iciValueEven_8E     = $008E ;     used in ICI (indexed, do not move)
iciValueOdd_8F      = $008F ;     used in ICI (indexed, do not move)
iciValue90          = $0090 ;     used in ICI (indexed, do not move)
iciValue91          = $0091 ;     used in ICI (indexed, do not move)
iciValue92          = $0092 ;     used in ICI (indexed, do not move)
iciValue93          = $0093 ;     used in ICI (indexed, do not move)
iciValue94          = $0094 ;     used in ICI (bank related)
iciValue95          = $0095 ;     used in ICI (bank related)
purgeValveTimer     = $0096 ;*(R) 16-bit, purge value related
purgeValveTimer2    = $0098 ;*    16-bit, purge valve related
purgeValveValue     = $009A ;*    purge valve related
crankingFuelValue   = $009B ;x    value from 2nd row of 3 x 12 table, value is static
startupFuelTime     = $009C ;x    value from 3rd row of 3 x 12 table, decrements at 1 Hz rate
doubleInjecterRate  = $009D ;*    16-bit, normally 192, number of sparks for double fuel rate (todo: reduce to 1-byte)
hotFuelAdjustmment  = $009F ;*    16-bit, probably the fuel adjustment for startup w/hot underhood temp
fuelTempCounter     = $00A1 ;*    a counter used in the fuel temperature service routine
unused1             = $00A2 ;*    (unused)
unused2             = $00A3 ;*    (unused)
savedThrottlePot    = $00A4 ;*    16-bit, saved TPS value (only when closing) in TPS service routine
injectorPulseCntr   = $00A6 ;*    counter for injector micropulses during very cold startup
startupCodeDelay    = $00A7 ;*    counter for small startup code execution delay
bits_00A8           = $00A8 ;*    bits 7 and 0 only used in one routine
bankValue1          = $00A9 ;     16-bit, used as bank related value
bankValue2          = $00AB ;     16-bit, used as bank related value
iacvAdjustSteps     = $00AD ;*    rate of adjustment steps for IACV motor
iacvWorkingValue    = $00AE ;*    the working or in-process value for the stepper motor adjustment
fuelPumpTimer       = $00AF ;*(W) write only, init to 255, decr in main, renewed in ICI, zero shuts off pump
ectCounter          = $00B0 ;*    used as a counter in the ECT service routine
inertiaCounter      = $00B1 ;*    used as counter in inertia switch service routine
timerOverflow1      = $00B2 ;*    timer overflow counter
idleSpeedDelta      = $00B3 ;*    difference between target idle and actual RPM
idleSpeedCounter    = $00B4 ;*    counter used for idle control
idleControlValue    = $00B5 ;*    16-bits, a signed value used for idle control
unused3             = $00B7 ;*    (unused)
acDownCounter       = $00B8 ;*    a counter used for A/C compressor control
adcReadingUnused    = $00B9 ;*    16-bit, ADC reading is stored here but not used
rsFaultSlowdown     = $00BB ;*    16-bit, a slowdown counter used for VSS fault
workingBankValue    = $00BD ;     the working (in process) value for X008E or X008F
bankRelatedValue1   = $00BE ;     bank value
bankRelatedValue2   = $00BF ;     bank value
idleRelatedValue    = $00C0 ;*    an idle related value
tpsClosedLoopCntr   = $00C1 ;*    increments to 19, can be cleared or reset to $FF
tpsTimer            = $00C2 ;*    16-bit, a timer used to measured throttle rate
sparkPeriodTimer    = $00C4 ;*    16-bit, timer value saved near start of ICI to measure spark period
stepperMotorTimer   = $00C6 ;*    16-bit, timer value used to pace stepper motor control signals
generalPurpose0     = $00C8 ;     16-bit
generalPurpose1     = $00CA ;     16-bit
generalPurpose2     = $00CC ;     16-bit
generalPurpose3     = $00CE ;     16-bit
counter16bit        = $00D0 ;     16-bit, used as two 8-bit values in older (TVR) code
bits_00D2           = $00D2 ;
bits_00D3           = $00D3 ;
bankCounterLeft     = $00D4 ;
bankCounterRight    = $00D5 ;
dualNibbleCounter   = $00D6 ;
unused4             = $00D7 ;
unused5             = $00D8 ;
savedTpsValue       = $00D9 ;*    16-bit, saved TPS value from last call
purgeValveCounter   = $00DB ;*
bits_00DC           = $00DC ;
bits_00DD           = $00DD ;
unused6             = $00DE ;
groupFaultCounter   = $00DF ;*    counter used in group code area
misfireCounterEven  = $00E0 ;*
misfireCounterOdd   = $00E1 ;*
bits_00E2           = $00E2 ;
throttlePotTemp     = $00E3 ;*    16-bit, temporary storage of TPS value
sciIndex1           = $00E5 ;
sciIndex2           = $00E6 ;
sciCounter          = $00E7 ;
sciRcvChar          = $00E8 ;
sciXmtPtr           = $00E9 ;     16-bit
sciIndex3           = $00EB ;     16-bit
sciIndex4           = $00ED ;     16-bit
                            ;     (stack area)
topOfStack          = $00FF ;     top of MPU stack (range $00FF to $00EF, 17 bytes)


; *** External RAM (128 bytes) ***

neutralSwitchVal    = $2000 ;*(R) 0= Park, 255= Drive, 127= Manual
timerOverflow2      = $2001 ;*
vssStateCounter     = $2002 ;*
roadSpeed           = $2003 ;*(R) road speed in kilometers per hour
bits_2004           = $2004 ;*
unused7             = $2005 ;*
fuelTempCount       = $2006 ;*(R) fuel temperature sensor (FTS) count value
unused8             = $2007 ;*
                            ; the following 9 values are index addressed
fuelMapScaler       = $2008 ;x    16-bits
fuelMapRowScaler    = $200A ;x
rpmLimitMargin      = $200B ;x
rpmLimit            = $200C ;x(R) 16-bit (rpmLimitRAM)
rpmLimitRAM         = $200C ;x    (todo)
ectThreshold1       = $200E ;x
ectThreshold2       = $200F ;x
mysteryValue3       = $2010 ;x    (todo)
throttlePotScaler   = $2011 ;x

lambdaReading       = $2012 ;*    the current Lambda ADC reading (either bank)
bankDownCounterR    = $2013 ;     16-bit
bankDownCounterL    = $2015 ;     16-bit
bankCounterR        = $2017 ;
bankCounterL        = $2018 ;
bankCounterR1       = $2019 ;
bankCounterL1       = $201A ;
lambdaBiasR         = $201B ;
lambdaBiasL         = $201C ;
closedLoopDelay     = $201D ;*    init to $10, decremented at 1Hz by Timer 2
timer2Value         = $201E ;*    used by Timer 2, similar to X0084
bits_201F           = $201F ;*
startupTimerEven    = $2020 ;*    right bank
startupTimerOdd     = $2021 ;*    left bank
purgeValveVar1      = $2022 ;*    16-bit
purgeValveVar2      = $2024 ;*    16-bit
fuelMapPtr          = $2026 ;*    16-bit (for map 5, this value would be $C6AF)
mysteryDownCounter  = $2028 ;*    16-bit (todo)
obddDelayCounter    = $202A ;*    used by OBDD service routine
speedLimitIndicator = $202B ;*    set to $AA at 122 MPH, back to $00 at 119 MPH
fuelMapNumber       = $202C ;*(R) this will be 0 through 5
savedEngineRPM      = $202D ;*    16-bit, used by purge valve timer
tpsFaultDelayCount  = $202F ;*    throttle pot fault delay, newer code only, not TVR
faultSlowDownCount  = $2030 ;*    16-bit, general fault slowdown counter
milTestDelay        = $2032 ;*    16-bit, time delay for MIL (EFI lamp)
dtc12Delay          = $2034 ;*    delay counter for MAF fault (code 12)
codeErrorWord       = $2035 ;*    16-bit, value is used once but never initialized or changed (to be deleted)
mpuReInitCounter    = $2037 ;*    0 thru 20 counter used to re-init MPU register
bits_2038           = $2038 ;*

IF BUILD_R3383
startupDownCount    = $2039 ;
ELSE
acStartupDelay      = $2039 ;*    counts down from 12 to 0 at 1 Hz after startup, delays A/C operation
startupDownCount1Hz = $2039 ;*    initialized to 12 and counts down to 0
ENDC

stepperMotorReSync  = $203A ;*    used for stepper motor direction change
bits_203B           = $203B ;*    (only 1 bit used, purgeValve and ignitionInt)
purgeValveFailDelay = $203C ;*    delay downcounter for purge valve fail (DTC 88), reset to $FF when open loop
tuneResistorDelay   = $203D ;*    delay counter for tune resistor (DTC 21)
unusedValue         = $203E ;*    this byte is init to $40 but never used (to be deleted)
neutralSwitchDelay  = $203F ;*    16-bit, slowdown counter for neutral switch fault (DTC 69)
romChecksum         = $2041 ;*    this value should be $01
throttlePotCounter  = $2042 ;*    16-bit, init to 60,000 and decremented in TPS routine, may be unnecessary
unused9             = $2044 ;*
unused10            = $2045 ;*    this byte is init to $01 but otherwise unused
unused11            = $2046 ;*
bits_2047           = $2047 ;*(R) this byte contains idle mode bit
iacvVariable        = $2048 ;*    value is 128+/- and used for IACV fault detection
faultCode26Counter  = $2049 ;*    16-bit, possibly for unused very lean mixture fault
rpmIndicatorDelay   = $204B ;*    16-bit, value counts down from 50, should be byte only
mafLinear           = $204D ;*(R) 16-bit, values range from about 600 to over 17,000
mafVariable         = $204F ;*    16-bit, this value related to mafLinear
targetIdleRPM       = $2051 ;*(R) 16-bit, older code does not have this
stepperMtrCounter   = $2053 ;*    16-bit, must keep this with low byte below
stprMtrCntrLowByte  = $2054 ;*    (used separately in stepperMtr2)
bankCounterEven     = $2055 ;*    16-bit
bankCounterOdd      = $2057 ;*    16-bit
bits_2059           = $2059 ;*
acCounter           = $205A ;*    counter used by A/C routine
bits_205B           = $205B ;*
iciStartupCounter   = $205C ;*    upcounter used at start of ICI
iciStartupValue     = $205D ;*    16-bit, timer value written once at start of ICI

IF BUILD_R3383
startupDownCount1Hz = $205F ;*
ELSE
unused12            = $205F
ENDC

; X2060 through X2072 are copies of battery backed data (X0040 through X0052)

romChecksumMirror   = $2069 ;     (todo: rename this)

unused13            = $2073 ;*
unused14            = $2074 ;*
unused15            = $2075 ;*
specialAdcControl   = $2076 ;*    delay counter for special high RPM, high TPS ADC table
tpFaultSlowdown     = $2077 ;*    fault delay counter used in TPS routien
unused16            = $2078 ;*
ectFaultCounter     = $2079 ;*    should stay zero if ECT sensor is OK
copyOfX00E0         = $207A ;*    value from X00E0 stored here but unused
copyOfX00E1         = $207B ;*    value from X00E1 stored here but unused
unused17            = $207C ;*
vssFaultCounter     = $207D ;*    increments when road speed is non-zero
zeroTo80Counter     = $207E ;*    counts zero to 80 for code path control, newer code only
unused18            = $207F ;*


