; Send character with UART
.PORT uart_rx, 0x60
.PORT uart_tx, 0x60
.PORT uart_status, 0x61
.PORT uart_int_mask, 0x62

main:
	LOAD s0, 'a'
  OUT s0, uart_tx

read:
  IN sF, uart_status
  TEST sF, 0x10
  JUMP Z, read
  IN s2, uart_rx
  CALL delay2
  ADD s2, 1
	OUT s2, uart_tx
 CALL delay2

  
JUMP read
END:
	jump END


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