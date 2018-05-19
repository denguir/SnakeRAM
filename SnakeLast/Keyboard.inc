;
; Keyboard.inc
;
; Created: 5/19/2018 2:04:01 PM
; Author : Vador
;

checkKeyboard:
	; 4 steps keyboard check
	; check row 3
	sbi PORTD,6
	cbi PORTD,5
	sbi PORTD,7
	sbi PORTD,4
	nop

	sbis PIND,1
	rjmp K3pressed
	sbis PIND,3
	rjmp K1pressed

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

end_keyboard:
	ret

K0pressed:
	; set direction to left
	ldi V, 0b0000_1000
	cbi PORTC,3
	rjmp end_keyboard
K3pressed:
	; set direction to up
	ldi V, 0b0000_0100
	cbi PORTC,3
	rjmp end_keyboard
KBpressed:
	; set direction to down
	ldi V, 0b0000_0010
	cbi PORTC,3
	rjmp end_keyboard
KCpressed:
	; set direction to right
	ldi V, 0b0000_0001
	cbi PORTC,3
	rjmp end_keyboard

K1pressed:
	rjmp end_keyboard

KApressed:
	; begin button
	lds RANDOM_POS, TCNT1L
	rcall randomXpos
	sts FRUITXADDR, RANDOM_POS
	lds RANDOM_POS, TCNT1H
	rcall randomYpos
	sts FRUITYADDR, RANDOM_POS

	rcall initialConditions
	rjmp end_keyboard



