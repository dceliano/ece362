
/*
************************************************************************
 ECE 362 - Mini-Project C Source File - Fall 2015
***********************************************************************
     	   			 		  			 		  		
 Team ID: < Team 20 >

 Project Name: < ? >

 Team Members:

   - Team/Doc Leader: < Dom Celiano >      Signature: ______________________
   
   - Software Leader: < Iaman Alkhalaf>      Signature: ______________________

   - Interface Leader: < Trevor Bonesteel >     Signature: ______________________

   - Peripheral Leader: < John Mahony >    Signature: ______________________


 Academic Honesty Statement:  In signing above, we hereby certify that we 
 are the individuals who created this HC(S)12 source file and that we have
 not copied the work of any other student (past or present) while completing 
 it. We understand that if we fail to honor this agreement, we will receive 
 a grade of ZERO and be subject to possible disciplinary action.

***********************************************************************

 The objective of this Mini-Project is to .... < ? >


***********************************************************************

 List of project-specific success criteria (functionality that will be
 demonstrated):

 1.

 2.

 3.

 4.

 5.

***********************************************************************

  Date code started: < ? >

  Update history (add an entry every time a significant change is made):

  Date: < ? >  Name: < ? >   Update: < ? >

  Date: < ? >  Name: < ? >   Update: < ? >

  Date: < ? >  Name: < ? >   Update: < ? >


***********************************************************************
*/

#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */
#include <mc9s12c32.h>

/* All functions after main should be initialized here */
char inchar(void);
void outchar(char x);
void shiftout(char x);
void wait(void);
void lightled(int[]);
void bco(unsigned char x);

/* Variable declarations */

unsigned char star;
unsigned char service;
unsigned char food;
int select;
int send_to_recv;
int test;
unsigned char send;
int y;
int ready = 0;

#define TSIZE 4	// transmit buffer size (80 characters)
unsigned char tbuf[TSIZE];	// SCI transmit display buffer

#define SEQSIZE 12
int ledseq[SEQSIZE];  			 		  			 		       

/* Special ASCII characters */
#define CR 0x0D		// ASCII return 
#define LF 0x0A		// ASCII new line 

/* LCD COMMUNICATION BIT MASKS (note - different than previous labs) */
#define RS 0x10		// RS pin mask (PTT[4])
#define RW 0x20		// R/W pin mask (PTT[5])
#define LCDCLK 0x40	// LCD EN/CLK pin mask (PTT[6])

/* LCD INSTRUCTION CHARACTERS */
#define LCDON 0x0F	// LCD initialization command
#define LCDCLR 0x01	// LCD clear display command
#define TWOLINE 0x38	// LCD 2-line enable command
#define CURMOV 0xFE	// LCD cursor move instruction
#define LINE1  0x80	// LCD line 1 cursor position
#define LINE2  0xC0	// LCD line 2 cursor position

char tin	= 0;	// SCI transmit display buffer IN pointer
char tout	= 0;	// SCI transmit display buffer OUT pointer

	 	   		
/*	 	   		
***********************************************************************
 Initializations
***********************************************************************
*/

void  initializations(void) {

/* Set the PLL speed (bus clock = 24 MHz) */
  CLKSEL = CLKSEL & 0x80; //; disengage PLL from system
  PLLCTL = PLLCTL | 0x40; //; turn on PLL
  SYNR = 0x02;            //; set PLL multiplier
  REFDV = 0;              //; set PLL divider
  while (!(CRGFLG & 0x08)){  }
  CLKSEL = CLKSEL | 0x80; //; engage PLL

/* Disable watchdog timer (COPCTL register) */
  COPCTL = 0x40   ; //COP off; RTI and COP stopped in BDM-mode

/* Initialize asynchronous serial port (SCI) for 2400 baud, interrupts off initially */
  SCIBDH =  0x07; //set baud rate to 9600
  SCIBDL =  0x50; //24,000,000 / 16 / 156 = 9600 (approx)  
  SCICR1 =  0x10; //$9C = 156
  SCICR2 =  0x0C; //initialize SCI for program-driven operation
  DDRB   =  0x10; //set PB4 for output mode
  PORTB  =  0x10; //assert DTR pin on COM port



 /* initilize PWM ch3 */

  MODRR = 0x08;
  PWME = 0x08;
  PWMPOL = 0x08;  
  PWMCTL = 0x00;  
  PWMCAE = 0x00;  
  PWMPER3 = 0xFF; 
  PWMDTY3 = 0x00;
  PWMCLK = 0x00;  
  PWMPRCLK = 0x01;
  PWMSCLA = 0x00;
  PWMSCLB = 0x00;
  
  

//  Initialize Port AN pins 1 through 4 for use as digital inputs

	DDRAD = 0; 		//program port AN for input mode
  ATDDIEN = 0x1E; //program AN1 - AN4 pins as digital inputs

  /* Initilaize ATD 
        - will use port AN0
        - Conversion length = 1
  */
  ATDCTL2 = 0x80;
  ATDCTL3 = 0x08;
  ATDCTL4 = 0x85;
  
  ATDCTL5 = 0x30;
  DDRT = 0xFF;
  DDRM = 0xFF;
     
 /* Initialize the SPI to 6 Mbs */
  DDRM   = 0xFF;
  SPICR1 = 0x50;
  SPICR2 = 0x00;
  SPIBR  = 0x10;    
          
            
/* Initialize interrupts */

  CRGINT = 0x80;
  RTICTL = RTICTL | 0x27;	
  
  TSCR1 = 0x80;
  TSCR2 = 0x0C;
  TIOS = 0x80;
  TIE = 0x80;
  TC7 = 150;
	      
}

	 		  			 		  		
/*	 		  			 		  		
***********************************************************************
Main
***********************************************************************
*/
void main(void) {
  	DisableInterrupts
	initializations(); 		  			 		  		
	EnableInterrupts;
	test = 0;

 for(;;) {
  
/* < start of your main loop > */ 

     if (ready) {
      test++;
      ready = 0;
      bco(':');
      bco(food);
      bco(service);
      bco(star);
    }
       
  
   } /* loop forever */
   
}   /* do not leave main */




/*
***********************************************************************                       
 RTI interrupt service routine: RTI_ISR
************************************************************************
*/

interrupt 7 void RTI_ISR(void)
{
  	// clear RTI interrupt flagt 
  	CRGFLG = CRGFLG | 0x80; 

/* create a sequence of bit values using array for the values being ouput
   to the led shift register. The value in the array that is highest
   will be ouput onto the shift first (the service value) it will then
   be followed by the food value, then the star rating, followed by 
   the submit led value */

	    PTT_PTT0 = 0; //set column 1 low
      PTT_PTT1 = 1;
      PTT_PTT2 = 1;
      while(!PORTAD0_PTAD1 && !select){  //check if row 1 low
       star = '1'; //1 star
       ledseq[5] = 1;
       ledseq[4] = 0;
       ledseq[3] = 0;
       ledseq[2] = 0;
       ledseq[1] = 0;     
      }
      while(!PORTAD0_PTAD2 && !select){ //check if row 2 low
       star = '2'; //2 star
       ledseq[5] = 1;
       ledseq[4] = 1;
       ledseq[3] = 0;
       ledseq[2] = 0;
       ledseq[1] = 0;  
      }
      while(!PORTAD0_PTAD3 && !select){  //check if row 3 low
       star = '3';  //3 star
       ledseq[5] = 1;
       ledseq[4] = 1;
       ledseq[3] = 1;
       ledseq[2] = 0;
       ledseq[1] = 0;  
      }
      while(!PORTAD0_PTAD4 && !select){  //check if row 4 low
       star = '4';  //4 star
       ledseq[5] = 1;
       ledseq[4] = 1;
       ledseq[3] = 1;
       ledseq[2] = 1;
       ledseq[1] = 0;  
      }
      PTT_PTT0 = 1; //set column 1 high
      PTT_PTT1 = 0; //set column 2 low
      while(!PORTAD0_PTAD1 && !select){  //check if row 1 low
       star = '5';  //5 star
       ledseq[5] = 1;
       ledseq[4] = 1;
       ledseq[3] = 1;
       ledseq[2] = 1;
       ledseq[1] = 1;        
      }
      while(!PORTAD0_PTAD2 && !select){ //check if row 2 low
       service = '1';  //1 service
       ledseq[8] = 1;
       ledseq[7] = 0;
       ledseq[6] = 0;
      }
      while(!PORTAD0_PTAD3 && !select){  //check if row 3 low
       service = '2';  //2 service
       ledseq[8] = 0;
       ledseq[7] = 1;
       ledseq[6] = 0;
      }
      while(!PORTAD0_PTAD4 && !select){  //check if row 4 low
       service = '3';  //3 service
       ledseq[8] = 0;
       ledseq[7] = 0;
       ledseq[6] = 1;
      }
      PTT_PTT1 = 1; //set column 2 high
      PTT_PTT2 = 0; //set column 3 low
      while(!PORTAD0_PTAD1 && !select){  //check if row 1 low
       food = '1';  //1 food
       ledseq[11] = 1;
       ledseq[10] = 0;
       ledseq[9] = 0;
      }
      while(!PORTAD0_PTAD2 && !select){ //check if row 2 low
       food = '2';  //2 food
       ledseq[11] = 0;
       ledseq[10] = 1;
       ledseq[9] = 0;
      }
      while(!PORTAD0_PTAD3 && !select){  //check if row 3 low
       food = '3';  //3 food
       ledseq[11] = 0;
       ledseq[10] = 0;
       ledseq[9] = 1;
      }          
      while(!PORTAD0_PTAD4){
       select = 1;
       ledseq[0] = 1;
       lightled(ledseq);
       //send_to_recv = food + 10*service + 100*(star-1) ;
       //send = send_to_recv;//bco(send_to_recv); //transmit data to reciever
       ready = 1;
       PWMDTY3 = y;
      }
      PWMDTY3 = 0;
      lightled(ledseq);
      PTT_PTT2 = 1; //set column 3 high 
         
     
}

/*
***********************************************************************                       
  TIM interrupt service routine	  		
***********************************************************************
*/

interrupt 15 void TIM_ISR(void)
{
 // clear TIM CH 7 interrupt flag 
  TFLG1 = TFLG1 | 0x80;
  ATDCTL5 = 0x10;           // Start ATD !
  while(!ATDSTAT0_SCF){}
  
  y = ATDDR0H;
  

}


/*
***********************************************************************                       
  SCI interrupt service routine                                                   
***********************************************************************
*/

interrupt 20 void SCI_ISR(void)
{
    if ( SCISR1_TDRE == 1) {
    if ( tin == tout) {
      SCICR2_SCTIE = 0;
      
    }
      else {
        SCIDRL = tbuf[tout];
        //test = tbuf[tout];
        tout = (tout + 1) % TSIZE;
      }
    }
    
}
  
  /*if ( SCISR1_TDRE == 1) {
    SCIDRL = send;
    SCICR2_SCTIE = 0;

  
  }*/



/*
***********************************************************************   ††††   ††††  † ††††††   ††
  SCI buffered character output routine - bco

  Places character x passed to it into TBUF

   - check TBUF status: if FULL, wait for space; else, continue
   - place character in TBUF[TIN]
   - increment TIN mod TSIZE
   - enable SCI transmit interrupts

  NOTE: DO NOT USE OUTCHAR (except for debugging)
***********************************************************************
*/

void bco(unsigned char x)
{

  while(tout == (tin + 1) % TSIZE) {}
  tbuf[tin] = x;
  //send = x;
  tin = (tin + 1) % TSIZE;
  SCICR2_SCTIE = 1;

}


/*
***********************************************************************
  lightled: light leds on the shift register  
  
  PTT_PTT6 = dataout
  PTT_PTT5 = clock
              
***********************************************************************
*/
void lightled(int lightseq[]){
  int i;
  for(i = SEQSIZE - 1; i > -1; i--){
    PTT_PTT5 = lightseq[i];
    //clock the gal
    PTT_PTT6 = 1;
    PTT_PTT6 = 0;
    PTT_PTT6 = 1;
  }
}


/*
***********************************************************************
 Character I/O Library Routines for 9S12C32 
***********************************************************************
 Name:         inchar
 Description:  inputs ASCII character from SCI serial port and returns it
 Example:      char ch1 = inchar();
***********************************************************************
*/

char inchar(void) {
  /* receives character from the terminal channel */
        while (!(SCISR1 & 0x20)); /* wait for input */
    return SCIDRL;
}

/*
***********************************************************************
 Name:         outchar    (use only for DEBUGGING purposes)
 Description:  outputs ASCII character x to SCI serial port
 Example:      outchar('x');
***********************************************************************
*/

void outchar(char x) {
  /* sends a character to the terminal channel */
    while (!(SCISR1 & 0x80));  /* wait for output buffer empty */
    SCIDRL = x;
}