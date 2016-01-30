;	10-Apr-2015		timer test v1 
;	11-Apr-2015		working as "tt1.asm" -> modifying as "tt2.asm" to test interrupt function of downcounter
;

; hardware register addresses
gpport:    .equ $21
gpport1:   .equ $39

UART0_STATUS:  .equ $00 ; [7: RX READY] [6: TX BUSY] [6 unused bits]
UART0_DATA:    .equ $01

    .ORG $0000

	jp init


	.ORG $0066 ; NMI interrupt vector

	PUSH BC
	PUSH DE
	PUSH HL
	PUSH AF
	PUSH IX
	PUSH IY



    .ORG $0F00

init:

    ; select upcounter latch value
    ld a, 0x11
    out (0x11), a



start:
	LD	A, $FF
    out (gpport1), a
	call DELAY2




;timer counting





  	LD	A, $F0
    out (gpport1), a
	call DELAY2





	;print the latched timer value, then start over.

    ld de, timerdone
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




	jp start

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
        and a          ; test if zero
        ret z          ; return when we find a 0 byte
        call outchar
        inc hl         ; next char please
        jr outstring


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
        add $07 ; start at 'A' (10+7+0x30=0x41='A')
numeral:add $30 ; start at '0' (0x30='0')
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
        ld a, 0x0d   ; output newline
        call outchar
        ld a, 0x0a
        call outchar
        ret

;--------------------------------------------------------------------------------------------  uart routines  (up) -----------------

timerdone:
        .BYTE "Timer 0x", 0



    .ORG $B300









	.END

