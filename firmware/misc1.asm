;------------------------------------------------------------------------------
;                       Subroutine called from end of ICI
;
; Called only at end of ICI (before partial reset)
; Alters values at 008E/8F, 0090/91
;------------------------------------------------------------------------------

code

LF018           sei
                ldaa        bits_0089
                anda        #$03                ; test bits_0089.1 and bits_0089.0
                beq         .LF04B              ; return if both bits are zero
                ldx         $0094               ; X0094/95 looks like a small signed number
                bmi         .LF026              ; (ldx affects negative flag, this is the only way to F026)

                dex                             ; if it's not negative, decrement it, store it and rtn
                bra         .LF049
                                                ; if here, X0094.7 is set
.LF026          ldx         #$008E              ; X008E/8F is used for lean condition
                ldd         $00,x               ; loads X008E/8F or X0094/95
                bne         .LF033
                ldaa        bits_0089
                anda        #$FE                ; clr bits_0089.0
                staa        bits_0089

.LF033          jsr         LEE29               ; adds (or subtracts) 1 to/from X008E/8F
                ldx         #$0090              ; X0090/91 is used for rich condition
                ldd         $00,x               ; load X0090/91
                bne         .LF043
                ldaa        bits_0089
                anda        #$FD                ; clr bits_0089.1
                staa        bits_0089

.LF043          jsr         LEE29               ; adds (or subtracts) 1 to/from X0090/91
                ldx         $C09E               ; val is $0002 ($FF9E is in some builds by mistake)

.LF049          stx         $0094               ; decrements value or stores #$0002

.LF04B          cli
                rts
code
