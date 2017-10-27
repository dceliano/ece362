// ***********************************************************************
//  ECE 362 - Experiment 6 - Fall 2014     
//
// Dual-channel LED bar graph display                    
// ***********************************************************************
//	 	   			 		  			 		  		
// Completed by: < Dominic Celiano >
//               < 0617-C >
//               < Lab 9 >
//
//
// Academic Honesty Statement:  In entering my name above, I hereby certify
// that I am the individual who created this HC(S)12 source file and that I 
// have not copied the work of any other student (past or present) while 
// completing it. I understand that if I fail to honor this agreement, I will 
// receive a grade of ZERO and be subject to possible disciplinary action.
//
// ***********************************************************************

#include <hidef.h>           /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */
#include <mc9s12c32.h>

// All funtions after main should be initialized here

// Note: inchar and outchar can be used for debugging purposes

char inchar(void);
void outchar(char x);
			 		  		
//  Variable declarations  	   			 		  			 		       
int tenthsec = 0;  // one-tenth second flag
int leftpb = 0;    // left pushbutton flag
int rightpb = 0;    // right pushbutton flag
int runstp = 0;    // run/stop flag                         
int rticnt = 0;    // RTICNT (variable)
int prevpb = 0;    // previous state of pushbuttons (variable)
int bgd0[5]; // 5-int array to control bgd (bar graph display) 0
int bgd1[5]; // 5-int array to control bgd 1	
int THRESH1, THRESH2, THRESH3, THRESH4, THRESH5;
int i = 0;	
// Initializations
 
void  initializations(void) {

// Set the PLL speed (bus clock = 24 MHz)

  		CLKSEL = CLKSEL & 0x80; // disengage PLL from system
  		PLLCTL = PLLCTL | 0x40; // turn on PLL
  		SYNR = 0x02;            // set PLL multiplier
  		REFDV = 0;              // set PLL divider
  		while (!(CRGFLG & 0x08)){  }
  		CLKSEL = CLKSEL | 0x80; // engage PLL
  
// Disable watchdog timer (COPCTL register)

      COPCTL = 0x40;    //COP off - RTI and COP stopped in BDM-mode

// Initialize asynchronous serial port (SCI) for 9600 baud, no interrupts

      SCIBDH =  0x00; //set baud rate to 9600
      SCIBDL =  0x9C; //24,000,000 / 16 / 156 = 9600 (approx)  
      SCICR1 =  0x00; //$9C = 156
      SCICR2 =  0x0C; //initialize SCI for program-driven operation
         
//  Initialize Port AD pins 7 and 6 for use as digital inputs

	    DDRAD = 0; 		//program port AD for input mode
      ATDDIEN = 0xC0; //program PAD7 and PAD6 pins as digital inputs
         
//  Add additional port pin initializations here  (e.g., Other DDRs, Ports) 
      DDRT = 0xFF; //set pins as outputs
      PTT_PTT0 = 0;
      PTT_PTT1 = 0;

      ATDCTL2 = 0x80; 
      ATDCTL3 = 0x10;
      ATDCTL4 = 0x85;
      ATDCTL5 = 0x10;
      
      ATDCTL2_AFFC = 1; //fast flag clear mode 
      

//  Define bar graph segment thresholds (THRESH1..THRESH5)
//  NOTE: These are binary fractions (ranging from $00 to $FF)
      THRESH1 = 0x2B; // 0.85 V
      THRESH2 = 0x55; // 1.70 V
      THRESH3 = 0x80; // 2.55 V
      THRESH4 = 0xAA; // 3.40 V
      THRESH5 = 0xD5; // 4.25 V

//  Add RTI/interrupt initializations here
      CRGINT = 0x80;
      RTICTL = 0x39;  // RTI will occur every 5.12 ms (Modulus of 10, Pre-Scalar of 12: x0111001  , rticnt = 19.5 for .1s)

}
	 		  			 		  		
 
// Main (non-terminating loop)
 
void main(void) {
	initializations(); 		  			 		  		
	EnableInterrupts;


  for(;;) {

// Main program loop (state machine)
// Start of main program-driven polling loop

      if (tenthsec){  //  If the "tenth second" flag is set, then
        tenthsec = 0; //    - clear the "tenth second" flag
        if(runstp){   //    - if "run/stop" flag is set, then
          ATDCTL5 = 0x10; //  starts a new conversion and uses scan mode (continuous conversion)  - initiate ATD coversion sequence
          while (ATDSTAT0_SCF == 0){
            //wait for the conversion to finish (the SCF flag to be set to 1)
          }
          // now, the conversion is complete.
          
          // read the values from each register, compare it to the thresholds, and set the LED output accordingly
          //ATDDR0H is the analog input from analog channel 0 (converted)
          //ATDDR1H is the analog input from analog channel 1 (converted)
          
          // analog channel 0 being used to determine LED outputs
          if (ATDDR0H < THRESH1){
             // set 00000
             bgd0[0] = 0;
             bgd0[1] = 0;
             bgd0[2] = 0;
             bgd0[3] = 0;
             bgd0[4] = 0;
          }
          if (ATDDR0H >= THRESH1 && ATDDR0H < THRESH2){
             // set 00001
             bgd0[0] = 0;
             bgd0[1] = 0;
             bgd0[2] = 0;
             bgd0[3] = 0;
             bgd0[4] = 1;
          }
          if (ATDDR0H >= THRESH2 && ATDDR0H < THRESH3){
             // set 00011
             bgd0[0] = 0;
             bgd0[1] = 0;
             bgd0[2] = 0;
             bgd0[3] = 1;
             bgd0[4] = 1;
          }
          if (ATDDR0H >= THRESH3 && ATDDR0H < THRESH4){
             // set 00111
             bgd0[0] = 0;
             bgd0[1] = 0;
             bgd0[2] = 1;
             bgd0[3] = 1;
             bgd0[4] = 1;
          }
          if (ATDDR0H >= THRESH4 && ATDDR0H < THRESH5){
             // set 01111
             bgd0[0] = 0;
             bgd0[1] = 1;
             bgd0[2] = 1;
             bgd0[3] = 1;
             bgd0[4] = 1;
          }
          if (ATDDR0H >= THRESH5){
             // set 11111
             bgd0[0] = 1;
             bgd0[1] = 1;
             bgd0[2] = 1;
             bgd0[3] = 1;
             bgd0[4] = 1;
          }
          
          // analog channel 1
          if (ATDDR1H < THRESH1){
             // set 00000
             bgd1[0] = 0;
             bgd1[1] = 0;
             bgd1[2] = 0;
             bgd1[3] = 0;
             bgd1[4] = 0;
          }
          if (ATDDR1H >= THRESH1 && ATDDR1H < THRESH2){
             // set 00001
             bgd1[0] = 0;
             bgd1[1] = 0;
             bgd1[2] = 0;
             bgd1[3] = 0;
             bgd1[4] = 1;
          }
          if (ATDDR1H >= THRESH2 && ATDDR1H < THRESH3){
             // set 00011
             bgd1[0] = 0;
             bgd1[1] = 0;
             bgd1[2] = 0;
             bgd1[3] = 1;
             bgd1[4] = 1;
          }
          if (ATDDR1H >= THRESH3 && ATDDR1H < THRESH4){
             // set 00111
             bgd1[0] = 0;
             bgd1[1] = 0;
             bgd1[2] = 1;
             bgd1[3] = 1;
             bgd1[4] = 1;
          }
          if (ATDDR1H >= THRESH4 && ATDDR1H < THRESH5){
             // set 01111
             bgd1[0] = 0;
             bgd1[1] = 1;
             bgd1[2] = 1;
             bgd1[3] = 1;
             bgd1[4] = 1;
          }
          if (ATDDR1H >= THRESH5){
             // set 11111
             bgd1[0] = 1;
             bgd1[1] = 1;
             bgd1[2] = 1;
             bgd1[3] = 1;
             bgd1[4] = 1;
          }
          
          //       - transmit 10-bit data to external shift register
          //controlling bgd0 
          for (i = 0; i < 5; i++){
              PTT_PTT4 = 1; // set the clock high
              PTT_PTT3 = bgd0[i];
              PTT_PTT4 = 0; //set the clock low to shift the shift register, thereby pushing out the bit of data
          }
          //controlling bgd1
          for (i = 0; i < 5; i++){
              PTT_PTT4 = 1; // set the clock high
              PTT_PTT3 = bgd1[i];
              PTT_PTT4 = 0; //set the clock low to shift the shift register, thereby pushing out the bit of data
          }
          
          
        }
      }

      if(leftpb){     //  If the left pushbutton ("stop BGD") flag is set, then:
         leftpb = 0;  //    - clear the left pushbutton flag
         runstp = 0;  //    - clear the "run/stop" flag (and "freeze" BGD)
         PTT_PTT1 = 1;     //    - turn on left LED/turn off right LED (on docking module)
         PTT_PTT0 = 0;
      }
      	 	   			 		  			 		  		
         			 		  			 		  		
      if(rightpb){     //  If the right pushbutton ("start BGD") flag is set, then
          rightpb = 0; //    - clear the right pushbutton flag 
          runstp = 1;  //    - set the "run/stop" flag (enable BGD updates)
          PTT_PTT1 = 0;     //    - turn off left LED/turn on right LED (on docking module)
          PTT_PTT0 = 1;
      }               
      	 	   			 		  			 		  		

  } /* loop forever */
  
}  /* make sure that you never leave main */



// ***********************************************************************                       
// RTI interrupt service routine: rti_isr
//
//  Initialized for 5-10 ms (approx.) interrupt rate - note: you need to
//    add code above to do this
//
//  Samples state of pushbuttons (PAD7 = left, PAD6 = right)
//
//  If change in state from "high" to "low" detected, set pushbutton flag
//     leftpb (for PAD7 H -> L), rghtpb (for PAD6 H -> L)
//     Recall that pushbuttons are momentary contact closures to ground
//
//  Also, keeps track of when one-tenth of a second's worth of RTI interrupts
//     accumulate, and sets the "tenth second" flag         	   			 		  			 		  		
 
interrupt 7 void RTI_ISR( void)
{
  	CRGFLG = CRGFLG | 0x80;  // set CRGFLG bit to clear RTI interrupt flag
  	
  	// increment RTICNT, but only if the program is running
  	if (runstp){
    	rticnt++;
    	if(rticnt >= 19){
    	  tenthsec = 1; // a tenth of a second has passed
    	  rticnt = 0; //reset rticnt
    	}
  	}
  	
	  if (prevpb && !PORTAD0_PTAD7){ // if leftpb was pressed
	     leftpb = 1;	     
	  }
	  prevpb = PORTAD0_PTAD7;
	  
	  if (prevpb && !PORTAD0_PTAD6){ // if rightpb was pressed
	     rightpb = 1;	     
	  }
	  prevpb = PORTAD0_PTAD6;
	  
}


// ***********************************************************************
// Character I/O Library Routines for 9S12C32 (for debugging only)
// ***********************************************************************
// Name:         inchar
// Description:  inputs ASCII character from SCI serial port and returns it
// ***********************************************************************
char  inchar(void) {
  /* receives character from the terminal channel */
        while (!(SCISR1 & 0x20)); /* wait for RDR input */
    return SCIDRL;
 
}

// ***********************************************************************
// Name:         outchar
// Description:  outputs ASCII character passed in outchar()
//                  to the SCI serial port
// ***********************************************************************/
void outchar(char ch) {
  /* transmits a character to the terminal channel */
    while (!(SCISR1 & 0x80));  /* wait for TDR empty */
    SCIDRL = ch;
}