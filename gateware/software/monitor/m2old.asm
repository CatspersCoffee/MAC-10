; 2013-10-20: A simple but working ROM monitor program for the great Z80 system-on-FPGA project.
; This is my first Z80 assembler program so ... be kind.

; Wishlist:
;    dm could print an extra space after 8th char, and chars in ASCII on the right hand side, a la hexdump -C

; hardware register addresses
UART0_STATUS:  equ 0x00 ; [7: RX READY] [6: TX BUSY] [6 unused bits]
UART0_DATA:    equ 0x01
UART1_STATUS:  equ 0x28
UART1_DATA:    equ 0x29
STACK_INIT:    equ 0xF000 ; stack (grows downwards, runtime movable)
INPUT_BUFFER:  equ 0xEF00 ; input buffer (grows upwards, runtime movable)

SPI_CHIPSELECT: equ 0x18
SPI_STATUS:     equ 0x19
SPI_TX:         equ 0x1a
SPI_RX:         equ 0x1b
SPI_DIVISOR:    equ 0x1c
GPIO_INPUT:     equ 0x20
GPIO_OUTPUT:    equ 0x21

MMU_SELECT:    equ 0xF8   ; page table entry selector
MMU_PAGE17:    equ 0xFA   ; magic I/O port that accesses physical memory
MMU_PERM:      equ 0xFB   ; permission bits [6 unused bits] [WRITE] [READ]
MMU_FRAMEHI:   equ 0xFC   ; high byte of frame number
MMU_FRAMELO:   equ 0xFD   ; low byte of frame number
MMU_PTR_VAL0:  equ 0xFC
MMU_PTR_VAL1:  equ 0xFD
MMU_PTR_VAL2:  equ 0xFE
MMU_PTR_VAL3:  equ 0xFF

FLASH_MAN:     equ 0xc2
FLASH_DEV1:    equ 0x20
FLASH_DEV2:    equ 0x17

RAM_MB: equ 8

        ; on reset, the MMU maps us at 0x0000 for 4K,
        ; however it's really useful to have access to this
        ; first page because it's where we can put programs
        ; for CP/M to run, etc. So we remap ourselves up to
        ; 0xf000 and run from there.

        org 0x0000 ; early ROM location (also Z80 reset vector)

        ; test if we're cold booting -- have to do this reasonably quickly,
        ; before the SDRAM controller has initialised itself (~0.1msec)
        in a, (GPIO_INPUT)
        ld b, a ; stash that for now

        di ; disable interrupts (for those arriving via RST 0 rather than CPU reset)
        ; map page at 0xF000 to 0x2000000 physical (4K SRAM ROM)

		LD SP,$FF00				; load Stack Pointer to 


monitor_loop:
		LD	A, 0x44
        call outchar

  		LD	A, 0xF8
        out (GPIO_OUTPUT), a

		call DELAY2

  		LD	A, 0xF4
        out (GPIO_OUTPUT), a

		call DELAY2

		LD	A, 0x45
        call outchar

  		LD	A, 0xF2
        out (GPIO_OUTPUT), a

		call DELAY2

  		LD	A, 0xF1
        out (GPIO_OUTPUT), a

		call DELAY2


        jp monitor_loop


DELAY1:
		LD	C,0xFE				;put 0xFF in the C reg
again3:
		LD	B,0xFF				;put 0xFF in the B reg
again2:
		LD	A,0xFF				;put 0xFF in the A reg
again:
		DEC	A
		JP	NZ, again
		DEC	B
		JP	NZ, again2
		DEC	C
		JP	NZ, again3
		RET	

DELAY2:
; Delay = 0.5 seconds
; Clock frequency = 128 MHz
; Actual delay = 0.5 seconds = 16000000 cycles
; Error = 0 %

			;15999996 cycles
	LD	C,0x91	;d1
	LD	B,0xE1	;d2
	LD	A,0x23	;d3

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

;Delay3_0
;	decfsz	d1, f
;	goto	$+2
;	decfsz	d2, f
;	goto	$+2
;	decfsz	d3, f
;	goto	Delay3_0



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

; pad to 4K
                    ds 0x10000 - $, 0xfe  ; this will be negative when the ROM exceeds 4K so the assembler will alert us to our excess.
