/*
 * Keyboard.inc
 *
 *  Created: 5/19/2018 12:43:56 PM
 *   Author: Vador
 */ 

 /*
##########################
KEYBOARD READING FUNCTIONS
##########################
*/

updateDir:
	; 2 steps keyboard check
	;clr SEL_KEY
	;rcall KBCheck1
	;rcall KBCheck2
	;rcall selectKey
	;rjmp compareKey
	rcall checkKeyboard
dirUpdated:
	ret

KBCheck1:
	rcall configRowKb
	rcall readColKb
	ret

KBCheck2:
	rcall configColKb
	rcall readRowKb
	ret
	

configRowKb:
	ldi KB_REG, 0b1111_0000 ; 4 row output mode, 4 col input mode
	out DDRD, KB_REG
	ldi KB_REG, 0b0000_1111 ; rows -> low, cols -> enable pull up resistors
	out PORTD, KB_REG
	ret

configColKb:
	ldi KB_REG, 0b0000_1111 ; 4 col output mode, 4 row input mode
	out DDRD, KB_REG
	ldi KB_REG, 0b0000_1111 ; all cols high, 
	out PORTD, KB_REG
	ret

readColKb:
	in R0, PIND ; read Pin state
	ldi KB_REG, 0b0000_1111 ; max value of PIND
	sub KB_REG, R0 ; KB_STATE = 0 if all cols are high
	breq noKeyPressedCol ; compare KB_STATE (last register used) with 0
	rjmp keyPressedCol

	noKeyPressedCol:
		ldi SEL_COL, 0x00
		ret
	keyPressedCol:
		rcall checkColPressed
		ret

readRowKb:
	in R0, PIND ; read Pin state
	ldi KB_REG, 0b1111_0000 ; max value of PIND
	sub KB_REG, R0 ; KB_STATE = 0 if all cols are high
	breq noKeyPressedRow ; compare KB_STATE (last register used) with 0
	rjmp keyPressedRow

	noKeyPressedRow:
		ldi SEL_ROW, 0x00
		ret
	keyPressedRow:
		rcall checkRowPressed
		ret


checkColPressed:
	sbis PIND,0
	ldi SEL_COL, 0b0000_0001
	sbis PIND,1
	ldi SEL_COL, 0b0000_0010
	sbis PIND,2
	ldi SEL_COL, 0b0000_0100
	sbis PIND,3
	ldi SEL_COL, 0b0000_1000
	ret

checkRowPressed:
	sbic PIND,4
	ldi SEL_ROW, 0b0001_0000
	sbic PIND,5
	ldi SEL_ROW, 0b0010_0000
	sbic PIND,6
	ldi SEL_ROW, 0b0100_0000
	sbic PIND,7
	ldi SEL_ROW, 0b1000_0000
	ret

selectKey:
	add SEL_KEY, SEL_COL
	add SEL_KEY, SEL_ROW
	ret

compareKey:
	cpi SEL_KEY, NO_K
		breq NoKpressed
	cpi SEL_KEY, K0
		breq K0pressed
	cpi SEL_KEY, K3
		breq K3pressed
	cpi SEL_KEY, KB
		breq KBpressed
	cpi SEL_KEY, KC
		breq KCpressed
	cpi SEL_KEY, KA
		breq KApressed

NoKpressed:
	sbi PORTC,3
	rjmp dirUpdated
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


checkKeyboard:
	; check Row 3 
	SBI PORTD,6
	CBI PORTD,5
	SBI PORTD,7
	SBI PORTD,4
	NOP

	SBIS PIND,1
	RJMP K3pressed

	; check Row 4
	CBI PORTD,4
	SBI PORTD,5
	SBI PORTD,6
	SBI PORTD,7
	NOP

	SBIS PIND,0
	RJMP KCpressed
	SBIS PIND,1
	RJMP KBpressed
	SBIS PIND,2
	RJMP K0pressed
	SBIS PIND,3
	RJMP KApressed
	RJMP NoKpressed

	RET