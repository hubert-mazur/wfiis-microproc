.PORT ct_lbyte, 0xC0
.PORT ct_config, 0xC1
.PORT ct_OCR_H, 0xC2
.PORT ct_status, 0xC9
.PORT ct_int_mask, 0xCA
.PORT int_status, 0xE0
.PORT int_mask, 0xE1
.PORT rx, 0x60
.PORT tx, 0x60
.PORT gpio_B_in, 0x21
.PORT gpio_B_out, 0x21
.PORT gpio_B_dir, 0x29
.REG s0, ct_config_reg
.REG s1, ct_lbyte_reg
.REG s2, ct_OCR_H_reg
.REG s3, uart_out_reg
.REG sF, int_mask_reg


INIT:
	EINT
	LOAD s4, 1
	OUT s4, ct_int_mask
	OUT s4, gpio_B_dir
	LOAD int_mask_reg, 32
	OUT int_mask_reg, int_mask 
	LOAD ct_config_reg, 9 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg, 0b11110100  ; 500 us
	LOAD ct_OCR_H_reg, 1  ; 500 us
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H

	LOAD s5, 0
	OUT s5, gpio_B_out ; zero na linii

	CALL delay
	CALL wait1u
	
	LOAD s5, 0
	OUT s5, gpio_B_dir

	CALL delay
	
main:

	LOAD s5, 1 ; bierzemy linie
	OUT s5, gpio_B_dir

	; wysylamy convert T
	CALL write_1
	CALL write_0
	CALL write_0
	CALL write_0
	CALL write_1
	CALL write_0
	CALL write_0

; czkamy 1s
	LOAD ct_config_reg, 13 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg, 0b01100100  ; 1000 ms
	LOAD ct_OCR_H_reg, 0  ; 1000 ms
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H
	CALL delay
	
	CALL write_1
	CALL write_0
	CALL write_1
	CALL write_1
	CALL write_1
	CALL write_1
	CALL write_1
	CALL write_0

	LOAD s8, 0

	LOAD s9, 1 ; ktory bit ustawiamy
	CALL read
	TEST s7, 1
	CALL z, set_bit

	LOAD s9, 2 ; ktory bit ustawiamy
	CALL read
	TEST s7, 1
	CALL z, set_bit

	LOAD s9, 4 ; ktory bit ustawiamy
	CALL read
	TEST s7, 1
	CALL z, set_bit

	LOAD s9, 8 ; ktory bit ustawiamy
	CALL read
	TEST s7, 1
	CALL z, set_bit

	LOAD s9, 16 ; ktory bit ustawiamy
	CALL read
	TEST s7, 1
	CALL z, set_bit

	LOAD s9, 32 ; ktory bit ustawiamy
	CALL read
	TEST s7, 1
	CALL z, set_bit

	LOAD s9, 64 ; ktory bit ustawiamy
	CALL read
	TEST s7, 1
	CALL z, set_bit

	LOAD s9, 128 ; ktory bit ustawiamy
	CALL read
	TEST s7, 1
	CALL z, set_bit

; zczytujemy temp

	JUMP main

	OUT ct_config_reg, ct_config
	LOAD uart_out_reg, 0
	LOAD s5, 0

set_bit:
	;LOAD s8, s8 | s9
	OR s8, s9

LOOP2:
		TEST s6, 0
		JUMP z, LOOP2

write_0:
		LOAD s5, 1
		OUT s5, gpio_B_dir
		LOAD s5, 0
		OUT s5, gpio_B_out ; zero na linii na 80 us
		; chcemy czekac 80us
		LOAD ct_config_reg, 9 ; fclk / 100
		OUT ct_config_reg, ct_config
		LOAD ct_lbyte_reg,  0b01100100; 100 us
		LOAD ct_OCR_H_reg, 0  ; 100 us
		CALL delay ; czekamy 80us
		LOAD s5, 0
		OUT s5, gpio_B_dir

write_1:
		LOAD s5, 1
		OUT s5, gpio_B_dir
		LOAD s5, 0
		OUT s5, gpio_B_out ; zero na linii na 80 us
		call wait1u
		LOAD s5, 1
		OUT s5, gpio_B_out
		LOAD ct_config_reg, 9 ; fclk / 100
		OUT ct_config_reg, ct_config
		LOAD ct_lbyte_reg,  0b00011110; 30 us
		LOAD ct_OCR_H_reg, 0  ; 30 us
		call delay
		LOAD s5, 0
		OUT s5, gpio_B_dir

read:
	LOAD s5, 1
	OUT s5, gpio_B_dir
	CALL wait1u
	LOAD s5, 0
	OUT s5, gpio_B_dir
	LOAD ct_config_reg, 9 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg,  0b00011110; 30 us
	LOAD ct_OCR_H_reg, 0  ; 30 us
	call delay
	IN s7, gpio_B_in
	CALL wait1u
	RET
	

delay:
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H
	LOAD s6, 0
	ADD ct_config_reg, 32 ; wlacz timer
	OUT ct_config_reg, ct_config
	loop4:	
		TEST s6, 0
		JUMP z, loop4
	call wait1u
	RET


wait1u:	; czekamy 2us
	LOAD sC, 0
	wait:
		ADD sC, 1
		COMP sC, 100
		JUMP nz, wait
		ret


int_handler:
	LOAD s6, 1
	LOAD s5, 0
	SUB ct_config_reg, 32 ; wylacz timer
	OUT ct_config_reg, ct_config
	OUT s5, ct_status
	OUT s5, int_status
	RETI

	;OUT uart_out_reg, tx
	;ADD uart_out_reg, 1
	;LOAD s5, 0
	;OUT s5, ct_status
	;OUT s5, int_status
	;RETI

.CSEG 0x3FF
	JUMP int_handler