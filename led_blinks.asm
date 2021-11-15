.PORT leds_0, 0x0
.PORT switch, 0x10
.PORT buttons_full, 0x11

LOAD s0, 0xCC

BLINK:
	IN s4, buttons_full
	COMP s4, 0x01
	JUMP z, case1
	JUMP case2

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

delay3:
	LOAD sD, 255
	petla3:
	CALL delay2
	SUB sD, 1
	JUMP nz, petla3
	RET

case1:
	IN s2, switch
	OUT s2, leds_0
	JUMP BLINK

case2:
  OUT s0, leds_0
  JUMP BLINK
	