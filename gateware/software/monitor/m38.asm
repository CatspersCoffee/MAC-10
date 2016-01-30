gpport    equ 021H
    ORG 0B000H
start:
	LD	A, 0FFH
    out (gpport), a
	call DELAY2
  	LD	A, 0F0H
    out (gpport), a
	call DELAY2
	jp start
DELAY2:
	LD	C,091H	
	LD	B,0E1H	
	LD	A,023H	
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
