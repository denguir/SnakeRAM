;
; Keyboard.inc
;
; Created: 5/19/2018 2:04:01 PM
; Author : Vador
;

updateDir:
	; 4 steps keyboard check
	rcall checkKeyboard
dirUpdated:
	ret

checkKeyboard:
	; check row 3
	sbi PORTD,6
	cbi PORTD,5
	sbi PORTD,7
	sbi PORTD,4
	nop

	sbis PIND,1
	rjmp K3pressed

	; check row 4
	cbi PORTD,4
	sbi PORTD,5
	sbi PORTD,6
	sbi PORTD,7
	nop

	sbis PIND,0
	rjmp KCpressed
	sbis PIND,1
	rjmp KBpressed
	sbis PIND,2
	rjmp K0pressed
	sbis PIND,3
	rjmp KApressed
	ret

NoKpressed:
	rjmp dirUpdated
	sbi PORTC,3
K0pressed:
	ldi V, 0b0000_1000 ; set direction to left
	cbi PORTC,3
	rjmp dirUpdated
K3pressed:
	ldi V, 0b0000_0100 ; set direction to up
	cbi PORTC,3
	rjmp dirUpdated
KBpressed:
	ldi V, 0b0000_0010 ; set direction to down
	cbi PORTC,3
	rjmp dirUpdated
KCpressed:
	ldi V, 0b0000_0001 ; set direction to right
	cbi PORTC,3
	rjmp dirUpdated
KApressed:
	; begin button
	lds RANDOM_POS, TCNT1L
	rcall randomXpos
	sts FRUITXADDR, RANDOM_POS
	lds RANDOM_POS, TCNT1H
	rcall randomYpos
	sts FRUITYADDR, RANDOM_POS
	ldi V, 0b0000_0001 ; start moving
	rjmp dirUpdated


