;	10-Apr-2015		timer test v1 
;
;

; hardware register addresses
gpport:    .equ $21
gpport1:   .equ $39

UART0_STATUS:  .equ $00 ; [7: RX READY] [6: TX BUSY] [6 unused bits]
UART0_DATA:    .equ $01

END:	.EQU	$FF	; Mark END OF TEXT

reg1:	.equ $C000


    .ORG $B000

;init

    ; select upcounter latch value
    ld a, $11
    out ($11), a

    ld hl, alive1
    call outstring

    ld hl, reg1
    ld (hl), $F0

 ;	LD	A, $F0
 ;   out (reg1), a

start:

;	LD	A, $FF
;    out (gpport1), a

;	call StartTimer
;	call timerMH

; 	LD	A, $F0



	call StartTimer


start2:

	call timerMH
 ;   out (reg1), a
	LD B, A

	CP	$01					; test compare A to 0x01
	JP	Z, yes1				; is equal JUMP to
  	JP	start2				; is not equal
yes1:
	call togglePort1
	call StartTimer

	call PrintTimer

	jp start2






togglePort1:

;	in a, (reg1)
;    ld hl, reg1
;    ld a, (hl)

	LD IX,$C000				;load HL with 0xC000
	LD A, (IX + 0)


;	XOR A

	CP	$01					; test compare A to 0x01
	JP	Z, yes2				; is equal JUMP to
	LD A, $01
  	JP	ok2				; is not equal
yes2:
	LD A, $00
ok2:

 ;   out (reg1), a
;	ld hl, reg1
 ;   ld (hl), A

 	LD (IX + 0), A

    out (gpport1), a


	call outcharhex
	call outnewline

	ret



timerMH:
	call LatchTimer
    in a, ($16)
	CP	$01					; test for timer MidHigh =0x07
	JP	Z, timeriseq2		; JUMP IF equal to above
  	LD	A, $00				; loads 0x00 to Acc and returns -> not equal to compare value
	ret
timeriseq2:
    in a, ($15)
	CP	$86					; test for timer MidHigh =0x07
	JP	Z, timeriseq		; JUMP IF equal to above
  	LD	A, $00				; loads 0x00 to Acc and returns -> not equal to compare value


	ret
timeriseq:
  	LD	A, $01				; loads 0x01 to Acc and returns -> is equal to compare value
	ret



PrintTimer:
	;print the latched timer value.
    ld hl, timerdone
    call outstring
    in a, ($17)
    call outcharhex
    in a, ($16)
    call outcharhex
    in a, ($15)
    call outcharhex
    in a, ($14)
    call outcharhex
    call outnewline
	ret





StartTimer:
   ; reset hardware timer
    ld a, $01
    out ($11), a
	ret

LatchTimer:
; latch hardware timer value
    ld a, $02
    out ($11), a
	ret




;--------------------------------------------------------------------------------------------  uart routines  (down) -----------------


; outstring: Print the string at (HL) until 0 byte is found
; destroys: AF HL
outstring:
        ld a, (hl)     ; load next character
   ;     and a          ; test if zero


	CP	END			; TEST FOR END BYTE
	JP	Z,outstringEND		; JUMP IF END BYTE IS FOUND


   ;     ret z          ; return when we find a 0 byte
        call outchar
        inc hl         ; next char please
        jr outstring
outstringEND:
		ret

; print the byte in A as a two-character hex value
outcharhex:
        push bc
        ld c, a  ; copy value
        ; print the top nibble
        rra
        rra
        rra
        rra
        call outnibble
        ; print the bottom nibble
        ld a, c
        call outnibble
        pop bc
        ret

; print the nibble in the low four bits of A
outnibble:
        and $0f ; mask off low four bits
        cp 10
        jr c, numeral ; less than 10?
        add a, $07 ; start at 'A' (10+7+0x30=0x41='A')
numeral:
		add a, $30 ; start at '0' (0x30='0')
        call outchar
        ret

; outchar: Wait for UART TX idle, then print the char in A
; destroys: AF
outchar:
        push bc
        ld b, a
        ; wait for transmitter to be idle
ocloop: in a, (UART0_STATUS)
        bit 6, a
        jr nz, ocloop   ; loop while busy

        ; now output the char to serial port
        ld a, b
        out (UART0_DATA), a
        pop bc
        ret

; output a newline
outnewline:
        ld a, $0d   ; output newline
        call outchar
        ld a, $0a
        call outchar
        ret

;--------------------------------------------------------------------------------------------  uart routines  (up) -----------------



DELAY2:
	LD	C,$91	;d1
	LD	B,$E1	;d2
	LD	A,$23	;d3
again31:
	DEC	C
	JP	Z, again30
	JP again31
again30:
	DEC	B
	JP	Z, again32
	JP again31
again32:
	DEC	A
	JP	Z, again33
	JP again31
again33:
	RET


alive1:
	.BYTE "Alive tt1",END
timerdone:
	.BYTE "Timer 0x",END


	.END





