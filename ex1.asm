.PORT rx, 0x60
.PORT tx, 0x60
.PORT int_status, 0xE0
.PORT int_mask, 0xE1
.PORT uart_int_mask, 0x62

.CONST rx_not_empty, 16
.CONST int_uart_status, 4

.REG s0, read
.REG s1, write

init:
	LOAD sF, rx_not_empty
	LOAD sE, int_uart_status
	OUT sF, uart_int_mask
	OUT sE, int_mask
	EINT

main:
	JUMP main

int_handler:
	IN read, rx
  ADD read, 1
  OUT read, tx
	LOAD sD, 0
	OUT sD, int_status
	RETI

.CSEG 0x3FF
	JUMP int_handler

