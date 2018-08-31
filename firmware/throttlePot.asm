;------------------------------------------------------------------------------
;   14CUX Firmware Rebuild Project
;
;   File Date: 14-Nov-2013
;              26-Mar-2014  Updated comments.
;                           Replaced hard addresses with labels.
;
;   Description:
;       ADC Routine - Throttle Pot - Channel 3 (10-bit conversion)
;
;   ADC service routines are entered with the newly measured ADC value in
;   X00C8/C9 (only X00C9 for 8-bit readings). The A accumulator also contains
;   the 8-bit reading.
;
;------------------------------------------------------------------------------

code


;------------------------------------------------------------------------------
;                *** Fault Check Routine for Throttle Pot ***
;
; This is called by the TPS service routine (below) and by the ICI after the
; TPS value is read. The 10-bit TPS reading is passed into the subroutine in
; the AB accumulators.
;
; This is a fault checking routine with a counter (tpFaultSlowdown)and logic
; to create some "hysteresis" so that the fault state doesn't oscillate.
;
; There are 1023 counts for the full 5 volt span which equates to 4.88 mV
; per bit.
;
; The 'throttlePotDefault' value is $0076 (576 mV) and the 'throttlePotFail'
; threshold is $0008 (39 mV) for later LR code and $0010 (78 mV) for earlier
; code including TVR.
;
; Once a fault code 17 failure has been set, the software needs 240 samples
; greater than 1 Volt before the actual TPS value is again used.
;
;------------------------------------------------------------------------------
TpFaultCheck    std         throttlePot
                subd        #dtc17_tpsMinimum   ; fault code 17 threshold
                bcc         .LCD12              ; branch if TPS > threshold

                ldd         #throttlePotDefault ; failure, so use the default value
                std         throttlePot
                tba                             ; default value is 8-bits, fits in A
                jsr         setTempTPFaults     ; this subroutine sets fault code 17
                ldaa        #$F0                ; reset slowdown counter to 240 dec
                staa        tpFaultSlowdown


.LCD12          ldaa        tpFaultSlowdown     ; load counter
                beq         .LCD26              ; branch ahead if zero

                ldd         throttlePot         ; load 10-bit TPS value
                subd        #$00CD              ; subtract 205 dec (1.0 Volt) from value
                bcs         .tpLessThan1V       ; branch ahead if less than 1 volt

                dec         tpFaultSlowdown         ; TPS > 1 V, decrement counter

.tpLessThan1V   ldd         #throttlePotDefault     ; continue with default value
                std         throttlePot


.LCD26          ldd         throttlePot
                tst         $0085               ; test X0085.7 (no or low eng RPM)
                rts                             ; return

;------------------------------------------------------------------------------
;    ADC Routine - Throttle Pot - Channel 3 (10-bit conversion)
;
;
;    The following is copied from Land Rover documentation:
;
; Throttle Position Sensor (TPS)
;
; This potentiometer is mechanically linked to the throttle butterfly and
; provides an output voltage proportional to the butterfly position. This
; information allows the ECM to determine throttle position and is used for
; ECM strategies like the following:
;   • Acceleration Enhancement - The ECM increases the amount of fuel normally
;   provided for a given throttle position during periods of peak acceleration.
;   This allows the system to anticipate fuel needs.
;   • Deceleration Fuel Shut-off - During throttle closed deceleration, the ECM
;   does not activate fuel injectors (zero pulse-width) to prevent unneeded fuel
;   from entering the cylinders. This strategy protects against catalytic converter
;   overheating and reduces fuel consumption.
;
; 14 CU and CUX throttle circuitry is adaptable within a range of 80 to 500 mV.
; Within this range, the ECM will adapt to the initial setting and use it as a
; reference. There is no need to adjust the TPS following installation on these
; models. If the TPS should fail, the ECM will use a default value of 576 mV and the
; MIL will be illuminated. A diagnostic trouble code (17) is set when sensor output
; is less than 78 mV for longer than 160 milliseconds.
;
;------------------------------------------------------------------------------
adcRoutine3     ldaa        $008B               ; load bits value
                anda        #$01                ; test X008B.0 (1 means road speed > 4 KPH)
                bne         .roadSpeedGT4       ; if 1, branch

;-------------------------------
; Road Speed is less than 4 KPH
;-------------------------------
                jsr         LD609               ; this returns ECT based idle delta (range is about zero to 300)
                addd        $C167               ; value is 1200 (now RPM range is 1200 to about 1500)
                subd        engineRPM           ; subtract actual engine RPM
                bcs         .LCD55              ; branch down to set X0087.6 if eng RPM is greater

.LCD3C          ldaa        $0087               ; if here, RPM is less than calculated value
                anda        #$BF                ; clear X0087.6

.LCD40          staa        $0087               ; store X0087 bits value
                ldd         $00C8               ; load 10-bit throttle pot value
                bsr         TpFaultCheck        ; call fault routine above (tests for low RPM before return)
                bpl         .LCD5E              ; branch if engine is running
                jmp         .LCE58              ; engine not running, branch way down

;-------------------------------
; Road Speed is more than 4 KPH
;-------------------------------
.roadSpeedGT4   jsr         LD609               ; rtns coolant temp based idle delta (range is about zero to 300)
                addd        $C162               ; val is 1500 (now range is 1500 to about 1800)
                subd        engineRPM
                bcc         .LCD3C              ; branch back up if double value is GT x

.LCD55          ldaa        $0087               ; code above branches here when RPM > (1200 + delta)
                oraa        #$40                ; set X0087.6
                bra         .LCD40              ; branch up to common code
;-------------------------------

;-------------------------------
.LCD5B          jmp         .LCE09              ; 'bcc' just below uses this
;-------------------------------
; Engine is running
;-------------------------------
.LCD5E          subd        throttlePotMinimum  ; subtract TPmin from TPS
                std         $00C8               ; store result in temporary location
                bcs         .LCD69              ; branch if TPS is less than TPmin

                subd        #$0007              ; TPS is greater so subtract another 7
                bcc         .LCD5B              ; TPS still greater so branch->jump->CE09 (below)
;----------------------------
.LCD69          clra                            ; if here, TPS is less than TPmin (or less after subtracting 7)
                clrb
                std         $00C8               ; clear X00C8/C9 to zero
                ldaa        $0086               ; load bits value
                bita        #$01                ; test X0086.0
                sei                             ; set int mask (cleared at XCE06)
                bne         .LCD8F              ; branch ahead if X0086.0 is set

                ldx         $C1E3               ; data value is $FFEC (minus 20)
                stx         idleControlValue    ; reset 'idleControlValue' to -20
                ldab        $0088
                andb        #$9F                ; clr 0088 bits 6:5
                stab        $0088
                ldab        #$64
                stab        unusedValue         ; (unused)
                ldab        $0087
                bitb        #$40                ; test 0087.6 (eng RPM GT idle threshold)
                bne         .LCD8F              ; branch ahead if RPM is high enough

                ldab        $C154               ; eng RPM is low (val is 40 dec)
                stab        idleSpeedDelta      ; reset to 40 if eng RPM is LT threshold

.LCD8F          ldab        bits_2059
                bitb        #$04                ; test bits_2059.2 (changed during RTs)
                bne         .LCDFC
                ldab        iacvValue2          ; zero for D90, for RR: zero with 4s and 10s
                bne         .LCDF4
                ldab        $0087
                bitb        #$40                ; test 0087.6 (eng RPM GT threshold)
                beq         .LCDF4              ; branch ahead if eng RPM is low

                ldab        ignPeriodFiltered
                cmpb        $C7CE               ; val is $0A (about 2700 RPM)
                bcs         .LCDFC              ; branch ahead if eng speed is GT 2700 RPM
                ldab        iacMotorStepCount
                bne         .LCDFC              ; branch ahead if iacMotorStepCount is not zero
                ldab        bits_2038
                bitb        #$20                ; test bits_2038.5
                bne         .LCDFC
                ldd         throttlePotCounter  ; only code area that uses this
                bne         .LCDD2
                ldab        $008B
                bitb        #$01                ; test 008B.0 (road speed GT 4)
                beq         .LCDD2
                ldd         ignPeriod          ; this code is ineffective
                subd        $C7CA               ; val is $10D6
                bcc         .LCDD2
                bra         .LCDD2              ; a later code change?

;-------------------------------
; This is unused code
;-------------------------------
.unused         ldab        bits_2038
                orab        #$02
                stab        bits_2038
                ldaa        $0086
                bra         .LCDFC

;-------------------------------
;
;-------------------------------
.LCDD2          ldd         throttlePotCounter               ;
                subd        $C7CC               ; value is $0001
                bcc         .LCDDD
                ldd         #$0000

.LCDDD          std         throttlePotCounter  ; end use of throttlePotCounter
                ldaa        $0086               ; load 0086 into A
                ldab        $008A
                andb        #$FE                ; clr 008A.0 (stepper mtr direction bit, 0 = open)
                stab        $008A
                ldab        $C161               ; value is $0A
                subb        iacvValue0          ; occasionally init to 6 and decremented to zero
                stab        iacMotorStepCount
                stab        iacvValue2
                clr         iacvValue0


.LCDF4          ldab        bits_2059
                orab        #$04                ; set bits_2059.2
                stab        bits_2059


.LCDFC          oraa        #$81                ; set 0086.7 and 0086.0
                staa        $0086               ; store 0086
                ldaa        bits_008C
                oraa        #$04                ; set bits_008C.2
                staa        bits_008C
                cli
                bra         .LCE55
;------------------------------------------------
; Code jumps down to here when TPS is greater
; than TPmin by at least 7 counts.
;------------------------------------------------
.LCE09          subd        #$0005              ; subtract another 5 from TPS reading
                bcs         .LCE55              ; branch down if carry set

                ldaa        bits_008D
                bita        #$10                ; test bits_008D.4 (usually zero)
                beq         .LCE23

                anda        #$EF                ; clr  bits_008D.4
                staa        bits_008D
                ldd         #$0000
                std         purgeValveTimer2    ; set down counter to zero
                ldaa        $00DD
                anda        #$F7                ; clear 00DD.3
                staa        $00DD

.LCE23          ldaa        $0086
                bita        #$01                ; test 0086.0
                beq         .LCE30

                clrb
                stab        tpsClosedLoopCntr   ; counts to 19, can be reset to zero or 255
                ldx         throttlePotMinimum
                stx         throttlePot24bit    ; store as upper 16-bits of 24-bit value


.LCE30          anda        #$7E                ; clr 0086.7 and 0086.0
                oraa        #$04                ; set 0086.2
                staa        $0086
                ldaa        bits_2059
                anda        #$FB                ; clr bits_2059.2
                staa        bits_2059
                ldaa        tpsClosedLoopCntr
                inca
                cmpa        $C13B               ; for 3360 code, value is $14 (20 dec)
                bcs         .LCE4C              ; branch ahead if value is LT 20
                ldaa        $0088
                anda        #$9F                ; clr 0088 bits 6:5
                staa        $0088

.LCE4C          ldaa        iacvValue2
                beq         .LCE55
                sei
                jsr         LEE12               ; deals with iacvValue2 and stepper mtr adj value
                cli


.LCE55          jsr         LF423               ; 1 of 2 calls (other is in ICI) (sets bits according to TP)
;-----------------------------------------------------------
;    This section executes even when eng is NOT running
;    *** Adjust TPmin ***
;-----------------------------------------------------------
                                                ; <-- Eng Not Running (code above jumps here)
.LCE58          jsr         LF0D5               ; update timers (returns 16-bit counter in A-B)
                cli                             ; clr interrupt mask
                ldx         throttlePotMinimum
                cpx         #$0070              ; (X-M:M+1) (bhi test = C + Z = 0)
                bhi         .LCE6C              ; branch if TPMin is GT 112 dec (to set to min value of 17 dec)
                cpx         #$0011
                bcc         .LCE71              ; branch if TPMin is GT  17 dec (normal path)

; Note: Original code can only be duplicated this way.
                DB          $CE,$00,$11,$8C     ; original locations: CE68 to CE6B

.LCE6C          ldx         #$0070              ; This clips TPMin to $70 max
                bra         .LCEA8              ; bra 37 (branch to CEA8)

.LCE71          ldd         throttlePot
                subd        #$0070
                bhi         .LCEAA              ; branch if measured value is higher than 112 dec
                ldaa        $0085
                bita        #$20                ; test 0085.5
                beq         .LCEAA              ; branch if 0085.5 is zero
                ldaa        tpMinCounter        ; slows down TPmin adjustment
                cpx         throttlePot         ; X reg is still TPMin, cmpr with measured throttle pot value
                bhi         .LCE90              ; branch if TPMin is greater than measured value
                ldab        ignPeriod
                cmpb        #$17                ; $1700 = 1274 RPM
                bls         .LCEAA              ; branch ahead if PW is LT $1700 (RPM GT 1274)

                inca                            ; increment tpMinCounter
                bne         .LCEB2              ; and branch to store tpMinCounter if not zero
                inx                             ; this is probably still TPMin being incremented
                bra         .LCE94
                                                ; code above branches here if measured value is LT TPMin
.LCE90          deca                            ; decrement value from tpMinCounter
                bne         .LCEB2              ; and branch to store tpMinCounter if not zero
                dex                             ; this is probably still TPMin being decremented

.LCE94          ldaa        bits_008C
                bita        #$40                ; test bits_008C.6 (indicates data corrupted or ram fail)
                bne         .LCEA8
                stx         $00C8               ; saved data is OK so store new TPMin at 00C8/C9 (temporary)
                ldaa        $00C9
                suba        $0054               ; the 8-bit TPMin working value??
                adda        $C1C0               ; for 3360 code, value is $08
                suba        $C1C2               ; for 3360 code, value is $10
                bhi         .LCEAA
;-----------------

.LCEA8          stx         throttlePotMinimum

                                                ; there are 4 branches (above) to here
.LCEAA          ldaa        $0087               ; code jumps here from above if (todo)
                bita        #$08                ; test 0087.3
                bne         .LCEB4              ; if 0087.3 set, branch to store tpMinCounter instead of reinit
                ldaa        #$34                ; the tpMinCounter init value

.LCEB2          staa        tpMinCounter        ; this slows down TPmin adjustment

.LCEB4          ldaa        $008B               ; bits
                tst         bits_205B           ; bits_205B.7 is cleared at boot
                bmi         .LCECD              ; branch if bits_205B.7 is set
                ldab        $0085
                bitb        #$81                ; test 0085.7 and 0085.0
                bne         .LCECD              ; branch ahead if either bit is set
                oraa        #$20                ; set 008B.5 (throttle is closing)
                staa        $008B
                ldab        bits_205B
                orab        #$80                ; set bits_205B.7 (008B.5 and bits_205B.7 are set together)
                stab        bits_205B
                                                ; 2 branches and fall-thru
.LCECD          bita        #$20                ; test 008B.5
                bne         .LCED4              ; branch to skip jump if 008B.5 is set
;----------------------------
                                                ; 2 references below
.backoffJmp     jmp         .notOpeningFast              ; jump to "Throttle is Closing, the same or LT $18"
;----------------------------

.LCED4          ldd         tpFastOpenThreshold
                std         $00CE
                jsr         LF0D5               ; update timers (returns 16-bit counter in A-B)
                subd        tpsTimer            ; value may be zero
                subd        #$4E20              ; this is 20000 dec
                bcc         .chkChangeRate
                jmp         .LCF98              ; near end of this routine

.chkChangeRate  ldd         throttlePot
                subd        savedThrottlePot    ; previous throttle pot value (only saved when closing)
                bcs         .backoffJmp         ; throttle is closing (or only opening slowly)
                subd        $00CE               ; throttle value is same or higher (subtract $0018 from delta)
                bcs         .backoffJmp         ; throttle is opening quickly

;------------------------------------------------------------------------------
;    Throttle has opened quickly since last call
;------------------------------------------------------------------------------
                sei                             ; throttle is opening, set interrupt mask
                ldaa        $008B
                anda        #$DF                ; clr 008B.5 (zero may indicate throttle opening rapidly)
                staa        $008B
                ldaa        bits_201F
                oraa        #$0C                ; set bits_201F.3 and bits_201F.2 to indicate TP is doing a fuel adjust
                staa        bits_201F
                ldaa        coolantTempCount
                ldab        #$0C                ; length of table is 12d
                ldx         #accelPumpTable
                jsr         indexIntoTable
                clrb
                ldaa        $0C,x               ; load value fron 2nd row of table
                cmpa        #$03                ; compare value with #03
                bcs         .LCF8C              ; skip fueling adjustment if engine is cold

                std         $00C8               ; store X00C8 = value from table, X00C9 = zero

;------------------------------------
; Timer 1 (Right Bank, same polarity)
;------------------------------------
                ldaa        timerCntrlReg1      ; Timer Control Reg 1
                anda        #$FE                ; clr OLVL1 (P21 --> Right or Even Injector Bank)
                staa        timerCntrlReg1
                ldaa        timerStsReg         ;
                bita        #$08                ; test output compare flag (OCF1) for right bank
                bne         .LCF32              ; branch ahead if OCF1 is high (injectors are open)

;----------------------------
; Injectors are closed
;----------------------------
                ldd         ocr1High            ; modify Output Compare Reg 1 by adding the
                addd        $00C8               ;   value from the data table
                std         ocr1High
                ldaa        timerCntrlReg1
                oraa        #$01                ; set OLVL1 (Output Level 1) to re-enable injector bank
                staa        timerCntrlReg1
                cmpa        timerStsReg
                ldd         ocr1High
                std         ocr1High            ; this sequence clears OCF1
                bra         .LCF4F              ; branch ahead to do left bank
;----------------------------
; Injectors are open
;----------------------------
.LCF32          ldd         altCounterHigh      ; reading alternate avoids clearing TOF
                addd        #$0013              ; add 19d to the counter
                std         ocr1High            ; store in Output Compare Reg 1
                cmpa        timerStsReg
                std         ocr1High            ; this sequence clears OCF1
                addd        $00C8               ; create new value by adding X00C8 (from data table)
                std         $00CE               ; save the value in X00CE/CF
                ldaa        timerCntrlReg1
                oraa        #$01                ; set OLVL1 (Output Level 1) to re-enable injector bank
                staa        timerCntrlReg1
                ldd         $00CE               ; reload the new timer value
                std         ocr1High            ; and store it in the output compare reg
                cmpa        timerStsReg
                std         ocr1High            ; this sequence clears OCF1
;---------------------------------------
; Timer 3 (Left Bank, reversed polarity)
;---------------------------------------
.LCF4F          ldaa        timerCntrlReg1
                oraa        #$04                ; set OLVL3 (P12 --> Even Injector Bank)
                staa        timerCntrlReg1
                ldaa        timerStsReg
                bita        #$20                ; test bit 5 in timerStsReg (OCF?)
                bne         .LCF6F
;----------------------------
; Injectors are closed
;----------------------------
                ldd         ocr3high            ; modify Output Compare Reg 3 by adding the
                addd        $00C8               ;   value from the data table
                std         ocr3high
                ldaa        timerCntrlReg1
                anda        #$FB                ; clr OLVL3 (P12 --> Even Injector Bank)
                staa        timerCntrlReg1
                cmpa        timerStsReg
                ldd         ocr3high
                std         ocr3high            ; this sequence clears OCF3
                bra         .LCF8C
;----------------------------
; Injectors are open
;----------------------------
                                                ; code above branches here if OCF3 is high
.LCF6F          ldd         altCounterHigh      ; reading alternate avoids clearing TOF
                addd        #$0013
                std         ocr3high
                cmpa        timerStsReg
                std         ocr3high            ; this sequence clears OCF3
                addd        $00C8               ; create new value by adding X00C8 (from data table)
                std         $00CE               ; save the value in X00CE/CF
                ldaa        timerCntrlReg1
                anda        #$FB                ; clr OLVL3 (Output Level 3) to re-enable injector bank
                staa        timerCntrlReg1
                ldd         $00CE               ; reload the new timer value
                std         ocr3high            ; and store it in the output compare reg
                cmpa        timerStsReg
                std         ocr3high            ; this sequence clears OCF1


;----------------------------
.LCF8C          cli                             ; clear interrupt mask
                bra         .LCF98

;------------------------------------------------------------------------------
;    Throttle is closing or not opening quickly
;------------------------------------------------------------------------------
.notOpeningFast ldd         throttlePot
                std         savedThrottlePot    ; local value
                jsr         LF0D5               ; update timers (returns 16-bit counter in A-B)
                std         tpsTimer            ; value may be zero

.LCF98          ldab        $00DC               ; bits
                ldaa        $008B               ; bits
                bita        #$01                ; test 008B.0 (road speed GT 4)
                bne         .LCFB5              ; branch ahead if RS is GT 4
                ldaa        $0086               ; lda affects Negative and Zero flags
                bpl         .LCFB5              ; branch ahead if 0086.7 is zero
                bitb        #$02                ; test 00DC.1 (air flow init bit?)
                bne         .LCFB9
                orab        #$02                ; set  00DC.1
                stab        $00DC
                ldd         #$8000              ; load init value
                std         secondaryLambdaR
                std         secondaryLambdaL
                bra         .LCFB9              ; branch to rts

.LCFB5          andb        #$F5                ; clr 00DC.3 and 00DC.1
                stab        $00DC

.LCFB9          rts

code
