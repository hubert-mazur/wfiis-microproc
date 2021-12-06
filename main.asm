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
.PORT ct_TCR_H, 0xC4

.REG s0, ct_config_reg
.REG s1, ct_lbyte_reg
.REG s2, ct_OCR_H_reg
.REG s3, uart_out_reg
.REG s4, tmp_reg
.REG s8, signed
.REG sA, output_mail
.REG sB, input_mail
.REG sD, bit
.REG sF, int_mask_reg

.PORT leds_0, 0x0

.CONST FCLK_100, 0b1001
.CONST FCLK_1000000, 0b1101

PRE_INIT:
	EINT
	LOAD tmp_reg, 's'
	OUT tmp_reg, tx
	LOAD tmp_reg, 1
	OUT tmp_reg, ct_int_mask ; set icp1
	LOAD int_mask_reg, 32
	OUT int_mask_reg, int_mask ; only timer can generate interrupts
	
main:
	CALL INIT

	; issue Convert T command
	LOAD output_mail, 0x44
	CALL SEND_VALUE

	LOAD s5, 1
	OUT s5, leds_0

	;wait 1s
	LOAD ct_config_reg, FCLK_1000000 ; fclk / 1 000 000
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg, 0b01100100  ; 1s
	LOAD ct_OCR_H_reg, 0  ; 1s
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H
	CALL delay
	
	LOAD s5, 64
	OUT s5, leds_0
	
	CALL INIT
	; READ SCRATCHPAD
	LOAD output_mail, 0xBE
	CALL SEND_VALUE
	CALL wait1u
	CALL READ_VALUE
	OUT input_mail, leds_0
	
	COMP signed, 1
	CALL Z, print_sign

	CALL parse_value

	CALL PRINT_TO_SCREEN

	
	JUMP PRE_INIT

; send results to UART
	TEST signed, 1
	CALL z, print_sign

	OUT input_mail, tx
	JUMP PRE_INIT

INIT:
	LOAD ct_config_reg, FCLK_100 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg, 0b11110100  ; 500 us
	LOAD ct_OCR_H_reg, 1  ; 500 us
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H
	
	LOAD tmp_reg, 1
	OUT tmp_reg, gpio_B_dir	 ; take the line
	LOAD tmp_reg, 0
	OUT tmp_reg, gpio_B_out ; put line low

	CALL delay

	LOAD tmp_reg, 0
	OUT tmp_reg, gpio_B_dir ; release line
	LOAD ct_lbyte_reg, 100 ; 120 us
	LOAD ct_OCR_H_reg, 0
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H
	CALL delay
	IN tmp_reg, gpio_B_in
	TEST tmp_reg, 1
	JUMP nz, PRE_INIT ; something went wrong, line is not low, return to beginning

	LOAD ct_config_reg, FCLK_100 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg, 0b11110100  ; 500 us
	LOAD ct_OCR_H_reg, 1  ; 500 us
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H

	CALL delay

	; send SKIP_ROM command [CCh], as we have only one device
	LOAD output_mail, 0xCC
	CALL SEND_VALUE

	RET

NOP:
JUMP NOP

print_sign:
	LOAD tmp_reg, '-'
	OUT tmp_reg, tx
	RET

set_bit:
	OR input_mail, bit
;	LOAD s5, '1'
;	OUT s5, tx
	RET

reset_timer:
	LOAD s5, 0
	OUT s5, ct_lbyte
	OUT s5, ct_TCR_H
	RET
	
write_0:
; chcemy czekac 80us
	LOAD ct_config_reg, 9 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg,  0b01100100; 100 us
	LOAD ct_OCR_H_reg, 0  ; 100 us

	LOAD s5, 1
	OUT s5, gpio_B_dir
	LOAD s5, 0
	OUT s5, gpio_B_out ; zero na linii na 80 us

	CALL delay ; czekamy 80us
	LOAD s5, 0
	OUT s5, gpio_B_dir
	CALL wait1u
	CALL wait1u
	RET

write_1:

	LOAD ct_config_reg, 9 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg,  60; 30 us
	LOAD ct_OCR_H_reg, 0  ; 30 us

	LOAD s5, 1
	OUT s5, gpio_B_dir

	LOAD s5, 0
	OUT s5, gpio_B_out ; zero na linii na 80 us
	call wait1u
	LOAD s5, 1
	OUT s5, gpio_B_out
	call delay

	RET

read:
	LOAD s5, 1
	OUT s5, gpio_B_dir
	LOAD s5, 0
	OUT s5, gpio_B_out

	CALL wait1u
	
	LOAD s5, 0
	OUT s5, gpio_B_dir

	LOAD ct_config_reg, FCLK_100 ; fclk / 100
	OUT ct_config_reg, ct_config
	LOAD ct_lbyte_reg,  45; 45 us
	LOAD ct_OCR_H_reg, 0  ; 45us
	;call delay
	CALL wait1u
	IN s7, gpio_B_in
	CALL wait1u
	CALL delay

	RET
	
delay:
	CALL reset_timer
	OUT ct_lbyte_reg, ct_lbyte
	OUT ct_OCR_H_reg, ct_OCR_H
	LOAD s6, 0
	ADD ct_config_reg, 32 ; wlacz timer
	OUT ct_config_reg, ct_config

	loop4:	
		COMP s6, 0
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
	LOAD tmp_reg, 1
	write_bit_loop:
		COMP tmp_reg, 0
		RET z
		;OUT tmp_reg, leds_0
		TEST output_mail, tmp_reg
		CALL z, write_0
		TEST output_mail, tmp_reg
		CALL nz, write_1
		SL0 tmp_reg
		JUMP write_bit_loop

; Read predefined number of bits and store it in input box
READ_VALUE:
	LOAD input_mail, 0
	LOAD s5, 'r'
	OUT s5, tx
	;LOAD tmp_reg, 0
	LOAD bit, 1
	; Miss 4 bits which are decimal part
	CALL read
	CALL read
	CALL read
	CALL read
	read_bit_loop:
		COMP bit, 0
		RET z
		CALL read
		TEST s7, 1
		CALL nz, set_bit
;		TEST s7, 1
;		CALL z, dont_set_bit
		
		SL0 bit
		JUMP read_bit_loop

dont_set_bit:
		LOAD s5, '0'
		OUT s5, tx
		RET

parse_value:
	TEST input_mail, 128
	JUMP NZ, sign
	LOAD signed, 0
	RET
	sign:
		LOAD tmp_reg, 128
		AND input_mail, 0b01111111
		SUB tmp_reg, input_mail
		LOAD input_mail, tmp_reg
		LOAD signed, 1
		RET

PRINT_TO_SCREEN:
	LOAD s5, 0
	LOAD s7, 0
	LOAD s9, 0
	LOAD tmp_reg, 0
	loop:
		ADD tmp_reg, 1
		ADD s5, 1
		COMP s5, 10
		CALL Z, ROLL_10
		COMP input_mail, tmp_reg
		JUMP NZ, loop
		CALL PRINT_RES
		RET
	
ROLL_10:
	LOAD s5, 0
	ADD s7, 1
	COMP s7, 10
	CALL Z, ROLL_100
	RET

ROLL_100:
	LOAD s7, 0
	ADD s9, 1
	RET


PRINT_RES:
	LOAD tmp_reg, s9
	COMP tmp_reg, 0
	CALL NZ, print_val
	
	LOAD tmp_reg, s7
	COMP tmp_reg, 0
	JUMP NZ, next
	
	COMP s9, 0
	CALL NZ, print_val
	JUMP s5_seg
	next:
		CALL print_val
	s5_seg:
		LOAD tmp_reg, s5
		CALL print_val
		RET

print_val:
	COMP tmp_reg, 0
	JUMP Z, print_0
	COMP tmp_reg, 1
	JUMP Z, print_1
	COMP tmp_reg, 2
	JUMP Z, print_2
	COMP tmp_reg, 3
	JUMP Z, print_3
	COMP tmp_reg, 4
	JUMP Z, print_4
	COMP tmp_reg, 5
	JUMP Z, print_5
	COMP tmp_reg, 6
	JUMP Z, print_6
	COMP tmp_reg, 7
	JUMP Z, print_7
	COMP tmp_reg, 8
	JUMP Z, print_8
	COMP tmp_reg, 9
	JUMP Z, print_9

print_0:
	LOAD s6, '0'
	OUT s6, tx
	RET

print_1:
	LOAD s6, '1'
	OUT s6, tx
	RET

print_2:
	LOAD s6, '2'
	OUT s6, tx
	RET

print_3:
	LOAD s6, '3'
	OUT s6, tx
	RET

print_4:
	LOAD s6, '4'
	OUT s6, tx
	RET

print_5:
	LOAD s6, '5'
	OUT s6, tx
	RET

print_6:
	LOAD s6, '6'
	OUT s6, tx
	RET

print_7:
	LOAD s6, '7'
	OUT s6, tx
	RET

print_8:
	LOAD s6, '8'
	OUT s6, tx
	RET

print_9:
	LOAD s6, '9'
	OUT s6, tx
	RET

.CSEG 0x3FF
	JUMP int_handler