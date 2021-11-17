.PORT rx, 0x60
.PORT tx, 0x60
.PORT int_status, 0xE0
.PORT int_mask, 0xE1
.PORT uart_int_mask, 0x62
.PORT uart_int_status, 0x61
.PORT button_int_mask_port, 0x12

.CONST rx_not_empty, 16
.CONST int_uart_status, 5
.CONST button_int_mask, 192
.REG s0, read
.REG s1, write
.dseg
	mystring: .db "WFiIS AGH jest super wydzialem! "

.cseg

init:
	LOAD s5, mystring
	LOAD sF, rx_not_empty
	LOAD sE, int_uart_status
	LOAD s7, button_int_mask
	OUT s7, button_int_mask_port
	OUT sF, uart_int_mask
	OUT sE, int_mask
	EINT

main:
	JUMP main

uart_int_handler:
	IN s3, uart_int_mask
	TEST s3, 1
	CALL NZ, string_out
	IN s4, uart_int_status
	TEST s4, 16
	CALL NZ, increment
	RET

increment:
	IN read, rx
  ADD read, 1
  OUT read, tx
	RET

string_out:
	FETCH s6, s5
	COMP s6, 0
	OUT s6, tx
	ADD s5, 1
	CALL Z, set_0
	RET

set_0:
	LOAD s9, rx_not_empty
	OUT s9, uart_int_mask
	LOAD s5, mystring
	RET

button_int_handler:
	LOAD s8, 17
	OUT s8, uart_int_mask
	RET

int_handler:
	IN s2, int_status
	TEST s2, 4
	CALL NZ, uart_int_handler
	TEST s2, 1
	CALL NZ, button_int_handler 
	LOAD sD, 0
	OUT sD, int_status
	RETI

.CSEG 0x3FF
	JUMP int_handler

