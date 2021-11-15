.PORT leds_0, 0x00
.PORT buttons_full, 0x11
LOAD s0, 0
VIEW:
	OUT s0, leds_0
	CALL COUNT
	JUMP VIEW

COUNT:
	CLICK:
		IN s1, buttons_full
		COMP s1, 64
		JUMP nz, CLICK
		CALL delay2
		ADD s0, 1
	UNCLICK:
		IN s1, buttons_full
		COMP s1, 0
		JUMP nz, UNCLICK
		CALL delay2
		RET

delay:
LOAD sF, 255
petla:
  SUB SF, 1
  JUMP nz, petla
  RET

delay2:
 LOAD sE, 255
 petla2:
	CALL delay
	SUB sE, 1
	JUMP nz, petla2
	RET 