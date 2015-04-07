gpport:    equ 0x21
    ORG 0xB000
start:
	LD	A, 0xFf
    out (gpport), a
	call DELAY2
  	LD	A, 0xF0
    out (gpport), a
	call DELAY2
	jp start
DELAY2:
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
