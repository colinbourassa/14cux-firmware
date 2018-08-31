;------------------------------------------------------------------------------
;   14CUX Firmware Rebuild Project
;
;   File Date: 07-Jan-2014
;
;   Description: R3652 Data and build flags (NAS Cold weather upgrade)
;
;       This file includes the the 2K byte data section of the R3652 ROM which
;   is from $0000 through $3FFF (mapped to $C000 through $C7FF in board). The
;   file also contains build flags which control how the code is assembled and
;   or modified.
;
;
;   R3652 (Cold Weather Chip)
;
;   Tune R3652 was part of a late upgrade (under Operation Pride) for NAS 3.9
;   Land Rovers as a result of cold start complaints. The changes are based on
;   R3526 code and are relatively minor. The changes only affect starting and
;   cold warmup.
;
;------------------------------------------------------------------------------


cpu 6803                ; tell assembler to output 6803 code
output SCODE            ; output Motorola S code format (srec2bin will be used)

ZERO = 0                ; used for convenient code deletion

;----------------------------------------------------------
; These flags control how the code section is built
; This section should not be altered.
;----------------------------------------------------------
BUILD_R3365             = 0
BUILD_R3383             = 0
BUILD_R3652             = 1
BUILD_R3360_AND_LATER   = 1
BUILD_TVR_CODE          = 0
NEW_STYLE_AC_CODE       = 1
NEW_STYLE_FAULT_SCAN    = 1
NEW_STYLE_FAULT_DELAY   = 1
NEW_STYLE_MIL_CODE      = 1

;----------------------------------------------------------
; This section recreates the data at the end of the ROM
; (just before the vectors). The only thing here that
; affects the code is the checksum fixer.
;----------------------------------------------------------
CRC16                   = $9F52     ; addr FFE0/E1
TUNE_NUMBER             = $3652     ; addr FFE9/EA
CHECKSUM_FIXER          = $F6       ; addr FFEB
TUNE_IDENT              = $1A28     ; addr FFEC/ED

;----------------------------------------------------------
; These two flags control the bytes at addresses C7C1 and
; C7C2 (near the end of this file). It appears that the
; original developers meant for these two bytes to be
; options, but this has not been fully tested.
;----------------------------------------------------------
NAS_FUEL_MAP_5_LOCK     = 1
MIL_DELAY               = 1

;----------------------------------------------------------
; This section contains code development flags
;
; OBSOLETE_CODE
; This flag is used to include or exclude a number of code
; blocks that are obsolete or unneeded. Obsolete code should
; be included when attempting a byte for byte rebuild.
;
; USE_4004_BIT4_FOR_ICI
; This option toggles the signal from pin 34 on the Plessey
; MVA5033 (PAL) to allow time profiling of the spark interrupt.
; This pin is not otherwise used in the standard software.
;
; SIMULATION_MODE
; This is a bench test feature that requires a special
; hardware setup. This flag should normally be set to zero.
;
;----------------------------------------------------------
OBSOLETE_CODE           = 1
USE_4004_BIT4_FOR_ICI   = 0
SIMULATION_MODE         = 0

SIM_CONTROL_BYTE    EQU  $55


;----------------------------------------------------------
; These values can differ from one tune version to the
; next, so they are defined here.
;----------------------------------------------------------
initialRpmLimit   = $056C   ; used in reset.asm (5403 RPM)
initialRpmMargin  = $1B     ; used in reset.asm (LSB = 100 RPM)
ignPeriodEngStart = $4E     ; used in several files (MSB = 375 RPM)
startupDelayCount = $02     ; used in ignitionInt.asm (usually $04 but $02 for cold weather chip)
coldStartupFactor = $12     ; used in ignitionInt.asm (value is $0A for older code)
highRoadSpeed_ON  = $C4     ; 196 KPH (122 MPH)
highRoadSpeed_OFF = $FC     ; minus 4 (196 - 4 = 192 KPH)
highSpeedIndByte  = $AA     ; the high road speed indicator byte (normally $AA)

dtc17_tpsMinimum  = $0008   ; used in throttlePot.asm (78mV, this is 39mV for R3526 and R3652)
dtc18_tpsMaximum  = $0332   ; used in ignitionInt.asm (4 Volts, was 1.5 V in earlier code)
dtc68_minimumRPM  = $0D     ; used in roadSpeed.asm (MSB = 2250 RPM)
dtc69_rpmMinimum  = $10     ; used in ignitionInt.asm (MSB = 1831 RPM)


;----------------------------------------------------------
; Constant values used inline (i.e. not from the data section)
;----------------------------------------------------------
ignPeriodHiSpeed   = $07   ; 4185 RPM (to switch in hi-speed ADC mux table)
pwRpmComputeLimit  = $0E   ; 2092 RPM (beyond this, the actual RPM is not computed because it's math intensive)
compRpmMaxConst    = $079E ; 1950 RPM (used when the engine speed exceeds pwRpmComputeLimit)
throttlePotDefault = $0076 ; 576mV
mapMultiplierOffset  = $80
mapRpmLimitOffset    = $8C
mapAdcMuxTableOffset = $7A

;----------------------------------------------------------
; Start of Data
;----------------------------------------------------------
*               = $C000
romStart        = *
limpHomeMap     DB          $21,$21,$21,$21,$1F,$1D,$1A,$19,$19,$19,$19,$19,$18,$14,$14,$14
                DB          $3F,$3E,$3B,$3A,$39,$39,$39,$39,$3B,$3C,$3B,$39,$35,$30,$30,$30
                DB          $5D,$5C,$5B,$5B,$5E,$5E,$5E,$5E,$5E,$5F,$5D,$5C,$53,$4A,$4A,$4A
                DB          $8E,$8E,$8C,$8C,$88,$8C,$8C,$84,$84,$80,$81,$81,$75,$69,$69,$69
                DB          $B2,$AF,$B0,$B0,$B1,$AC,$A6,$A6,$A6,$A6,$A4,$A3,$93,$8A,$8A,$8A
                DB          $FF,$FF,$D1,$D1,$D1,$D4,$D7,$D8,$E1,$D7,$D2,$D2,$CD,$CD,$B9,$C3
                DB          $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA,$DC,$E6,$E6,$E6,$E4,$F0
                DB          $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$FA,$FA,$FA,$FD,$FD

                DW          $54DD               ; fuel map multiplier (21725 dec)

                DB          $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA ; ADC mux table

                DW          $1F40               ; Used for cond B in ICI (8000 dec)
                DW          $1F40               ; Used for cond A in ICI (8000 dec)
                DB          $40                 ; Used for cond A in ICI
                DB          $04                 ; Used in cond A and B in ICI
                DB          $00                 ; Used in ICI
                DB          $00                 ; Used in ICI
                DW          $F830               ; Used in ICI (-2000d)
                DW          $07D0               ; Used in ICI (+2000d)
                DW          $0002               ; Location X0094 is set to this value
                DB          $80                 ; Used in ICI and other places
                DB          $01,$08,$FC,$80     ; (unused?)
                DB          $51                 ; Used to init location X2010
                DB          $EA                 ; Used for comparison with throttle pot value
                DB          $08,$9D             ; Used for comparison with engine ignition period (3400 RPM)
                DB          $01                 ; Used as a multiplication factor
                DB          $1B,$58             ; (possibly unused values)
tpFastOpenThreshold  DB     $00,$18
                DB          $02                 ; Used in fuel temp thermistor routine
                DB          $32                 ; Used in fuel temp thermistor routine
                DB          $00,$02             ; Used in main loop
                DB          $07,$80             ; Used in fuel temp thermistor routine
hiFuelTempThreshold  DB     $65

LC0B5           DB          $00,$24,$38,$91,$AB,$C2,$D2,$EE ; Data table used in coolant temp routine
                DB          $26,$26,$2B,$2E,$2F,$30,$34,$34
                DB          $00,$10,$02,$02,$03,$10,$00,$00

                DB          $70                 ; Fault code & default coolant sensor value
rsFaultSlowdownThreshold DW $0800               ; Road Speed Sensor Fault registers after this many counts

                DB          $00,$12,$1B,$25,$47,$75,$94,$B0,$C8,$DA,$E2,$E4 ; Table referenced in coolant temp routine
                DB          $0B,$0A,$07,$0D,$1A,$2A,$3C,$46,$53,$59,$6D,$75 ; Offset = 12
                DB          $1C,$0D,$06,$0A,$14,$1E,$25,$2B,$2D,$31,$31,$31 ; Offset = 24

                DB          $96                 ; used in 1 Hz coundown routines
                DB          $0C                 ; maybe unused
                DB          $19                 ; used in ICI (TP multiplier)
                DB          $0A                 ; used in ICI (TP compare value)

                DB          $18,$31,$5A,$7A,$89,$99,$B3,$CC,$DD,$E2 ; Table used in ICI
                DB          $05,$06,$08,$0A,$10,$1C,$28,$34,$34,$34
                DB          $04,$06,$07,$05,$05,$00,$00,$00,$00,$00
                DB          $2D,$32,$3C,$50,$64,$FF,$FF,$FF,$FF,$FF
                DB          $1C,$18,$10,$0C,$0B,$14,$14,$14,$07,$05
                DB          $2D,$2D,$2D,$28,$24,$1E,$1E,$1E,$1E,$1E


                DB          $64                 ; Used during initialization
                DB          $04,$00             ; Used in ICI
                DB          $10                 ; ICI, compared with upper byte of filtered ign. period
                DB          $14                 ; Used in ICI
                DB          $17                 ; Used in ICI
                DB          $25                 ; Used during initialization
                DB          $14                 ; Used in throttle pot and ICI
                DB          $7A                 ; -> X200E (default fuel map value)
                DB          $C8                 ; 200 dec, multiplier for purge valve timer
                DB          $64                 ; possibly unused
                DB          $3C                 ; 60 dec, multiplier for purge valve timer
                DB          $14,$82             ; Related to purge valve timer
                DB          $06,$B8             ; Used in main loop S/R (1720 RPM, used in purge valve routine)
                DB          $0A                 ; Used in ICI
                DB          $2E,$E0             ; Used in ICI and main loop S/R
                DB          $00,$52             ; Used in CT S/R
                DB          $00,$00             ; Used in ICI
                DB          $00,$64             ; Used in ICI
                DB          $00,$8C             ; Used in ICI
                DB          $05                 ; Used in main loop S/R
                DB          $2D                 ; Used in main loop S/R
                DB          $32,$00             ; Used in main loop S/R
                DB          $1C                 ; Used in main loop S/R
                DB          $28                 ; Used in Trottle Pot routine
                DB          $AF                 ; Used in main loop S/R
                DB          $28                 ; Used in main loop S/R
                DB          $1A                 ; Used in main loop S/R
                DB          $05                 ; Used by main loop S/R
idleAdjForNeutral  DB       $00,$64             ; Value is 100 (idle setting increase when in neutral)
idleAdjForAC    DB          $00,$32             ; Value is 50 (idle setting increase for A/C)
                DB          $20                 ; Used by main loop S/R
                DB          $0A                 ; Used in ICI
                DB          $A0,$00             ; Used in ICI
                DB          $0A                 ; Used in Throttle Pot and main loop S/R
                DB          $05,$DC             ; Used in Throttle Pot routine
                DB          $06                 ; Used by main loop S/R
                DB          $14                 ; Used by main loop S/R
                DB          $0C                 ; Used by main loop S/R
                DW          $04B0               ; eng RPM reference (1200) used in TP routine
                DB          $14,$0E,$AD,$14,$18,$18 ; Used by main loop S/R
                DB          $53                 ; Used by main loop S/R (may be upper byte of rev limit, 53FF/4 = 5375 RPM)
                DB          $27                 ; Used in ICI
                DB          $00,$3C             ; Used in ICI (this limits the value in B5/B6 to 60 minus 1)
                DB          $00,$0E             ; Used by main loop S/R
                DB          $01                 ; Used by main loop S/R
baseIdleSetting DW          $0258               ; Base idle setting (600 RPM)
                DB          $50,$00,$D1         ; Used in ICI

                DB          $00,$0B,$1C,$23,$48,$51,$88,$E4,$F2 ; Coolant temp table -- 9 values
                DB          $78,$78,$A0,$A0,$88,$85,$72,$50,$1E ; Offset  9
                DB          $00,$97,$00,$2A,$15,$16,$18,$E5,$08 ; Offset 18

LC196           DB          $59,$5C,$5E,$60,$62,$65,$67,$69 ; (C196 is referenced in ICI)
                DB          $F4,$E3,$D2,$C1,$AF,$9E,$8E,$7B
                DB          $00,$00,$00,$00,$00,$00,$00,$00

                DB          $01                 ; Used in Input Capture Interrupt
                DW          $043D               ; subtracted from sum of air flow values in ICI
                DB          $15                 ; compared with counter value in 0094 or 0095 in ICI
                DW          $0100               ; subtracted from air flow sum in ICI

engDataA        DW          $0065               ; Values for X9x00 (Type 5) Use this for R3526
engDataB        DW          $005B
engDataC        DW          $005C

engInitDataA    DB          $00                 ; Init value for X9000
engInitDataB    DB          $00                 ; Init value for X9100
engInitDataC    DB          $00                 ; Init value for X9200

                DW          $000A               ; During init, added to stored TPmin after use
                DB          $00                 ; unused
                DB          $08                 ; used in TP (added to TPMin)
                DB          $00                 ; unused
                DB          $10                 ; used in TP (subtracted from TPMin)
                DW          $225D               ; Used in ICI
                DW          $09C0               ; Used in ICI
                DW          $001E               ; Used in ICI
                DB          $B2                 ; Init value for X200A

; 3 x 8 table for air flow in ICI
                DB          $00,$60,$6C,$7C,$84,$8E,$9A,$A8 ; row 0 is compared & subtracted from air flow sum
                DB          $36,$36,$36,$36,$3C,$48,$63,$94 ; row 1 is added to final value
                DB          $00,$00,$00,$30,$4C,$90,$E0,$00 ; row 2 is multiplied by remainder

                DB          $FF
                DW          $FFEC               ; This inits the value in idleControlValue to minus 20
                DB          $2C                 ; This inits the value in acDownCounter to 44 dec
                DB          $2C                 ; This inits the value in acDownCounter to 44 dec (alt. code path)
                DW          $0200               ; value used in ICI only
idleAdjForHeatedScreen  DW  $0000               ; Value zero (idle setting adjustment for heated screen)
                DB          $08
                DB          $01                 ; Used in ICI
                DB          $02                 ; Used in ICI
                DB          $0C                 ; Misfire fault threshold?
hotCoolantThreshold   DB    $14                 ; If either the coolant or fuel temps exceeds their threshold, the
hotFuelThreshold      DB    $34                 ;    condenser fan timer will be set to run the fans at shutdown
                DB          $56                 ; Compared with left short term trim in ICI
                DB          $30                 ; Compared with left and right short term trim in ICI (fault code related?)
                DB          $E0                 ; Compared with left and right short term trim in ICI (fault code related?)
                DW          $0023               ; Subtracted from throttle pot value in ICI
                DW          $0000               ; Subtracted from throttle pot value in ICI
                DW          $CEC3               ; CE is compared with coolant temp in ICI (XC1F9 is unused)
                DW          $0202               ; C1FA is used, C1FB is unused
                DW          $00C8               ; Inits O2 sample counters?? value is 200 dec
                DB          $10                 ; O2 sensors are ignored for this many seconds after startup
                DB          $03                 ; startup timer value (conditionally loaded into 2020 and 2021)
                DW          $0004               ; Related to purge valve timer??
                DW          $0C00               ; Value is stored in X2024/25
wideThrottleThreshold DW    $02CD

accelPumpTable  DB          $00,$14,$28,$32,$3F,$52,$66,$7E,$8F,$AD,$C3,$D7 ; XC206: Used by TP routine (coolant temp, 12 values)
                DB          $0C,$0C,$0E,$12,$13,$19,$1C,$28,$28,$1E,$14,$00 ; XC212: Offset of 12 from cooland temp table

                DB          $07,$25,$22

                DB          $47                 ; for fuel map 0, 4 and 5
                DB          $1E
                DW          $1000
                DB          $24
                DW          $0E00

                DB          $47                 ; for fuel map 1, 2 and 3
                DB          $1E
                DW          $1000
                DB          $24
                DW          $0E00

LC22F           DB          $01
                DB          $02

hiRPMAdcMux     DB          $87,$02,$87,$86,$87,$02,$87
                DB          $87,$87,$87,$87,$87,$87,$F7

;------------------------------------------------------------------------------
; Note: Variables between here and fuel map 1 are not in R2419
;------------------------------------------------------------------------------

                DB          $1E
                DW          $0032
                DB          $6C                 ; Used to init 'stprMtrSavedValue'
                DB          $20
                DW          $4721
                DB          $1C
                DB          $22
                DB          $22
                DW          $0096
                DW          $0096
                DB          $3A
                DB          $C6
                DW          $3E80               ; used by ignition sense subroutine
                DB          $71                 ; used by ignition sense subroutine
                DB          $4E                 ; used by ignition sense subroutine
                DW          $118B               ; ign pulse period (1670 RPM) used by stepper motor routine
                DW          $01F9               ; used by ignition sense subroutine
                DB          $0F
                DB          $0A                 ; used by road speed routine
                DB          $50
                DB          $02                 ; used by CalcIacvVariable
                DB          $02                 ; used by CalcIacvVariable
                DB          $08
                DW          $0258               ; used by input capture interrupt
                DW          $03F6               ; used by input capture interrupt
                DB          $53
                DW          $7FB9               ; used by CalcIacvVariable
                DW          $80B4               ; used by CalcIacvVariable
                DB          $28                 ; used by ignition sense subroutine

;------------------------------------------------------------------------------
fuelMap1        DB          $23,$23,$23,$21,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F,$1E,$1E,$1E,$1F
                DB          $3E,$3E,$3C,$3C,$3A,$38,$36,$36,$36,$36,$36,$37,$36,$36,$36,$36
                DB          $5C,$5B,$58,$57,$57,$55,$55,$54,$53,$52,$50,$4E,$4E,$4D,$4D,$4E
                DB          $84,$84,$82,$7D,$7A,$76,$76,$75,$6E,$6E,$6D,$6C,$6B,$69,$67,$6A
                DB          $A6,$A6,$A6,$A6,$A6,$A4,$9C,$9B,$9A,$8F,$8B,$87,$86,$84,$82,$84
                DB          $DD,$DD,$DD,$D2,$CD,$C8,$C8,$CD,$CD,$C1,$B4,$B2,$B0,$AF,$AD,$AF
                DB          $EC,$EC,$EC,$EC,$EC,$EF,$E8,$FC,$F5,$EE,$D3,$CD,$CD,$CB,$CB,$D0
                DB          $EC,$EC,$EC,$EC,$EC,$EF,$EC,$FC,$FF,$EE,$EC,$F0,$F0,$EE,$EE,$EE

                DW          $5DBE               ; fuel map multiplier

                DB          $18,$21,$31,$5A,$7C,$99,$B3,$CC,$DD,$EA
                DB          $04,$08,$0A,$0D,$12,$1C,$2B,$30,$33,$33
                DB          $04,$03,$04,$04,$04,$00,$00,$00,$00,$00
                DB          $28,$32,$3C,$64,$96,$FF,$FF,$FF,$FF,$FF
                DB          $14,$28,$28,$1E,$19,$1E,$1E,$1E,$19,$19
                DB          $0F,$14,$14,$14,$14,$1E,$1E,$1E,$1E,$1E

                DB          $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8
                DB          $0C,$0A,$08,$0D,$19,$2B,$3B,$46,$4E,$59,$69,$75
                DB          $1E,$10,$07,$0F,$13,$17,$1E,$26,$2C,$31,$39,$44

                DB          $00,$29,$50,$91,$AB,$C2,$E0,$EE
                DB          $26,$26,$2A,$2E,$34,$38,$43,$4E
                DB          $00,$06,$03,$0E,$0B,$17,$32,$14

                DB          $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA ; ADC mux table
                DB          $B2,$1B,$03,$6C,$24,$23,$68
                DB          $3C

;------------------------------------------------------------------------------
fuelMap2        DB          $23,$23,$23,$21,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F,$1E,$1E,$1E,$1F
                DB          $3E,$3E,$3C,$3C,$3A,$38,$36,$36,$36,$36,$36,$37,$36,$36,$36,$36
                DB          $5C,$5B,$58,$57,$57,$55,$55,$54,$53,$52,$50,$4E,$4E,$4D,$4D,$4E
                DB          $84,$84,$82,$7D,$7A,$76,$76,$75,$6E,$6E,$6D,$6C,$6B,$69,$67,$6A
                DB          $A6,$A6,$A6,$A6,$A6,$A4,$9C,$9B,$9A,$8F,$8B,$87,$86,$84,$82,$84
                DB          $DD,$DD,$DD,$D2,$CD,$C8,$C8,$CD,$CD,$C1,$B4,$B2,$B0,$AF,$AD,$AF
                DB          $EC,$EC,$EC,$EC,$EC,$EF,$E8,$FC,$F5,$EE,$D3,$CD,$CD,$CB,$CB,$D0
                DB          $EC,$EC,$EC,$EC,$EC,$EF,$EC,$FC,$FF,$EE,$EC,$F0,$F0,$EE,$EE,$EE

                DW          $5DBE               ; fuel map multiplier

LC3FB           DB          $18,$21,$31,$5A,$7C,$99,$B3,$CC,$DD,$EA
                DB          $04,$08,$0A,$0D,$12,$1C,$2B,$30,$33,$33
LC40F           DB          $04,$03,$04,$04,$04,$00,$00,$00,$00,$00
                DB          $28,$32,$3C,$64,$96,$FF,$FF,$FF,$FF,$FF
LC423           DB          $14,$28,$28,$1E,$19,$1E,$1E,$1E,$19,$19
                DB          $0F,$14,$14,$14,$14,$1E,$1E,$1E,$1E,$1E

LC437           DB          $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8
LC443           DB          $0C,$0A,$08,$0D,$19,$2B,$3B,$46,$4E,$59,$69,$75
                DB          $1E,$10,$07,$0F,$13,$17,$1E,$26,$2C,$31,$39,$44

LC45B           DB          $00,$29,$50,$91,$AB,$C2,$E0,$EE
LC463           DB          $26,$26,$2A,$2E,$34,$38,$43,$4E
LC46B           DB          $00,$06,$03,$0E,$0B,$17,$32,$14

LC473           DB          $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA ; ADC mux table

LC483           DB          $B2,$1B,$03,$6C,$24,$23,$68
LC48A           DB          $3C

;------------------------------------------------------------------------------
fuelMap3        DB          $23,$23,$23,$21,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F,$1E,$1E,$1E,$1F
                DB          $3E,$3E,$3C,$3C,$3A,$38,$36,$36,$36,$36,$36,$37,$36,$36,$36,$36
                DB          $5C,$5B,$58,$57,$57,$55,$55,$54,$53,$52,$50,$4E,$4E,$4D,$4D,$4E
                DB          $84,$84,$82,$7D,$7A,$76,$76,$75,$6E,$6E,$6D,$6C,$6B,$69,$67,$6A
                DB          $A6,$A6,$A6,$A6,$A6,$A4,$9C,$9B,$9A,$8F,$8B,$87,$86,$84,$82,$84
                DB          $DD,$DD,$DD,$D2,$CD,$C8,$C8,$CD,$CD,$C1,$B4,$B2,$B0,$AF,$AD,$AF
                DB          $EC,$EC,$EC,$EC,$EC,$EF,$E8,$FC,$F5,$EE,$D3,$CD,$CD,$CB,$CB,$D0
                DB          $EC,$EC,$EC,$EC,$EC,$EF,$EC,$FC,$FF,$EE,$EC,$F0,$F0,$EE,$EE,$EE

                DW          $5DBE               ; fuel map multiplier

LC50D           DB          $18,$21,$31,$5A,$7C,$99,$B3,$CC,$DD,$EA
                DB          $04,$08,$0A,$0D,$12,$1C,$2B,$30,$33,$33
                DB          $04,$03,$04,$04,$04,$00,$00,$00,$00,$00
LC52B           DB          $28,$32,$3C,$64,$96,$FF,$FF,$FF,$FF,$FF
LC535           DB          $14,$28,$28,$1E,$19,$1E,$1E,$1E,$19,$19
                DB          $0F,$14,$14,$14,$14,$1E,$1E,$1E,$1E,$1E

                DB          $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8
LC555           DB          $0C,$0A,$08,$0D,$19,$2B,$3B,$46,$4E,$59,$69,$75
                DB          $1E,$10,$07,$0F,$13,$17,$1E,$26,$2C,$31,$39,$44

LC56C           DB          $00,$29,$50,$91,$AB,$C2,$E0,$EE
LC575           DB          $26,$26,$2A,$2E,$34,$38,$43,$4E
LC57D           DB          $00,$06,$03,$0E,$0B,$17,$32,$14

LC585           DB          $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$09,$8E,$FA ; ADC mux table

LC595           DB          $B2,$1B,$03,$6C,$24,$23,$68
LC59C           DB          $3C

;------------------------------------------------------------------------------
fuelMap4        DB          $21,$21,$21,$22,$21,$20,$1F,$1F,$1E,$1E,$1D,$1C,$1A,$19,$19,$19
                DB          $41,$41,$40,$3F,$3E,$3E,$3D,$3C,$3B,$3C,$3E,$3F,$3C,$34,$34,$34
                DB          $60,$5E,$5D,$5D,$5B,$5A,$5A,$5D,$5D,$5E,$61,$62,$57,$4E,$4E,$4E
                DB          $84,$84,$82,$82,$83,$83,$80,$7C,$7D,$83,$84,$85,$78,$6C,$6C,$6C
                DB          $B4,$AF,$A5,$A5,$A0,$A0,$A0,$A0,$A1,$A3,$A6,$A7,$96,$8C,$8C,$8C
                DB          $FF,$FF,$D2,$D2,$D2,$CD,$CD,$CD,$CB,$CB,$CE,$CE,$B2,$B2,$B4,$C3
                DB          $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F5,$EF,$D6,$D7,$D7,$DE,$DE
                DB          $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA,$FA,$FF,$FF,$FD,$FD

LC61D           DW          $56CC               ; fuel map factor

LC61F           DB          $18,$21,$31,$5A,$7C,$99,$B3,$CC,$DD,$EA
                DB          $04,$08,$0A,$0C,$0E,$1C,$23,$28,$30,$30
                DB          $02,$04,$06,$08,$08,$00,$00,$00,$00,$00
                DB          $3C,$3C,$46,$50,$64,$FF,$FF,$FF,$FF,$FF
                DB          $50,$46,$32,$19,$0C,$14,$14,$19,$19,$19
                DB          $14,$14,$12,$12,$12,$1E,$1E,$1E,$1E,$1E

                DB          $00,$12,$1B,$25,$47,$75,$99,$B0,$C8,$DA,$E4,$E8
LC667           DB          $0C,$0A,$07,$0D,$18,$27,$3B,$46,$4E,$59,$6D,$75
                DB          $1E,$0B,$04,$0F,$10,$11,$1E,$26,$2C,$31,$39,$44

                DB          $00,$29,$50,$91,$AB,$C2,$E0,$EE
LC687           DB          $26,$26,$2A,$2C,$34,$38,$43,$4E
LC68F           DB          $00,$06,$01,$13,$0B,$17,$32,$14

LC697           DB          $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA ; ADC mux table
LC6A7           DB          $B9,$1B,$05,$6C,$6E,$2C,$5C
LC6AE           DB          $64

;------------------------------------------------------------------------------
fuelMap5        DB          $21,$21,$21,$21,$1F,$1D,$1A,$19,$19,$19,$19,$19,$18,$14,$14,$14
                DB          $3F,$3E,$3B,$3A,$39,$39,$39,$39,$3B,$3C,$3B,$39,$35,$30,$30,$30
                DB          $5D,$5C,$5B,$5B,$5C,$5E,$5E,$5E,$5E,$5F,$5D,$5C,$53,$4A,$4A,$4A
                DB          $8E,$8E,$8C,$8C,$88,$8C,$8C,$84,$84,$80,$81,$81,$75,$69,$69,$69
                DB          $B2,$AF,$B0,$B0,$B1,$AC,$A6,$A6,$A6,$A6,$A4,$A3,$93,$8A,$8A,$8A
                DB          $FF,$FF,$D1,$D1,$D1,$D4,$D7,$D8,$E1,$D7,$D2,$D2,$CD,$CD,$B9,$C3
                DB          $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA,$DC,$E6,$E6,$E6,$E4,$F0
                DB          $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$FA,$FA,$FA,$FD,$FD

                DW          $54DD               ; fuel map multiplier

LC731           DB          $18,$31,$5A,$7A,$89,$99,$B3,$CC,$DD,$E2 ; (C731) used by Input Capture Interrupt (10 coolant temp values)
LC73B           DB          $05,$06,$08,$0A,$10,$1C,$28,$34,$34,$34 ; index offsets are 0A, 14, 1E and ($0A + $28)
LC745           DB          $04,$06,$07,$05,$05,$00,$00,$00,$00,$00
LC74F           DB          $2D,$32,$3C,$50,$64,$FF,$FF,$FF,$FF,$FF
LC759           DB          $1C,$18,$10,$0C,$0B,$14,$14,$14,$07,$05
LC763           DB          $2D,$2D,$2D,$28,$24,$1E,$1E,$1E,$1E,$1E

LC76D           DB          $00,$12,$1B,$25,$47,$75,$94,$B0,$C8,$DA,$E2,$E4 ; (C76D) used by coolant temp routine
LC779           DB          $0B,$0A,$07,$0D,$1A,$2A,$3C,$46,$53,$59,$6D,$75 ; in X009B (cranking fueling value above zero F)
LC785           DB          $1C,$0D,$06,$0A,$14,$1E,$25,$2B,$2D,$31,$31,$31 ; in X009C (time fueling component, 1 Hz countdown)

LC791           DB          $00,$24,$38,$91,$AB,$C2,$D2,$EE ; (C791) used by CT routine (8 values)
LC799           DB          $26,$26,$2B,$2E,$2F,$30,$34,$34 ; offset =  8
LC7A1           DB          $00,$10,$02,$02,$03,$10,$00,$00 ; offset = 16

LC7A9           DB          $87,$86,$02,$03,$84,$02,$8D,$88,$02,$8B,$80,$85,$81,$8E,$FA,$FA ; ADC mux values
                                                ; (see notes below)

LC7B9           DB          $B2                 ; -> X200A (used in ICI to calc FM load value row index)
                DB          $1B                 ; RPM safety delta
                DW          $056C               ; RPM limit
LC7BD           DB          $7A                 ; -> X200E (fuel map value)
LC7BE           DB          $2C                 ; -> X200F (a coolant temp threshold)
LC7BF           DB          $51                 ; -> X2010 (todo)
LC7C0           DB          $64                 ; -> X2011 (multiplied by abs of throttle delta)
;------------------------------------------------------------------------------

; This byte must be $00 for the tune resistor fuel map selection to work.
; In NAS Land Rovers, it's set to $FF to lock the ECU into fuel map 5 only.
IF NAS_FUEL_MAP_5_LOCK
  fuelMapLock   DB          $FF
ELSE
  fuelMapLock   DB          $00
ENDC

IF MIL_DELAY
                DB          $FF
ELSE
                DB          $00
ENDC

voltageMultA    DB          $64
voltageMultB    DB          $BD
voltageOffset   DW          $6408
LC7C7           DB          $27
LC7C8           DW          $EA60               ; TP: 'throttlePotCounter' (60000 init value used by TP routine)
LC7CA           DW          $10D6               ; TP: value subtracted in TP Routine
LC7CC           DW          $0001               ; TP: value subtracted in TP Routine
LC7CE           DB          $0A                 ; TP: compare value in TP Routine
LC7CF           DB          $01                 ; (unused?)
LC7D0           DB          $0A                 ; $0A is compare value in Air Cond Load routine

LC7D1           DW          $0FA0               ; ICI: 4000 dec used for lean condition check (alt value to 8000 in C092) added to X008E
LC7D3           DW          $0FA0               ; ICI: 4000 dec used for rich condition check (alt value to 8000 in C094) added to X0090

LC7D5           DB          $20                 ; ICI: used in rich condition code
LC7D6           DB          $1B                 ; ICI: used in lean condition code
LC7D7           DB          $00                 ; ICI: used for code control (zero vs non-zero)
LC7D8           DW          $0064               ; used as eng speed delta (100 RPM)
LC7DA           DB          $18                 ; idle speed adjustment
LC7DB           DW          $05DC               ; (1500 dec) subtract from short term trim in s/r (bank related adjustment)

acCoolantTempThreshold  DB  $0F
acCoolantTempDelta      DB  $01
init1HzStartDownCount   DB  $0C

LC7E0           DB          $65                 ; ICI: Coolant Temperature threshold
LC7E1           DW          $00C8               ; SM fault test (200 dec)
LC7E3           DB          $40                 ; SM fault test

LC7E4           DS          $C800-*,$FF         ; Fill with $FF until start of code (which normally begins with rpmTable)

;------------------------------------------------------------------------------
;                               RPM Table
;   This table sets up the RPM brackets for the fuel map. Ignition period is
;   measured by the microprocessor and stored as a 16-bit number. The period
;   is measured in 1 uSec increments but is divided by 2 and stored in 2 uSec
;   units. The first two columns in the table are the 16-bit ignition period
;   brackets and the right two columns tell the software how to interpolate
;   the remainder.
;
;   If editing this table, it's important to make sure that the interpolation
;   values are correct for a smoothly changing curve.
;
;------------------------------------------------------------------------------

*               =           $C800

rpmTable        DB          $05, $53, $40, $00  ; 5502 RPM
                DB          $06, $2A, $00, $13  ; 4753 RPM
                DB          $07, $25, $00, $10  ; 4100 RPM
                DB          $07, $D0, $00, $18  ; 3750 RPM
                DB          $09, $73, $80, $9C  ; 3100 RPM
                DB          $0A, $D9, $80, $B7  ; 2700 RPM
                DB          $0E, $A6, $80, $43  ; 2000 RPM
                DB          $10, $BD, $80, $7A  ; 1750 RPM
                DB          $14, $ED, $80, $3D  ; 1400 RPM
                DB          $1A, $A2, $80, $2C  ; 1100 RPM
                DB          $20, $8D, $80, $2B  ;  900 RPM
                DB          $25, $8F, $80, $33  ;  780 RPM
                DB          $29, $DA, $80, $3B  ;  700 RPM
                DB          $2F, $40, $80, $2F  ;  620 RPM
                DB          $3D, $09, $80, $12  ;  480 RPM
                DB          $92, $7C, $40, $2F  ;  200 RPM
