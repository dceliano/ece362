 ;***********************************************************************
; ECE 362 - Experiment 6 - Fall 2014
;***********************************************************************
;
; Completed by: < Dominic Celiano >
;               < 0617-C >
;               < Lab Div. 9 >
;
;
; Academic Honesty Statement:  In signing this statement, I hereby certify
; that I am the individual who created this HC(S)12 source file and that I 
; have not copied the work of any other student (past or present) while 
; completing it. I understand that if I fail to honor this agreement, I will 
; receive a grade ofZERO and be subject to possible disciplinary action.
;
;
; Signature: _____________________________________   Date: ____________
;
;       
;***********************************************************************
;
; The objective of this experiment is to implement a Big More-Than-Ten
; 19-second play clock on the 9S12C32 development kit.  A waveform
; generator will be used to provide a 100 Hz periodic interrupt. A
; GAL22V10 will be used to provide the requisite interfacing logic,
; which includes an interrupt device flag and a BCD-to-display-code
; decoder for driving a pair of common-anode 7-segment LEDs (see
; lab description document for details). Note that this application
; is intended to run in a "turn-key" fashion. 
;
; The following docking board resources will be used:
;
; - left pushbutton (PAD7): shot clock reset
; - right pushbutton (PAD6): shot clock start/stop
; - left LED (PT1): shot clock run/stop state
; - right LED (PT0): shot clock expired (00) state
;
; CAUTION: Be sure to set the DSO waveform generator output to produce a 
;          5 V peak-to-peak square wave with +2.5 V offset
;
;========================================================================
;
; MC68HC9S12C32 REGISTER MAP

INITRM	EQU	$0010	; INITRM - INTERNAL RAM POSITION REGISTER
INITRG	EQU	$0011	; INITRG - INTERNAL REGISTER POSITION REGISTER

; ==== CRG - Clock and Reset Generator

SYNR	  EQU	$0034	; CRG synthesizer register
REFDV 	EQU	$0035	; CRG reference divider register
CRGFLG	EQU	$0037	; CRG flags register
CRGINT	EQU	$0038
CLKSEL	EQU	$0039	; CRG clock select register
PLLCTL	EQU	$003A	; CRG PLL control register
RTICTL	EQU	$003B
COPCTL	EQU	$003C

; ==== PORT M

PTM	    EQU	$0250	; Port M data register (bit 3 will be used to clear device flag)
DDRM  	EQU	$0252	; Port M data direction register

; ==== Port AD - Digital Input (Pushbuttons)

PTAD    EQU     $0270   ; Port AD data register
DDRAD   EQU     $0272   ; Port AD data direction register
ATDDIEN	EQU	$008D	; Port AD digital input enable
			; (programs Port AD bit positions as digital inputs)

; ==== Port T - docking module LEDs and external PLD interface

PTT   	EQU	$0240	; Port T data register
DDRT	  EQU	$0242	; Port T data direction register

; ==== IRQ control register

IRQCR	EQU	$001E	; (will use default state out of reset) 

; ==== SCI Register Definitions

SCIBDH	EQU	$00C8	; SCI0BDH - SCI BAUD RATE CONTROL REGISTER
SCIBDL	EQU	$00C9	; SCI0BDL - SCI BAUD RATE CONTROL REGISTER
SCICR1	EQU	$00CA	; SCI0CR1 - SCI CONTROL REGISTER
SCICR2	EQU	$00CB	; SCI0CR2 - SCI CONTROL REGISTER
SCISR1	EQU	$00CC	; SCI0SR1 - SCI STATUS REGISTER
SCISR2	EQU	$00CD	; SCI0SR2 - SCI STATUS REGISTER
SCIDRH	EQU	$00CE	; SCI0DRH - SCI DATA REGISTER
SCIDRL	EQU	$00CF	; SCI0DRL - SCI DATA REGISTER

;***********************************************************************
;
; ASCII character definitions
;

CR	 equ	$0d	; RETURN
LF   equ  $0a ; LINE FEED

; ======================================================================
;
;  Variable declarations (SRAM)
;  Others may be added if deemed necessary


intcnt	equ	$3800	; number of IRQ interrupts accumulated
			          	; (set tenths flag when count reaches 10)
tenths	equ	$3801	; one-tenth second flag
leftpb	equ	$3802	; left pushbutton flag
rightpb	equ	$3803	; right pushbutton flag
runstp	equ	$3804	; run/stop flag

; Loading the play clock into memory
pclock  equ $3805

; used to help with interrupts
prevpb  equ $3808
crgflg  equ $3810



;***********************************************************************
;  BOOT-UP ENTRY POINT
;***********************************************************************

	org	$8000
startup	sei			; Disable interrupts
	movb	#$00,INITRG	; set registers to $0000
	movb	#$39,INITRM	; map RAM ($3800 - $3FFF)
	lds	#$3FCE		; initialize stack pointer

;
; Set the PLL speed (bus clock = 24 MHz)
;

	bclr	CLKSEL,$80	; disengage PLL from system
	bset	PLLCTL,$40	; turn on PLL
	movb	#$2,SYNR	; set PLL multiplier
	movb	#$0,REFDV	; set PLL divider
	nop
	nop
plp	brclr	CRGFLG,$08,plp	; while (!(crg.crgflg.bit.lock==1))
	bset	CLKSEL,$80	; engage PLL 

;
; Disable watchdog timer (COPCTL register)
;
	movb	#$40,COPCTL	; COP off; RTI and COP stopped in BDM-mode

;
; Initialize asynchronous serial port (SCI) for 9600 baud, no interrupts
; Note - for debugging use only
;
	movb	#$00,SCIBDH	; set baud rate to 9600
	movb	#$9C,SCIBDL	; 24,000,000 / 16 / 156 = 9600 (approx)
	movb	#$00,SCICR1	; $9C = 156
	movb	#$0C,SCICR2	; initialize SCI for program-driven operation


;***********************************************************************
;  START OF CODE FOR EXPERIMENT 6
;***********************************************************************
;
;  Flag and variable initialization (others may be added)
;
	clr	intcnt
	clr	tenths
	clr	leftpb
	clr	rightpb
	clr	runstp
 
;
;  Initialize Port AD for use as a digital input port (for pushbuttons)
;
	clr	DDRAD		; program port AD for input mode
	movb	#$C0,ATDDIEN	; program PTAD7 and PTAD6 pins as digital inputs

;
;  Initialize Port M to provide asynchronous reset to external device flag on bit 3
;
	bset	DDRM,$08		; configure pin 3 of Port M (PM3) as output signal
	bset	PTM,$08	; send active high clear pulse to external device flag
	bclr	PTM,$08	; return asynchronous clear signal to low state

;
;  < add any additional initialization code here >
;


	cli		; enable IRQ interrupts - last step before starting main loop
;
;  Start of main program-driven polling loop
;

; before we start the main loop, load the d accumulator
  ldd $0190
  std pclock ; store 19.0 seconds on the play clock

main

;  If the "tenth second" flag is set, then
;    - clear the "then second" flag
;    - If the "run/stop" flag is set, then
;      + decrement the play clock value (stored as packed 4-digit BCD number)
;      + update the 7-segment display
;        o if the time remaining is greater than or equal to 10 seconds,
;          display the tens and ones digits
;        o if the time remaining is less than 10 seconds but
;          greater than or equal to 1 second, blank the tens digit
;          and only display the ones digit
;        o if the time remaining is less than 1.0 second,
;          turn on the middle decimal point and display
;          the tenths digit instead of the ones digit
;          (starting with .9 and ending with .0)
;    - Endif
;  Endif

  ldaa tenths
  cmpa #1 ; if tenths flag is set
  bne endif1 ; don't do any of the code below if the flag isn't set
  clr tenths ; clear the tenths flag
  ldaa runstp
  cmpa #1 ; if the "run/stop" flag is set, then execute the code below
  bne endif1
  ;decrement the number
  ldd pclock
  exg a,b ; we need to add $99 to both bytes, but do so to the lower byte (b) first - so we exchange a and b
  adda $99
  daa
  exg a,b
  adda $99 ; add $99 to the upper byte now
  daa ; now, the BCD number is decremented
  ;update the display
  ldd pclock
  cpd $0100
  bge greaterthanten
  blt lessthanten
  
greaterthanten
    ldab pclock+1 ; load in the lower byte of pclock
    lsrb ; shift the register 4 to the right and then 4 left to get rid of the lower nibble we don't care about (since it is a decimal)
    lsrb
    lsrb
    lsrb
    lslb
    lslb
    lslb
    lslb
    addb $4 ; add 0100 to the b register so that PT2 will get set to 1 on the board
    bclr PTT, $FF ; clear all of the bits before setting them
    stab PTT ; write accumulator b to PTT
    bra endif1
    
lessthanten
    cpd $0010
    blt lessthanone
    ldab pclock+1 ; load in the lower byte of pclock
    lsrb ; shift the register 4 to the right and then 4 left to get rid of the lower nibble we don't care about (since it is a decimal)
    lsrb
    lsrb
    lsrb
    lslb
    lslb
    lslb
    lslb
    ; don't add anything this time (so that the tens digit bit stays low
    bclr PTT, $FF ; clear all of the bits before setting them
    stab PTT ; write accumulator b to PTT
    bra endif1 
    
lessthanone 
    ldab pclock+1
    lslb ; move the tenths digit 4 bits to the left
    lslb
    lslb
    lslb
    addb $8 ; add 1000 to the b register to set the PT3 bit to 1 (decimal point)
    bclr PTT, $FF ; clear all of the bits before setting them

endif1

  ;  If the left pushbutton ("reset play clock") flag is set, then:
  ;    - clear the left pushbutton flag
  ;    - clear the "run/stop" flag
  ;    - turn off both the "run/stop" and "time expired" LEDs
  ;    - reset the display to "19" 
  ;  Endif

  ldaa leftpb
  cmpa #1 ; if left pushbutton flag is set
  bne endif2
  clr leftpb
  clr runstp
  ldd $94 ;load it with $10010100 (9 in the left byte, with the PT2 set and PT1 and PT0 cleared).
endif2

  ;  If the right pushbutton ("start/stop") flag is set, then
  ;    - clear the right pushbutton flag
  ;    - toggle the "run/stop" flag
  ;    - toggle the "run/stop" LED (PT0)
  ;  Endif

  ldaa rightpb
  cmpa #1 ; if right pushbutton flag is set
  bne endif3
  clr rightpb
  com runstp ; toggle the flag
  ldab PTT
  eorb $01 ; toggle b
  stab PTT

endif3


  ;  If the play clock has reached ".0", then:
  ;    - clear the "run/stop" flag
  ;    - turn on the "time expired" LED
  ;    - turn off the "run/stop" LED
  ;  Endif

  ldd pclock
  cmpa #1
  bne endif4
  clr runstp
  bclr PTT, #$01 ; turn off PT0
  ldaa PTT
  oraa $02 ; turn on PT1
  staa PTT

endif4

	jmp	main	;  main is a while( ) loop with no terminating condition


;***********************************************************************
;
; IRQ interrupt service routine
;
;  External waveform generator produces 100 Hz IRQ interrupt rate
;
;  Use INTCNT to determine when 10 IRQ interrupts have accumulated 
;    -> set tenths flag and clear INTCNT to 0
;
;  Sample state of pushbuttons (PAD7 = left, PAD6 = right)
;  If change in state from "high" to "low" is detected, set pushbutton flag
;     leftpb (for PAD7 H -> L), rightpb (for PAD6 H -> L)
;     (pushbuttons are momentary contact closures to ground)
;

irq_isr


; < place your code for the IRQ interrupt service routine here >

; < be sure to clear external device flag by asserting bit 3 of Port M - see above >
;(asyronchornously cleared via port M, pin 3 - an output pin via the DDRM register)
; just increments the intcnt flag, which sets the tenths flag when it reaches 10
  ;***********************************************************************
  ; RTI interrupt service routine
  ;
  ; Keeps track of when 0.1 second of RTI interrupts has accumulated
  ; and sets tenths accordingly
  ;
  ; Also, samples state of pushbuttons (PTAD7 = left, PTAD6 = right)
  ; If change in state from "high" to "low" detected, set pushbutton flag
  ; leftpb (for PTAD7 H -> L), rightpb (for PTAD6 H -> L)
  ; Recall that pushbuttons are momentary contact closures to ground
  
rti_isr
  
  ; Using intcnt, track when 0.1 second of RTI interrupts have accumulated
  ; Set the "tenths" flag when this occurs and clear intcnt
  
  bset crgflg,$80
  brclr runstp,$01,chkpb
  inc intcnt
  ldaa intcnt
  cmpa #10 ; based on 10 ms interrupt rate
  blt chkpb
  clr intcnt
  movb #$01,tenths
  
  ; Check the pushbuttons for a change of state (compare previous with current)
  ; If no change detected, exit service routine
  
chkpb
  ldaa PTAD ; read current state of pushbuttons
  anda #$C0 ; mask off PTAD7 and PTAD6
  cmpa prevpb ; compare with previous PB state
  bne didchg ; if current state != previous state
  rti ; figure out which pushbutton involved
      ; else, exit with no change
  
  ; State of PB changed -- check if action necessary
  ; Note: Not considering case when both PBs pressed simultaneously
  
didchg
  psha ; save current state of PB
  
  ; If previous state of left PB was "H" and current state is "L"
  ; then set "leftpb" flag and proceed to exit; else, check right PB
  
chklft
  anda #$80 ; isolate current left PB
  eora #$80 ; complement current left PB
  psha
  ldab prevpb
  andb #$80 ; isolate previous left PB
  andb 1,sp+
  beq chkrgt ; if AND=0, left PB did not change from H->L so exit
  ; else, set leftpb flag
  movb #$01,leftpb
  bra rdone
  
  ; If previous state of right PB was "H" and current state is "L"
  ; then set "rightpb" flag and proceed to exit
  
chkrgt
  ldaa 0,sp ; reload current PB state
  anda #$40 ; isolate current right PB
  eora #$40 ; complement current right PB
  psha
  ldab prevpb
  andb #$40 ; isolate previous right PB
  andb 1,sp+
  beq rdone ; if AND=0, right PB did not change from H->L so exit
  ; else, set rightpb flag
  movb #$01,rightpb
  
  ; Since PB state changed, set PREVPB = current state read
  
rdone
  pula
  staa prevpb ; update PB state
  rti





;***********************************************************************
; Character I/O Library Routines for 9S12C32
;
; (these maay prove useful for testing and debugging but are otherwise
; not used for this application)
;***********************************************************************

rxdrf    equ   $20    ; receive buffer full mask pattern
txdre    equ   $80    ; transmit buffer empty mask pattern

;***********************************************************************
; Name:         inchar
; Description:  inputs ASCII character from SCI serial port
;                  and returns it in the A register
; Returns:      ASCII character in A register
; Modifies:     A register
;***********************************************************************

inchar  brclr  SCISR1,rxdrf,inchar
        ldaa   SCIDRL ; return ASCII character in A register
        rts

;***********************************************************************
; Name:         outchar
; Description:  outputs ASCII character passed in the A register
;                  to the SCI serial port
;***********************************************************************

outchar brclr  SCISR1,txdre,outchar
        staa   SCIDRL ; output ASCII character to SCI
        rts

;***********************************************************************
;
; Define 'where you want to go today' (reset and interrupt vectors) 
;
; If get a "bad" interrupt, just return from it

BadInt	rti

;
; ------------------ VECTOR TABLE --------------------
;

	org	$FF8A
	fdb	BadInt	;$FF8A: VREG LVI
	fdb	BadInt	;$FF8C: PWM emergency shutdown
	fdb	BadInt	;$FF8E: PortP
	fdb	BadInt	;$FF90: Reserved
	fdb	BadInt	;$FF92: Reserved
	fdb	BadInt	;$FF94: Reserved
	fdb	BadInt	;$FF96: Reserved
	fdb	BadInt	;$FF98: Reserved
	fdb	BadInt	;$FF9A: Reserved
	fdb	BadInt	;$FF9C: Reserved
	fdb	BadInt	;$FF9E: Reserved
	fdb	BadInt	;$FFA0: Reserved
	fdb	BadInt	;$FFA2: Reserved
	fdb	BadInt	;$FFA4: Reserved
	fdb	BadInt	;$FFA6: Reserved
	fdb	BadInt	;$FFA8: Reserved
	fdb	BadInt	;$FFAA: Reserved
	fdb	BadInt	;$FFAC: Reserved
	fdb	BadInt	;$FFAE: Reserved
	fdb	BadInt	;$FFB0: CAN transmit
	fdb	BadInt	;$FFB2: CAN receive
	fdb	BadInt	;$FFB4: CAN errors
	fdb	BadInt	;$FFB6: CAN wake-up
	fdb	BadInt	;$FFB8: FLASH
	fdb	BadInt	;$FFBA: Reserved
	fdb	BadInt	;$FFBC: Reserved
	fdb	BadInt	;$FFBE: Reserved
	fdb	BadInt	;$FFC0: Reserved
	fdb	BadInt	;$FFC2: Reserved
	fdb	BadInt	;$FFC4: CRG self-clock-mode
	fdb	BadInt	;$FFC6: CRG PLL Lock
	fdb	BadInt	;$FFC8: Reserved
	fdb	BadInt	;$FFCA: Reserved
	fdb	BadInt	;$FFCC: Reserved
	fdb	BadInt	;$FFCE: PORTJ
	fdb	BadInt	;$FFD0: Reserved
	fdb	BadInt	;$FFD2: ATD
	fdb	BadInt	;$FFD4: Reserved
	fdb	BadInt	;$FFD6: SCI Serial System
	fdb	BadInt	;$FFD8: SPI Serial Transfer Complete
	fdb	BadInt	;$FFDA: Pulse Accumulator Input Edge
	fdb	BadInt	;$FFDC: Pulse Accumulator Overflow
	fdb	BadInt	;$FFDE: Timer Overflow
	fdb	BadInt	;$FFE0: Standard Timer Channel 7
	fdb	BadInt	;$FFE2: Standard Timer Channel 6
	fdb	BadInt	;$FFE4: Standard Timer Channel 5
	fdb	BadInt	;$FFE6: Standard Timer Channel 4
	fdb	BadInt	;$FFE8: Standard Timer Channel 3
	fdb	BadInt	;$FFEA: Standard Timer Channel 2
	fdb	BadInt	;$FFEC: Standard Timer Channel 1
	fdb	BadInt	;$FFEE: Standard Timer Channel 0
	fdb	BadInt	;$FFF0: Real Time Interrupt (RTI)
	fdb	irq_isr	;$FFF2: IRQ (External Pin or Parallel I/O) (IRQ)
	fdb	BadInt	;$FFF4: XIRQ (Pseudo Non-Maskable Interrupt) (XIRQ)
	fdb	BadInt	;$FFF6: Software Interrupt (SWI)
	fdb	BadInt	;$FFF8: Illegal Opcode Trap ()
	fdb	startup	;$FFFA: COP Failure (Reset) ()
	fdb	BadInt	;$FFFC: Clock Monitor Fail (Reset) ()
	fdb	startup	;$FFFE: /RESET
	end