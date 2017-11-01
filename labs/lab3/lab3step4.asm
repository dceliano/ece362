; ECE 362 Lab 3 - Fall 2014 - Step 4

; Name: < enter name here >

; Lab: < enter lab division here >

; Class Number: < enter class number here >

; Use Code Warrior (CW) in Full Chip Simulation mode

;***********************************************************************
; Write a subroutine "minmax" that searches the array of UNSIGNED 16-bit
; words passed to it by name, and returns the MINIMUM and MAXIMUM values
; via the stack. The minimum array length that needs to be handled is
; 2 words and the maximum array length is 100 words.
;
; At entry to "minmax", the stack content is as follows (note that the
; calling program allocates space on the stack for MINVAL and MAXVAL,
; and initializes these to $0000):
;
;      +--------------------+
; SP ->| return address - H |
;      +--------------------+
;      | return address - L |
;      +--------------------+
;      | number of elements |
;      +--------------------+
;      | array pointer - H  |
;      +--------------------+
;      | array pointer - L  |
;      +--------------------+
;      |   00 (maxval - H)  |
;      +--------------------+
;      |   00 (maxval - L)  |
;      +--------------------+
;      |   00 (minval - H)  |
;      +--------------------+
;      |   00 (minval - L)  |
;      +--------------------+
;
; Just prior to exit from "minmax", the stack content is as follows:
;
;      +--------------------+
; SP ->| return address - H |
;      +--------------------+
;      | return address - L |
;      +--------------------+
;      |    <don't care>    |
;      +--------------------+
;      | array pointer - H  |
;      +--------------------+
;      | array pointer - L  |
;      +--------------------+
;      |     maxval - H     |
;      +--------------------+
;      |     maxval - L     |
;      +--------------------+
;      |     minval - H     |
;      +--------------------+
;      |     minval - L     |
;      +--------------------+
;
;***********************************************************************
;
; To test and auto-grade your solution:
;	- Use CodeWarrior to assemble your code and launch the debugger
;	- Load the Auto-Grader (L3AG-4.s19) into the debugger
;		> Choose File -> Load Application
;		> Change the file type to "Motorola S-Record (*.s*)"
;		> Navigate to the 'AutoGrade' folder within your project
;		> Open 'L3AG-4.s19'
; - Open and configure the SCI terminal as a debugger component
;	- Start execution at location $800
;
; The score displayed is the number of test cases your code has passed.
; If nothing is displayed (i.e., your code "crashes"), no points will be
; awarded - note that there is no way to "protect" the application that
; tests your code from stack errors inflicted by mistakes in your code.
;
; Also note: If the message "STACK CREEP!" appears, it means that the
; stack has not been handled correctly (e.g., more pushes than pops or
; data passed to it not de-allocated correctly). 
;
;***********************************************************************

	org	$A00	; DO NOT REMOVE OR MODIFY THIS LINE

; Place your code for "minmax" below

  jsr minmax

minmax
loop_begin
         pulx         ; pull the return address off the stack and put it into x
         pula         ; pull the num elements off the stack and put it into a - this is the # of iterations to do
         puly         ; pull the array pointer off the stack and put it into y
         
do_loop     
         ; pull off the current maxval and store it in a register - this register will always hold the maxval
         ; compare the current value of the array with maxval
         ; if currentval > maxval, then put currentval into the register
         ; pull off the current minval and put in a (different) register that will always hold the minval
         ; compare them
         ; if currentval < minval, put currentval into the register
         ; push minval register onto the stack
         ; push maxval register onto the stack
         
         dbne a,do_loop ; do this loop until we reach the end of the array    


         
loop_end
         pshy ;push the ORIGINAL array index
         pshx ; push the return address


        rts

	end
