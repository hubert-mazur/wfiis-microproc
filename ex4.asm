.PORT ct_lbyte, 0xC0
.PORT ct_config, 0xC1
.PORT ct_OCR_H, 0xC2
.PORT ct_status, 0xC9
.PORT ct_int_mask, 0xCA
.PORT int_status, 0xE0
.PORT int_mask, 0xE1
.PORT rx, 0x60
.PORT tx, 0x60


INIT:
	LOAD sF, 32
	OUT sF, int_mask
	LOAD s0, 13
	OUT s0, ct_config
	LOAD s1, 99
	LOAD s2, 0
	OUT s1, ct_lbyte
	OUT s2, ct_OCR_H
	ADD s0, 32
	OUT s0, ct_config
	LOAD s3, 0
	LOAD s4, 1
	OUT s4, ct_int_mask
	EINT


MAIN:
	JUMP MAIN


int_handler:
	OUT s3, tx
	ADD s3, 1
	LOAD s5, 0
	OUT s5, ct_status
	OUT s5, int_status
	RETI

.CSEG 0x3FF
	JUMP int_handler