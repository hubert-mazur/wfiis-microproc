; Print value on LCD
.PORT lcd_value, 0x30
.PORT lcd_control, 0x31

LOAD s0, 0
LOAD s1, 1
LOAD s2, 2
LOAD s3, 3
CALL INIT

MAIN:
	OUT s3, lcd_control
	LOAD sF, 0b00101010
	CALL delay3
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
	LOAD sF, 0b00100000
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
	LOAD sF, 0b00101010
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
	OUT sf, lcd_value
	CALL ENABLEPRINT
	CALL delay3
END:
	JUMP END


INIT:
	CALL delay3
	LOAD sF, 0x38
	OUT sF, lcd_value
	CALL ENABLEINIT
	CALL delay3
	LOAD sF, 0x38
	OUT sF, lcd_value
	CALL ENABLEINIT
	CALL delay3
	OUT sF, lcd_value
	CALL ENABLEINIT
	CALL delay3
	OUT sF, lcd_value
	CALL ENABLEINIT
	CALL delay3
	LOAD sF, 0x06
	OUT sF, lcd_value
	CALL ENABLEINIT
	CALL delay3
	LOAD sF, 0x0E
	OUT sF, lcd_value
	CALL ENABLEINIT
	CALL delay3
	LOAD sF, 0x01
	OUT sF, lcd_value
	CALL ENABLEINIT
	CALL delay3
	LOAD sF, 0x80
	OUT sF, lcd_value
	CALL ENABLEINIT
	CALL delay3
	RET

ENABLEINIT:
	OUT s1, lcd_control
	LOAD s0, s0
	LOAD s0, s0
	LOAD s0, s0
	OUT s0, lcd_control
	RET

ENABLEPRINT:
	OUT s3, lcd_control
	LOAD s0, s0
	LOAD s0, s0
	LOAD s0, s0
	OUT s2, lcd_control
	RET

delay:
LOAD sA, 255
petla:
  SUB sA, 1
  JUMP nz, petla
  RET

delay2:
 LOAD sB, 255
 petla2:
	CALL delay
	SUB sB, 1
	JUMP nz, petla2
	RET 

delay3:
	LOAD sC, 255
	petla3:
	CALL delay2
	SUB sC, 1
	JUMP nz, petla3
	RET