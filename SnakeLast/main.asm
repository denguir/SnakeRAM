;
; Snake.asm
;
; Created: 4/22/2018 12:09:48 PM
; Author : Vador
;

; define registers:

.def COUNTER_POS = R17
.def RANDOM_POS = R18
.def POS_Y = R19
.def POS_X = R20
.def V = R21 
.def COUNTER_MOVE = R22
.def LENGTH = R23
.def GAME_STATE = R24 ; 0: game over, 1: pause, 2: playing
.def SYMBOL = R25
; R26 -> R29 used as pointers X and Y

; define constants:
; timer counters
.equ COUNTER_OFFSET = 206
.equ COUNTER_OFFSET_MOVE_L = 0xE6
.equ COUNTER_OFFSET_MOVE_H = 0xF9

; map size
.equ X_MAX = 79
.equ Y_MAX = 6

; initial length of snake
.equ INIT_LENGTH = 3

; define head SRAM addresses
.equ HEADXADDR = 0x0100
.equ HEADYADDR = 0x0101

; define fruit SRAM addresses
.equ FRUITXADDR = 0x0200
.equ FRUITYADDR = 0x0201

; define past fruit SRAM addresses (for Random generator)
.equ FRUITXADDR2 = 0x0202
.equ FRUITYADDR2 = 0x0203


; begin program
.org 0x0000
	rjmp init
.org 0x001A
	rjmp ISRmove

; include definition file of ATmega328P
.include "m328pdef.inc"

; include important functions
.include "Keyboard.inc"
.include "Move.inc"
.include "Display.inc"
.include "Rules.inc"
.include "RandomGen.inc"

init:
	; config pins
	rcall configDispPin
	rcall configRowKb
	rcall configDebugLed
	
	; set all Snake initial conditions 
	rcall initialConditions

	; config display timer 
	ldi R16,COUNTER_OFFSET 
	out TCNT0,R16 ; set counter init
	ldi R16,0b0000_0011 ; set prescaler to 64 (COUNTER_OFFSET = 206 -> f = 5kHz)
	out TCCR0B,R16 ; timer is configured with prescaler 
	;(timer begins)

	; config ISR timer for periodic motion
	sei ; set the global interrupt flag
	ldi R16,0b0000_0001 ; register for ISR config
	sts TIMSK1, R16 ; enable ISR for timer 1
	ldi R16, COUNTER_OFFSET_MOVE_H
	sts TCNT1H,R16
	ldi R16, COUNTER_OFFSET_MOVE_L
	sts TCNT1L,R16 ; set counter init
	ldi R16,0b0000_0101 ; set prescaler to 1024
	sts TCCR1B,R16 ; timer is configured with prescaler 
	;(timer begins)

	rcall KApressed ; automatically push the key A to begin the game 
	rjmp main

main:
	rcall checkKeyboard
	cpi GAME_STATE, 0
	breq game_over
	play:
		rcall checkRules
		;rcall move ;in ISR
		rcall display
		rjmp main

	game_over:
		rcall displayGameOver
		rjmp main
	rjmp main


ISRmove:
	;cbi PORTC,2 ; switch led 2
	rcall move
	ldi R16, COUNTER_OFFSET_MOVE_H
	sts TCNT1H,R16
	ldi R16, COUNTER_OFFSET_MOVE_L
	sts TCNT1L,R16
	reti


configRowKb:
	ldi R16, 0b1111_0000 ; 4 row output mode, 4 col input mode
	out DDRD, R16
	ldi R16, 0b0000_1111 ; rows -> low, cols -> enable pull up resistors
	out PORTD, R16
	ret

configDispPin:
	sbi DDRB,3
	cbi PORTB,3
	sbi DDRB,4
	cbi PORTB,4
	sbi DDRB,5
	cbi PORTB,5
	ret

configDebugLed:
	sbi DDRB,1 ; buzzer configured as output
	sbi DDRC,2
	sbi DDRC,3
	sbi PORTC,2
	sbi PORTC,3
	ret

initialConditions:
	; initial game state
	ldi GAME_STATE, 2 ; play 
	; initial length
	ldi LENGTH, INIT_LENGTH

	; head position initial
	ldi POS_X, 52
	ldi POS_Y, 2
	sts HEADXADDR, POS_X 
	sts HEADYADDR, POS_Y

	; head position initial
	ldi POS_X, 51
	ldi POS_Y, 2
	sts 0x0102, POS_X
	sts 0x0103, POS_Y

	; head position initial
	ldi POS_X, 50
	ldi POS_Y, 2
	sts 0x0104, POS_X
	sts 0x0105, POS_Y

	; fruit position initial
	ldi POS_X, 30
	ldi POS_Y, 2
	sts FRUITXADDR2, POS_X
	sts FRUITYADDR2, POS_Y

	; initial direction -> none
	ldi V, 0b0000_0001
	ret