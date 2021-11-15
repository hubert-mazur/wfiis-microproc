.PORT leds_0, 0x0

LOAD s0, 44
LOAD s1, 230
ADD s1, s0
OUT s1, leds_0
END:
  JUMP END