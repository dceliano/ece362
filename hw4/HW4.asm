; ECE 362 HW 4 - Fall 20145

; Name: < Dominic Celiano >

; #7. Pass it a memory location and a modulus, and it will return (memory location) + 1 % modulus
imodb		MACRO
		inc #\1
		ldx #\1
		clra
		ldab #\2 ; second value passed in is modulus
		idiv ; remainder stored in D
		stab #\1
		ENDM
	

org $900
memb rmb 1