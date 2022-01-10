#include "LPC17xx.h" // Device header
#include <stdio.h>

#define UART_DLL 0x4000C000
#define UART_FDR 0x4000C028

#define UART_LSB
#define UART_MSB

#define CONVERT_T			0x44
#define READ_SCRATCHPAD		0xBE
#define SKIP_ROM			0xCC

typedef enum
{
	false = 0,
	true = 1,
} bool;

volatile bool timer_done;

void wait(uint32_t time);
void print_string(const char *str);
void init_UART();
void change_pin_direction(bool input);
void set_gpio_state(bool high);
void init_gpio();
void send_message(uint8_t val);
int init_1_wire();
float read_value();

int main()
{
	float temp;
	char buffer[100];

	init_UART();
	init_gpio();

	print_string("Init!\r\n");

	while (1)
	{
		init_1_wire();
		send_message(CONVERT_T);
		wait(1000000);
		init_1_wire();
		send_message(READ_SCRATCHPAD);
		wait(1);
		temp = read_value();
		sprintf(buffer, "%f.4 C\r\n", temp);
		print_string(buffer);
	}
}

int init_1_wire()
{
	change_pin_direction(false);
	set_gpio_state(false);
	wait(500);
	change_pin_direction(true);
	wait(100);
	if (((LPC_GPIO0->FIOSET0 >> 21) & 1))
	{
		print_string("1-Wire init error\r\n");
		return (-1);
	}

	wait(500);

	send_message(SKIP_ROM);

	return (0);
}

void init_gpio()
{

	LPC_PINCON->PINSEL1 &= (3 << 11);
	LPC_PINCON->PINSEL1 |= (1 << 11);
}

void init_UART()
{

	uint8_t LCR = 3 | (1 << 2) | (1 << 7);
	LPC_PINCON->PINSEL0 = (5 << 4);
	LPC_UART0->LCR = LCR;
	LPC_UART0->DLL = 10;
	LPC_UART0->DLM = 0;
	LPC_UART0->FDR = 5 | (14 << 4);
	LPC_UART0->LCR = 3 | (1 << 2);
}

void print_string(const char *str)
{
	char const *pointer = str;

	while (*pointer != '\0')
	{
		if (!(LPC_UART0->LSR & 32))
		{
			wait(10000);
			continue;
		}

		LPC_UART0->THR = *pointer;
		pointer++;
	}
}

void wait(uint32_t time)
{
	timer_done = false;
	// f_pclk = 25 000 000;
	LPC_TIM0->PR = 24; // prescaler
	LPC_TIM0->TC = 0;
	LPC_TIM0->MR0 = time;
	// funkcje progu MR0
	LPC_TIM0->MCR |= (1 << 1) | (1 << 0);
	// zerowanie
	// przerwanie
	NVIC_EnableIRQ(TIMER0_IRQn);
	// wlaczenie timera
	LPC_TIM0->TCR |= 1;

	while (!timer_done)
		;
}

void TIMER0_IRQHandler(void)
{
	LPC_TIM0->TC = 0;
	LPC_TIM0->IR = 1;
	timer_done = true;
}

void change_pin_direction(bool input)
{

	if (input)
		LPC_GPIO0->FIODIR0 &= ~(1 << 21);
	else
		LPC_GPIO0->FIODIR0 |= (1 << 21);
}

void set_gpio_state(bool high)
{

	if (high)
		LPC_GPIO0->FIOSET0 |= (1 << 21);
	else
		LPC_GPIO0->FIOSET0 &= ~(1 << 21);
}

void send_0()
{

	change_pin_direction(false);
	set_gpio_state(false);
	wait(100);
	change_pin_direction(true);
	wait(2);
}

void send_1()
{

	change_pin_direction(false);
	set_gpio_state(false);
	wait(1);
	set_gpio_state(true);
	wait(30);
}

bool read_message()
{
	bool bit;

	change_pin_direction(false);
	set_gpio_state(false);
	wait(1);
	change_pin_direction(true);
	wait(1);

	bit = (LPC_GPIO0->FIOSET0 >> 21) & 1;
	wait(45);

	return (bit);
}

void send_message(uint8_t val)
{
	for (int i = 0; i < 8; i++)
	{
		if (val & i)
			send_1();
		else
			send_0();
	}
}

float read_value()
{
	uint8_t val;
	float decimal;

	val = 0;

	for (int i = 0; i < 4; i++)
		val |= read_message() << i;

	decimal = ((float)val / (1 << 4));
	val = 0;

	for (int i = 0; i < 8; i++)
	{
		val |= read_message() << i;
	}

	return val + decimal;
}