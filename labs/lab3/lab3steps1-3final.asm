1:


; ECE 362 Lab 3 - Fall 2014 - Step 1

; Name: < enter name here >

; Lab: < enter lab division here >

; Class Number: < enter class number here >

; Use Code Warrior (CW) in Full Chip Simulation mode

;***********************************************************************
;
; Write a REENTRANT subroutine "findc" that counts the number of instances
; of a specified (ASCII) character in the string that is passed to it.
; Recall that a reentrant subroutine does not use any global variables
; (i.e., any local variables utilized should be allocated on the stack.
;
; At entry, the (ASCII) character to match along with the string to search
; is passed via the stack, as shown; assume the string terminates with the
; ASCII NULL character (the string can be any length up to 255 characters).
;
; At exit, the number of instances of the specified character is returned
; via the stack (as an unsigned 8-bit binary number) in place of the character
; that was matched (the string should be deallocated from the stack).
;
; At entry:
;
;      +--------------------+
; SP ->| return address - H |
;      +--------------------+
;      | return address - L |
;      +--------------------+
;      | character to match |
;      +--------------------+
;      | string - firstchar |
;      +--------------------+
;      |       char         |
;      +--------------------+
;      |       char         |
;      +--------------------+
;      | string - lastchar  |
;      +--------------------+
;      |     ASCII NULL     |
;      +--------------------+
;
;
; Just prior to exit:
;
;      +--------------------+
; SP ->| return address - H |
;      +--------------------+
;      | return address - L |
;      +--------------------+
;      | number of matches  |
;      +--------------------+
;
;***********************************************************************
;
; To test and auto-grade your solution:
;	- Use CodeWarrior to assemble your code and launch the debugger
;	- Load the Auto-Grader (L3AG-1.s19) into the debugger
;		> Choose File -> Load Application
;		> Change the file type to "Motorola S-Record (*.s*)"
;		> Navigate to the 'AutoGrade' folder within your project
;		> Open 'L3AG-1.s19'
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

; Place your code for "findc" below


findc
loopbegin
         pulx         ; pull the return address off the stack and put it into x
         pula         ; pull the char to match off the stack and put it into a
         ldab #$00    ; set the b accumulator to 0 (it will be used to count the # of matches)
         
charcheckloop 
         stab b_count       ; temporarily store b
         pulb               ; pull an ascii char off the stack and put it into b
         cmpb  #$00         ; test to see if the ascii char is NULL ($00)
         beq  loopend       ; if it is, finish the subroutine
         stab  charloc      ; if not, store the ascii value in memory
         ldab b_count       ; put the old value of b back into the b accumulator
         cmpa charloc       ; and compare it to the char to match.
         beq  addone        ; if they are equal, add 1 to b
         bra  charcheckloop 
         
loopend
         psha             ; push the number of matches (b) onto the stack
         pshx             ; push the return address (x) onto the stack
	       rts
	       
addone
         addb #$1
         bra charcheckloop	 
               
charloc rmb 2
b_count rmb 1

	end


2:

; ECE 362 - Lab 3 - Step 2

; Name: < enter name here >

; Lab: < enter lab division here >

; Class Number: < enter class number here >

; Use Code Warrior (CW) in Full Chip Simulation mode

;***********************************************************************
;
; Write a REENTRANT subroutine "popcnt" that counts the number of bits
; that are "1" in the 16-bit word passed to it on the stack, and returns
; that value as an 8-bit unsigned integer on the stack.  Recall that a
; reentrant subroutine does not use any global variables (i.e., any local
; variables utilized should be allocated on the stack).
;
; Note that the result can range from $00 (16-bit word was $0000) to $10
; (16-bit word was $FFFF).
;
; Stack frame at entry:
;
;      +--------------------+
; SP ->| return address - H |
;      +--------------------+
;      | return address - L |
;      +--------------------+
;      |   data word - H    |
;      +--------------------+
;      |   data word - L    |
;      +--------------------+
;
;
; Stack frame just prior to exit:
;
;      +--------------------+
; SP ->| return address - H |
;      +--------------------+
;      | return address - L |
;      +--------------------+
;      | number of "1" bits |
;      +--------------------+
;
;***********************************************************************
;
; To test and auto-grade your solution:
;	- Use CodeWarrior to assemble your code and launch the debugger
;	- Load the Auto-Grader (L3AG-2.s19) into the debugger
;		> Choose File -> Load Application
;		> Change the file type to "Motorola S-Record (*.s*)"
;		> Navigate to the 'AutoGrade' folder within your project
;		> Open 'L3AG-2.s19'
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

; Place your code for "popcnt" below


popcnt

do_start
        pulx ; pull off the return address
        pula
        ldab #$0  ; initialize count as 0
        stab count ; store it at count
        
do_loop

        lsla ; push the left-most bit into the carry flag - this also 'increments' our number by shifting it left
        ldab count ; load value stored at count into b
        adcb #$0 ; add C + 0 + (b)
        stab count ; store the new count into the memory address count
        cmpa #$0  ; see if there are any more 1 bits in the number
        beq do_loop_2_begin
        bra do_loop
        
do_loop_2_begin
        pula
do_loop_2
        lsla ; push the left-most bit into the carry flag - this also 'increments' our number by shifting it left
        ldab count ; load value stored at count into b
        adcb #$0 ; add C + 0 + (b)
        stab count ; store the new count into the memory address count
        cmpa #$0  ; see if there are any more 1 bits in the number
        beq do_exit
        bra do_loop_2
              
do_exit
        ldab count
        pshb     
        pshx 
       

	rts   
	
count rmb 1

	end

3: 

; ECE 362 - Lab 3 - Step 3

; Name: < enter name here >

; Lab: < enter lab division here >

; Class Number: < enter class number here >

; Use Code Warrior (CW) in Full Chip Simulation mode

;***********************************************************************
; Write a subroutine "correl" that calculates the correlation between
; two 16-bit binary values, where the correlation is defined as the
; number of corresponding bit positions that are identical.
;
; At entry, the X and Y registers contain the two 16-bit operands;
; at exit, the B register contains the correlation value (which can
; range from $00 to $10).
;
; Examples:
;
; if   (X) = %10101010 01010101 = $AA55 and (Y) = %01010101 10101010 = $55AA
; then (B) = $00
;
; if   (X) = %11001100 11001100 = $CCCC and (Y) = %01010101 10101010 = $55AA
; then (B) = $08
;
; if   (X) = %00000000 00000000 = $0000 and (Y) = %00000000 00000000 = $0000
; then (B) = $10
;
;***********************************************************************
;
; To test and auto-grade your solution:
;	- Use CodeWarrior to assemble your code and launch the debugger
;	- Load the Auto-Grader (L3AG-3.s19) into the debugger
;		> Choose File -> Load Application
;		> Change the file type to "Motorola S-Record (*.s*)"
;		> Navigate to the 'AutoGrade' folder within your project
;		> Open 'L3AG-3.s19'
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

; Place your code for "correl" below

correl

start
        ldab #$0 ;initialize count as 0
        pshy
        pshx
x1_vs_y1
        ldaa 0,sp
        eora 2,sp  ; xor all of the bits of x1 with y1
        coma       ; complement all of the bits in a
        
do_loop1
        lsla ; push the left-most bit into the carry flag - this also 'increments' our number by shifting it left
        adcb #$0 ; add C + 0 + (b)
        cmpa #$0  ; see if there are any more 1 bits in the number
        beq x0_vs_y0
        bra do_loop1
        
x0_vs_y0
      ldaa 1,sp
      eora 3,sp  ;xor all of the bits of x0 with y0
      coma       ; complement all of the bits in a

do_loop2
        lsla ; push the left-most bit into the carry flag - this also 'increments' our number by shifting it left
        adcb #$0 ; add C + 0 + (b)
        cmpa #$0  ; see if there are any more 1 bits in the number
        beq exit
        bra do_loop2
              
exit 
        pulx
        puly
       

	rts   


	end