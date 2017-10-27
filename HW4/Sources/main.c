#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */



void main(void) {
  /* put your own code here */
  
  unsigned int i;
unsigned int j;
unsigned int n;
i=0;
n=5;
do {
j=(i++)%n;
} while(i<20);

	EnableInterrupts;


  for(;;) {
    _FEED_COP(); /* feeds the dog */
  } /* loop forever */
  /* please make sure that you never leave main */
}
