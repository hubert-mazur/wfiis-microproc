; Read characters from UART and print them on LCD
.PORT lcd_value, 0x30
.PORT lcd_control, 0x31
.PORT uart_rx, 0x60
.PORT uart_tx, 0x60
.PORT uart_status, 0x61
.PORT uart_int_mask, 0x62

LOAD s0, 0
LOAD s1, 1
LOAD s2, 2
LOAD s3, 3
CALL INIT

main:
	OUT s3, lcd_control
read:
  IN sF, uart_status
  TEST sF, 0x10
  JUMP Z, read
  IN sD, uart_rx
	LOAD sF, sD
	OUT sf, lcd_value
  OUT sf, uart_tx
	CALL ENABLEPRINT
  JUMP read


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