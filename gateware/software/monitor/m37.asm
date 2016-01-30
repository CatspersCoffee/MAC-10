gpport:    equ $21
    ORG B000h
start:
	LD	A, Ffh
    out (gpport), a
	call DELAY2
  	LD	A, F0h
    out (gpport), a
	call DELAY2
	jp start
DELAY2:
	LD	C,91h	;d1
	LD	B,E1h	;d2
	LD	A,23h	;d3
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
	.END

