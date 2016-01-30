gpport    equ 21H
    ORG 0B000H
start:
	LD	A,FFH
    out (gpport), a
	call DELAY2
  	LD	A,F0H
    out (gpport), a
	call DELAY2
	jp start
DELAY2:
	LD	C,91H	
	LD	B,E1H	
	LD	A,23H	
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

what_msg:           db "Error reduces\r\nYour expensive computer\r\nTo a simple stone.\r\n", 0
