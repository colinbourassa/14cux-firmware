;------------------------------------------------------------------------------
;   14CUX Firmware Rebuild Project
;
;   File Date: 14-Nov-2013
;
;   Description:
;       The A/C service routine can jump to this code block which is in a
;   different location, outside of the branch range. There is no apparent
;   reason why it was separated.
;
;   Value (either $00 or $FF) is passed in A accumulator.
;       If A is $00, bits_008C.7 is cleared.
;       If A is $FF, bits_008C.7 is set.
;
;------------------------------------------------------------------------------

code
LD49E           ldab        bits_008C
                tsta                            ; test bit 7 (pos or neg)
                bmi         .LD4A7              ; branch if minus (bit is set)
                andb        #$7F                ; clr bits_008C.7
                bra         .LD4A9


.LD4A7          orab        #$80                ; set bits_008C.7


.LD4A9          stab        bits_008C           ; store value
                rts                             ;   and return to main loop
code
