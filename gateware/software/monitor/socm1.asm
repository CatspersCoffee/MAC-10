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

dfdfs:

        xor a
        out (GPIO_OUTPUT), a


		CALL DELAY1
		CALL DELAY1
		CALL DELAY1


		LD     A,$41

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


		JP dfdfs

;------------------------------------------------------------------------
DELAY1:
			LD	B,$FF				;put 0xFF in the B reg
again2:
			LD	A,$FF				;put 0xFF in the A reg
again:
			DEC	A
			JP	NZ, again

			DEC	B
			JP	NZ, again2

			RET	
;------------------------------------------------------------------------







	;	ds 0x10000 - $, 0xfe  ; this will be negative when the ROM exceeds 4K so the assembler will alert us to our excess.
	.FILL $EBB, $FE

.END
