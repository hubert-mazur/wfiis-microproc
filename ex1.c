#include "Board_LED.h"                  // ::Board Support:LED
#include "LPC17xx.h"                    // Device header
#include "Board_Buttons.h"              // ::Board Support:Buttons

#define UART_DLL 0x4000C000
#define UART_FDR 0x4000C028

#define UART_MSB 
#define UART_LSB 



volatile uint32_t msTicks = 0;

void wait(int ms);
void print_string(const char *str);

void SysTick_Handler(void)
{
		msTicks++;
}

int main()
{
	int error;
	int no_leds;
	char counter = (char) 20;
	char read;
	
	Buttons_Initialize();
	
	//no_leds = LED_GetCount();
	//error = LED_Initialize();
	uint8_t LCR = 3 | (1<<2) | (1<<7);
	
	LPC_UART0->LCR = LCR;
	LPC_UART0->DLL = 10;
	LPC_UART0->DLM = 0;
	LPC_UART0->FDR = 5 | ( 14 << 4);
	
	LPC_UART0->LCR = 3 | (1<<2);

	error = SysTick_Config(SystemCoreClock / 1000);
	
	while (1) {
	//for (int i=0; i< no_leds;i++)
		//LED_Off(i);
		
	//for (int i=0;i< no_leds;i++) {
	//	LED_On(i);
//wait(500);
//	}
	
		LPC_PINCON->PINSEL0 = (5 << 4);
		//LPC_UART0->THR = 'a';
		//wait(200);
		//counter++;
		//LPC_PINCON->PINSEL0 = (LPC_PINCON->PINSEL0 & (~ (5 << 4)));
	
		//while (!(LPC_UART0->LSR & 1));
		//read = LPC_UART0->RBR & 255;
		//LPC_UART0->THR = ++read;
		
		print_string("Hello World Hello World Hello World Hello World!\r\n");
		
		if (Buttons_GetState() & (1))
			print_string("Button 2 pressed\r\n");
	}
}

void wait(int ms)
{
		msTicks = 0;
	
		while (msTicks < ms);
		return;
}

void print_string(const char *str)
{
		char const *pointer = str;
	
		while (*pointer != '\0')
		{
				if (!(LPC_UART0->LSR & 32)) {
					wait(10);
					continue;
				}
				
				LPC_UART0->THR = *pointer;
				pointer++;
		}
}
