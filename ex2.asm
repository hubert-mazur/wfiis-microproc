.PORT rx, 0x60
.PORT tx, 0x60
.PORT int_status, 0xE0
.PORT int_mask, 0xE1
.PORT uart_int_mask, 0x62
.PORT button_int_mask_port, 0x12

.CONST rx_not_empty, 16
.CONST int_uart_status, 5
.CONST button_int_mask, 192
.REG s0, read
.REG s1, write

init:
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
	IN read, rx
  ADD read, 1
  OUT read, tx
	RET

button_int_handler:
	LOAD s8, 'k'
	OUT s8, tx
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

