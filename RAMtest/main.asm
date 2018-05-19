;
; RAMtest.asm
;
; Created: 5/3/2018 7:22:57 PM
; Author : Vador
;


; include definition file of ATmega328P
.include "m328pdef.inc"

.def REG1 = R17
.def REG2 = R18
.equ addr1 = 0x0100
.equ addr2 = 0x0101

.org 0x0000
	rjmp init


init:
	; led for debugging	
	sbi DDRC,2
	sbi DDRC,3
	sbi PORTC,2
	sbi PORTC,3

	ldi REG1, 1
	ldi REG2, 2

	ldi XH, HIGH(addr1)
	ldi XL, LOW(addr1)
	st X, REG1

	ldi YH, HIGH(addr2)
	ldi YL, LOW(addr2)
	st Y, REG2

	rjmp main

main:
	ld REG1, X
	add REG1, REG2
	st Y, REG1

	ld REG2, Y
	mul REG2, REG1
	breq ledOn
	rjmp loop

ledOn:
	cbi PORTC,2
	rjmp loop

loop:
	rjmp loop