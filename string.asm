; Send string with UART
.PORT uart_rx, 0x60
.PORT uart_tx, 0x60
.PORT uart_status, 0x61
.PORT uart_int_mask, 0x62

.dseg
	mystring: .db "WFiIS AGH jest super wydzialem"

.cseg

main:
	LOAD s1, mystring
	FETCH s0, s1
  CALL read
end:
JUMP end
	
read:
  IN sF, uart_status
  TEST sF, 0x4
  JUMP NZ, read
	OUT s0, uart_tx
  ADD s1, 1
	FETCH s0, s1
	COMP s0, 0
	JUMP NZ, read
	ret

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