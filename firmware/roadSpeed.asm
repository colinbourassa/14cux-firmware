;------------------------------------------------------------------------------
;   14CUX Firmware Rebuild Project
;
;   File Date: 14-Nov-2013  Initial file.
;              09-Mar-2014  Deleted old, incorrect comments, added new comments.
;
;   Description:
;       There are two independent routines in this file. They are both
;   described in detail below.
;
;
;   1) ADC Road Speed Service, Channel 7 (8-bit convert) adcRoutine7
;
;       This is the main road speed service routine. It conditions the 4 KPH
;   idle bit (for control of IACV), periodically writes the road speed, resets
;   the overflow counter and tests for bad VSS (fault code 68). Oddly, the
;   8-bit value measured at channel 7 (the VSS signal) by the ADC prior to
;   entering this routine is not used. Although this wastes processing time,
;   it was probably done this way to fit in with existing round-robin ADC
;   servicing scheme. It is actually the comarator test, described below, that
;   that samples the VSS level often enough to determine road speed.
;
;   2) Road Speed Signal Comparator Test (rdSpdCompTest)
;
;       This is called numerous times from many places in the ICI. Its
;   purpose is to catch or sample every VSS signal transition in order to
;   determine the VSS signal frequency and, thereby, the road speed. The
;   signal from the VSS sensor is a square wave, so the ADC uses the comparator
;   feature of the ADC. It doesn't care about the specific level but simply
;   if it's high or low. The Hitachi ADC's comparator option is used because
;   it is much faster than the successive approximation technique used to
;   resolve signals to 8 or 10 bits.
;
;
;   This is a basic description of road speed function.
;       The intent is to sample the level of the VSS signal often enough to
;   catch every high to low transition. To do this, a routine which does a
;   comparator test on the VSS signal is called 8 times during the course of
;   each spark interrupt. A bit is set high when the signal is detected to be
;   high. When the signal is detected low, the bit is tested. If the bit is low,
;   it means that transition has already been counted, so the subroutine just
;   returns. Otherwise, a variable (vssStateCounter) is incremented and the bit
;   is set low before returning. The result of this is that vssStateCounter is
;   incremented at an increasing rate as road speed increases.
;       There is a timer related counter (timerOverflow2) that increments
;   every time the MPU's free running counter wraps. The road speed routine
;   uses this to periodically (approx. once per second) copy or latch the
;   vssStateCounter into the actual road speed variable (roadSpeed). At this
;   time, the state counter is reset to zero and the process repeats. Note
;   that this means that the road speed is only updated once per second.
;
;
;   There are problems with measuring road speed this way.
;
;   1)  Strobing effects (aliasing) can happen at certain combinations of
;       frequencies.
;   2)  High engine RPM causes the spark interrupt to hog the processor and
;       the main loop gets starved out. Under these conditions, the main
;       service routines may not complete.
;   3)  High engine RPM also puts proportionally increasing burden on the spark
;       interrupt, which limits the effective RPM limit of the 14CUX.
;
;
;   The main road speed variables are listed here. The names will be used in
;   future versions of code instaed of hard-codes addresses. This means that,
;   at some point in the future, the addresses will be subject to change.
;
;                       Original
;   Variable            Address      Description
;   ----------------------------------------------------------------
;   timerOverflow2      X2001       timer overflow counter
;   vssStateCounter     X2002       VSS signal transition counter
;   roadSpeed           X2003       road speed in KPH
;
;
;   The following is from a Land Rover document:
;
;   "The Vehicle Speed Sensor is located on the left hand side of the frame
;   on early models, and on the left hand side of the transfer case on later
;   models. It informs the ECM when vehicle speed is above or below 3 mph.
;   This information is used by the ECM to ensure that the idle air control
;   valve (IACV) is moved to a position to prevent a stall when the vehicle
;   comes to a stop. DTC 68 will be displayed if the MAF is greater than 3V
;   at 2000-3000 RPMs".
;
;------------------------------------------------------------------------------
code

;------------------------------------------------------------------------------
;
;   Main Road Speed Service Routine
;       This routine is called in the main loop when $87 comes up in the round
;   robin ADC control list.
;
;   Road speed related variables are:
;
;   timerOverflow2  - Road Speed latch counter (reset when > 13, takes approx 1 sec)
;   vssStateCounter - VSS signal transition counter
;   roadSpeed       - Road Speed in KPH
;
;------------------------------------------------------------------------------
adcRoutine7     staa        $00C8               ; now both C8 and C9 hold the 8-bit value
                ldab        timerOverflow2      ; latch counter, increments every 65 ms
                cmpb        #$0D                ; compare with 13
                bhi         .resetCounters      ; branch if timerOverflow2 > 13
                bcs         .lessThan13         ; branch if timerOverflow2 < 13
;---------------------------------------------
;    *** Latch Counter as Road Speed ***
; Code gets here when overflow counter is 13.
;---------------------------------------------
                                                ; if here, timerOverflow2 = 13 (happens approx once per second)
                ldab        speedLimitIndicator ; ICI sets this to $AA or $00 to indicate high road speed
                beq         .roadSpeedOK        ; branch if zero (road speed is LT 119 to 122 MPH)
IF BUILD_R3365
                ldab        #$96                ; limit road speed reading to  93 MPH for NAS D90
ELSE
                ldab        #$B0                ; limit road speed reading to 109 MPH for others
ENDC
                bra         .LD38D              ; skip loading transition counter and store value as road speed

                                                ; if here, road speed is LT 122 (or 119?)
.roadSpeedOK    ldab        $2002               ; capture transition counter as road speed

.LD38D          stab        roadSpeed           ; store as road speed (or 176 KPH limit)
                beq         .LD3A5              ; branch if road speed is zero

                                                ; if here, VSS appears to be working (non-zero)
                inc         $207D               ; X207D looks like a fault delay (slowdown) counter
                ldab        $C258               ; this value is usually $0A
                cmpb        $207D               ; compare counter with $0A
                bcc         .resetCounters      ; branch ahead if counter < $0A

                ldab        $2047               ; else, clear internal fault bit
                andb        #$FB                ; clr X2047.2 (clear VSS fail bit)
                stab        $2047

.LD3A5          clr         $207D               ; clear the fault delay counter
;---------------------------------------------
;         *** Reset Counters ***
; Code branches here when timerOverflow2 > 13
;---------------------------------------------
.resetCounters  clrb                            ; reset both latch and transition counters
                sei                             ; these apparently must be clrd together, hence the mask
                stab        $2001               ; reset timerOverflow2
                stab        $2002               ; reset vssStateCounter
                cli                             ; clear interrupt mask

IF NEW_STYLE_AC_CODE
                ldaa        startupDownCount1Hz ; this down-counter is used by A/C routine and is
                beq         .lessThan13         ;  just decremented here
                deca                            ; decrement 1 Hz counter but not less than zero
                staa        startupDownCount1Hz
ENDC

;---------------------------------------------
;        *** Condition Idle Bit ***
;
; Code branches here when X2001 < 13
;---------------------------------------------
                                                ; this sets/clears an idle control bit
.lessThan13     ldaa        $008B               ; load bits value
                ldab        roadSpeed           ; load road speed
                cmpb        #$04                ; compare road speed with 4
                bcc         .roadspeedGT4       ; branch to set X008B.0 if RS > 4

                anda        #$FE                ; clr X008B.0 (road speed < 4)
                bra         .LD3C9

.roadspeedGT4   oraa        #$01                ; set X008B.0 (road speed > 4)

.LD3C9          staa        $008B

;-----------------------------------------------------------
;        Fault Code 68 Test (Vehicle Speed Sensor)
;
;    If road speed value is zero and
;
;    1) MAF is > 3.0 volts
;    2) Engine speed is between 2250 and 3600 RPM
;                (2100 and 3600 for Griffith)
;    3) Fault 68 counter has been incremented enough times
;       (the value is stored in the data section at XC0CE/CF)
;-----------------------------------------------------------
                ldaa        roadSpeed           ; load road speed
                bne         .LD41A              ; branch to skip test if not zero

                ldd         mafDirectHi         ; if here, Road Speed is zero
                addd        mafDirectLo
                subd        #$04CE              ; this equals an average value of 3.0 volts
                bcs         .LD41A              ; abort test if airFlow sum avgs 3.0 volts

                ldaa        ignPeriodFiltered   ; load MSB of ignition period
                cmpa        #dtc68_minimumRPM   ; 2250 RPM for newer code, 2100 RPM for older code
                bcc         .LD41A              ; abort test if engine speed is lower than this

                cmpa        #$08                ; about 3600 RPM
                bcs         .LD41A              ; abort test if engine speed is greater than about 3600 RPM

                ldx         rsFaultSlowdown             ; load Road Speed fault delay counter
                inx                                     ; increment it
                stx         rsFaultSlowdown             ; store it
                cpx         rsFaultSlowdownThreshold    ; compare it with XC0CE/CF (usually $0800)
                bcs         .LD41E                      ; branch to skip fault setting if less than this

                ldaa        $0088
                oraa        #$02                ; set X0088.1 (a Road Speed Sensor Fail bit)
                staa        $0088

                ldaa        faultBits_4C
                oraa        #$40                ; set Fault Code 68 (Vehicle Speed Sensor)
                staa        faultBits_4C

                ldaa        $2047
                oraa        #$04                ; set X2047.2 (another Road Speed Sensor Fail bit)
                staa        $2047

                bra         .LD41E              ; end of Road Speed Sensor fault check

;------------------------------------------------------------------------------
;   Road Speed Comparator (Level) Test
;
;   This is called from 8 different places in the ICI code. The ADC comparator
;   mode is used to determine if the sample of the incoming waveform is high or
;   low. The goal is to sample the waveform often enough to count every high to
;   level transition and, thereby, determine road speed.
;
;   The O2 sensor value 'lambdaReading' is loaded into the B accumulator before
;   returning, although, it appear that only one call needs it.
;
;   The variable 'faultCode26Counter' is incremented from 0 to $FFFF while the
;   vehicle is moving. The effect is somewhat like a distance traveled indicator.
;   'faultCode26Counter' has something to do with DTC 26 which is the Very Lean
;   Mixture Fault. This fault code may be unused.
;
;   The road speed code (above) does not enter at the beginning of this code
;   section. rdSpdCompTest is only called from the ICI.
;
;   Update 17-Mar-2014
;       All ADC measurements use the expanded cycle (Settling Time = 1) which
;   adds 9 uS to the measurement time. This may not be needed for the road
;   speed comparator test.
;       The Defender code version (R3365) triggers the measurement using in-line
;   code and then jumps to an abreviated subroutine. This saves 6 uS per call
;   (the cost of the jsr).
;       Clock cycle execution time is in square brackets.
;
;------------------------------------------------------------------------------
rdSpdCompTest   ldaa        #$27                ; [2] SC=0 PC=1  Set comparator mode on ch 7 (RS)
                staa        AdcControlReg1      ; [4] Hitachi says write this reg starts conversion
                ldaa        #$C8                ; [2] load compare value (to determine high or low)
                staa        AdcDataLow          ; [4] write comparitor value (R4 reg)
                                                ;     1 if Vin > $C8, 0 if Vin < $C8
.LD40D          ldaa        AdcStsDataHigh      ; [4]
                bita        #$40                ; [2] test busy flag (BSY)
                bne         .LD40D              ; [3] loop back if busy
                bita        #$20                ; [2] test comparitor output bit (PCO)
                beq         .lowLevel           ; [3] branch if low
                bra         .highLevel          ; [3] high, branch to set 008B.7
;---------------------------------------------------------------
; Comparator test does not use this code
;---------------------------------------------------------------
                                                ;     VSS fault code test (above) branches here when RS is not zero
                                                ;     or when zero but test passes (such as when stopped at a light)
.LD41A          clra                            ; [2]
                tab                             ; [2]
                std         rsFaultSlowdown     ; [3] clr slowdown counter for road speed sensor fault
;---------------------------------------------------------------
                                                ;     VSS fault code test (above) branches here when waiting for
                                                ;     RS Sensor fail counts or after failure bits are set
.LD41E          ldaa        $00C8               ; [3] 8-bit road speed ADC value
                suba        #$C8                ; [2] compare with threshold
                bcs         .lowLevel           ; [3] if less, branch to road speed low
;---------------------------------------------------------------
; Used by both comparator test and above code (normal RS routine)
;---------------------------------------------------------------
.highLevel      ldaa        $008B               ; [3] waveform is high
                oraa        #$80                ; [2] set 008B.7 (VSS high bit)
                staa        $008B               ; [3]
                bra         .rsReturn           ; [3] return
;---------------------------------------------------------------
.lowLevel       ldaa        $008B               ; [3] waveform is low
                bita        #$80                ; [2] test 008B.7 (test the waveform-high bit)
                beq         .rsReturn           ; [3] just return if it's clear

                anda        #$7F                ; [2] else, clr 008B.7 and count this transition
                staa        $008B               ; [3]
                inc         vssStateCounter     ; [6] (3 of 3) increment X2002 when road speed is not zero
                ldd         faultCode26Counter  ; [4] road speed counter
                addd        #$0001              ; [4] increment road speed counter
                bcs         .loadO2AndRet       ; [3] but stop at $FFFF
                std         faultCode26Counter  ; [5] (value ramps up while vehicle is moving)

                                                ; note that R2157 code (1990) does not have 'faultCode26Counter'
                                                ; nor the loading of 'lambdaReading' before rts

.loadO2AndRet   ldab        lambdaReading       ; [4] load O2 sensor before returning

.rsReturn       rts                             ; [5]
;------------------------------------------------------------------------------
code

