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
.REG s4, tmp_reg

.REG sA, output_mail
.REG sB, input_mail
.REG sE, read_count
.REG sD, bit
.REG s8, signed

.CONST FCLK_100, 0b1001
.CONST FCLK_1000000, 0b1101

INIT:
	EINT
	LOAD read_count, 12
	LOAD tmp_reg, 1
	OUT tmp_reg, ct_int_mask ; set icp1
	OUT tmp_reg, gpio_B_dir ; set GPIO pin as output
	LOAD int_mask_reg, 32
	OUT int_mask_reg, int_mask ; only timer can generate interrupts
	LOAD ct_config_reg, FCLK_100 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg, 0b11110100  ; 500 us
	LOAD ct_OCR_H_reg, 1  ; 500 us
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H

	LOAD tmp_reg, 0
	OUT tmp_reg, gpio_B_out ; put line low

	CALL delay
	CALL wait1u
	
	LOAD tmp_reg, 0
	OUT tmp_reg, gpio_B_dir ; release line
	LOAD ct_lbyte_reg, 100 ; 120 us
	LOAD ct_OCR_H_reg, 0
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H
	CALL delay
	IN tmp_reg, gpio_B_in
	TEST tmp_reg, 0
	JUMP z, INIT ; something went wrong, line is not low, return to beginning

	; send SKIP_ROM command [CCh], as we have only one device 
	LOAD output_mail, 0xCC
	CALL SEND_VALUE
	
main:
	LOAD s5, 1 ; configure PIN as output
	OUT s5, gpio_B_dir

	; issue Convert T command
	LOAD output_mail, 0x44
	CALL SEND_VALUE

	;wait 1s
	LOAD ct_config_reg, FCLK_1000000 ; fclk / 1 000 000
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg, 0b01100100  ; 1s
	LOAD ct_OCR_H_reg, 0  ; 1s
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H
	CALL delay
	
	; READ SCRATCHPAD
	LOAD output_mail, 0xBE
	CALL SEND_VALUE

	CALL wait1u

	CALL READ_VALUE
	CALL parse_value

; send results to UART
	TEST signed, 1
	CALL z, print_sign

	OUT input_mail, tx
	JUMP INIT

print_sign:
	LOAD tmp_reg, '-'
	OUT tmp_reg, tx
	RET

set_bit:
	OR input_mail, bit
	RET

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
	LOAD ct_config_reg, FCLK_100 ; fclk / 100
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

wait1u:	; wait 2us
	LOAD sC, 0
	wait:
		ADD sC, 1
		COMP sC, 100
		JUMP nz, wait
		ret

int_handler:
	LOAD s6, 1
	LOAD s5, 0
	SUB ct_config_reg, 32 ; turn off timer
	OUT ct_config_reg, ct_config
	OUT s5, ct_status
	OUT s5, int_status
	RETI

; Send predefined value set in output_mail register
SEND_VALUE:
	LOAD tmp_reg, 0
	write_bit_loop:
		COMP tmp_reg, 8
		RET z
		TEST output_mail, tmp_reg
		CALL z, write_1
		CALL nz, write_0
		ADD tmp_reg, 1
		JUMP write_bit_loop

; Read predefined number of bits and store it in input box
READ_VALUE:
	LOAD tmp_reg, 0
	LOAD bit, 1
	; Miss 4 bits which are decimal part
	CALL read
	CALL read
	CALL read
	CALL read
	read_bit_loop:
		COMP tmp_reg, read_count
		RET z
		CALL read
		TEST s7, 1
		CALL z, set_bit
		SL0 bit
		ADD tmp_reg, 1
		JUMP read_bit_loop

parse_value:
	TEST input_mail, 128
	JUMP Z, sign
	LOAD signed, 0
	RET
	sign:
		LOAD tmp_reg, 128
		AND input_mail, 0b01111111
		SUB tmp_reg, input_mail
		LOAD input_mail, tmp_reg
		LOAD signed, 1

.CSEG 0x3FF
	JUMP int_handler