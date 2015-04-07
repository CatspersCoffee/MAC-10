gpport:    .equ $21
    .ORG $B000
start:
	LD	A, $F8
    out (gpport), a
	call DELAY2
	LD	A, $F4
    out (gpport), a
	call DELAY2
	LD	A, $F2
    out (gpport), a
	call DELAY2
  	LD	A, $F1
    out (gpport), a
	call DELAY2
	jp start
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
	.END

