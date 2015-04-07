; 2013-10-20: A simple but working ROM monitor program for the great Z80 system-on-FPGA project - from Will Sowerbutts.
; 05-04-2015 Attempt at porting the monitor (from Sowerbutts) to to compiled on tasm z80 compiler 




; hardware register addresses
UART0_STATUS:  .EQU    $00 ; [7: RX READY] [6: TX BUSY] [6 unused bits]
UART0_DATA:    .EQU    $01
UART1_STATUS:  .EQU    $28
UART1_DATA:    .EQU    $29
STACK_INIT:    .EQU    $F000 ; stack (grows downwards, runtime movable)
INPUT_BUFFER:  .EQU    $EF00 ; input buffer (grows upwards, runtime movable)

SPI_CHIPSELECT: .EQU    $18
SPI_STATUS:     .EQU    $19
SPI_TX:         .EQU    $1a
SPI_RX:         .EQU    $1b
SPI_DIVISOR:    .EQU    $1c
GPIO_INPUT:     .EQU    $20
GPIO_OUTPUT:    .EQU    $21

MMU_SELECT:    .EQU    $F8   ; page table entry selector
MMU_PAGE17:    .EQU    $FA   ; magic I/O port that accesses physical memory
MMU_PERM:      .EQU    $FB   ; permission bits [6 unused bits] [WRITE] [READ]
MMU_FRAMEHI:   .EQU    $FC   ; high byte of frame number
MMU_FRAMELO:   .EQU    $FD   ; low byte of frame number
MMU_PTR_VAL0:  .EQU    $FC
MMU_PTR_VAL1:  .EQU    $FD
MMU_PTR_VAL2:  .EQU    $FE
MMU_PTR_VAL3:  .EQU    $FF

FLASH_MAN:     .EQU    $c2
FLASH_DEV1:    .EQU    $20
FLASH_DEV2:    .EQU    $17

RAM_MB: .EQU    $8

        ; on reset, the MMU maps us at $0000 for 4K,
        ; however it's really useful to have access to this
        ; first page because it's where we can put programs
        ; for CP/M to run, etc. So we remap ourselves up to
        ; $f000 and run from there.

.ORG $0000 ; early ROM location (also Z80 reset vector)

        ; test if we're cold booting -- have to do this reasonably quickly,
        ; before the SDRAM controller has initialised itself (~0.1msec)
        in a, (GPIO_INPUT)
        ld b, a ; stash that for now

        di ; disable interrupts (for those arriving via RST 0 rather than CPU reset)
        ; map page at $F000 to $2000000 physical (4K SRAM ROM)
        ld a, $f
        out (MMU_SELECT), a
        ld a, $20
        out (MMU_FRAMEHI), a
        xor a
        out (MMU_FRAMELO), a
        ld a, $03
        out (MMU_PERM), a
        ; jump to monitor in new location
;       jp boot
;
;.ORG $F000
boot:
        ; use MMU to map SDRAM into page 0
        xor a
        out (MMU_SELECT), a
        out (MMU_FRAMEHI), a
        out (MMU_FRAMELO), a
        ld a, $03 ; map it read/write
        out (MMU_PERM), a

        ld a, b ; recover the coldboot flag
        and $80 ; had the SDRAM controller initialisation completed?
        jr z, warmboot ; yes! it's a warm boot then.

        ; no; it's a cold boot
        ld sp, $1000

        ld hl, coldbootmsg
        call outstring

        ; we're going to zero out RAM, each 4K page in turn
        ld hl, $0

        ; use frame starting at $1000
        ld a, 1
        out (MMU_SELECT), a
        ld a, $03
        out (MMU_PERM), a

        ; for each page ...
cbnextpage:
        ; map it in
        ld a, h
        out (MMU_FRAMEHI), a
        out (GPIO_OUTPUT), a ; also display code on LEDs
        ld a, l
        out (MMU_FRAMELO), a
        push hl ; stash page number

        ; write zeroes to the 4K page mapped at $1000....$1fff
        ld hl, $1000
        ld de, $1001
        ld bc, $0fff
        ld (hl), 0 ; fill memory with with 0s
        ldir

        pop hl ; recover page number (we overwrite it in cycle 0, but with 0s)
        inc hl
        ld a, l
        cp 0
        jr nz, cbnextpage
        ld a, h
        call outnibble       ; print char after each MB zeroed
        ld a, h
        cp RAM_MB ; test if we're up to system RAM size?
        jr nz, cbnextpage

        call outnewline

        ; turn off LEDs
        xor a
        out (GPIO_OUTPUT), a

        ; restore MMU config
        xor a
        out (MMU_FRAMEHI), a
        inc a
        out (MMU_FRAMELO), a

        ; fall through to warm boot process
warmboot:
        ld sp, STACK_INIT   ; load stack pointer to point to 1 byte past top of memory
        ld iy, INPUT_BUFFER ; set default input buffer location 256 bytes below top of stack

        ; put a reset vector in place to jump back into us
        ld a, $c3 ; jmp instruction
        ld (0), a
        ld hl, boot
        ld (1), hl

        ; turn off bright LEDs!
        xor a
        out (GPIO_OUTPUT), a

        ; print our greeting
        ld hl, greeting
        call outstring

        ; flush UART FIFO
fifoflush:
        in a, (UART0_DATA)     ; read byte from UART
        in a, (UART0_STATUS)   ; check status
        bit 7, a               ; test if data waiting
        jr nz, fifoflush       ; keep flushing if there is

monitor_loop:
        ld hl, tick
        call outstring







        jp monitor_loop



; compare strings at (HL) and (DE), input buffer in (HL) and command in (DE).
; return with flags NZ -> inequality
; return with flags  Z -> equal ie string at (DE) is a prefix of (HL)
cmdcompare:
        ld a, (de)
        cp 0
        ret z    ; end of string at (DE) -> return zero flag
        cp (hl)
        ret nz   ; non-matching -> return nonzero flag
        inc de
        inc hl
        jr cmdcompare

; outstring: Print the string at (HL) until 0 byte is found
; destroys: AF HL
outstring:
        ld a, (hl)     ; load next character
        and a          ; test if zero
        ret z          ; return when we find a 0 byte
        call outchar
        inc hl         ; next char please
        jr outstring

; print the string at (HL) in hex (continues until 0 byte seen)
outstringhex:
        ld a, (hl)     ; load next character
        and a          ; test if zero
        ret z          ; return when we find a 0 byte
        call outcharhex
        ld a, $20 ; space
        call outchar
        inc hl         ; next char please
        jr outstringhex

; output a newline
outnewline:
        ld a, $0d   ; output newline
        call outchar
        ld a, $0a
        call outchar
        ret

outhl:  ; prints HL in hex. Destroys AF.
        ld a, h
        call outcharhex
        ld a, l
        call outcharhex
        ret

outbc:  ; prints BC in hex. Destroys AF.
        ld a, b
        call outcharhex
        ld a, c
        call outcharhex
        ret

outde:  ; prints DE in hex. Destroys AF.
        ld a, d
        call outcharhex
        ld a, e
        call outcharhex
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
        add A,$07 ; start at 'A' (10+7+$30=$41='A')
numeral:
		add A,$30 ; start at '0' ($30='0')
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


coldbootmsg:        .BYTE "\r\nCold boot: zeroing RAM ", 0
greeting:           .BYTE "\r"
                    .BYTE "  \r\n"
                    .BYTE "Z80 ROM Monitor 05-04-2015)\r\n", 0
tick:     .BYTE "-", 0

	;	ds 0x10000 - $, 0xfe  ; this will be negative when the ROM exceeds 4K so the assembler will alert us to our excess.
	.FILL $EBB, $FE

.END
