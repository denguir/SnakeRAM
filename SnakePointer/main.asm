;
; Snake.asm
;
; Created: 4/22/2018 12:09:48 PM
; Author : Vador
;

; include definition file of ATmega328P
.include "m328pdef.inc"

; define registers
.def KB_REG = R17
.def SEL_COL = R18
.def SEL_ROW = R19
.def SEL_KEY = R20
.def COUNTER_POS = R21
.def POS = R22
.def POS_Y = R23
.def POS_X = R24
.def V = R25 ; 4bits + Vx_Vy
; R26 -> R29 used as pointers X and Y
.def COUNTER_MOVE = R30
.def LENGTH = R31

; define constants
.equ COUNTER_OFFSET = 156
.equ COUNTER_OFFSET_MOVE_L = 0xE5
.equ COUNTER_OFFSET_MOVE_H = 0xF9
; define map size
.equ X_MAX = 79
.equ Y_MAX = 6
; define max length
.equ LENGTH_MAX = 16
; define head SRAM addresses
.equ HEADXADDR = 0x0100
.equ HEADYADDR = 0x0101
; define fruit SRAM addresses
.equ FRUITXADDR = 0x0200
.equ FRUITYADDR = 0x0201
; define each keyboard input
.equ K7 = 0b1000_1000
.equ K8 = 0b1000_0100
.equ K9 = 0b1000_0010
.equ KF = 0b1000_0001

.equ K4 = 0b0100_1000
.equ K5 = 0b0100_0100
.equ K6 = 0b0100_0010
.equ KE = 0b0100_0001

.equ K1 = 0b0010_1000
.equ K2 = 0b0010_0100
.equ K3 = 0b0010_0010
.equ KD = 0b0010_0001

.equ KA = 0b0001_1000
.equ K0 = 0b0001_0100
.equ KB = 0b0001_0010
.equ KC = 0b0001_0001

.equ NO_K = 0b0000_0000

; begin program
.org 0x0000
	rjmp init
.org 0x001A
	rjmp ISR

init:
	; config pins
	sbi DDRB,3
	cbi PORTB,3
	sbi DDRB,4
	cbi PORTB,4
	sbi DDRB,5
	cbi PORTB,5

	; led for debugging	
	sbi DDRB,1 ; buzzer configured as output
	sbi DDRC,2
	sbi DDRC,3
	sbi PORTC,2
	sbi PORTC,3

	ldi LENGTH, 5

	; head position initial
	ldi POS_X, 52
	ldi POS_Y, 2
	sts HEADXADDR, POS_X
	sts HEADYADDR, POS_Y

	; fruit position initial
	ldi POS_X, 30
	ldi POS_Y, 2
	sts FRUITXADDR, POS_X
	sts FRUITYADDR, POS_Y

	ldi V, 0b0000_0001 ; left Vx, Vy - righth

	; config display timer 
	ldi R16,COUNTER_OFFSET 
	out TCNT0,R16 ; set counter init
	ldi R16,0b0000_0011 ; set prescaler to 64 (COUNTER_OFFSET = 156 -> f = 2.5kHz)
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

	rjmp main

main:
	; breq gameState, GAMEOVER
	; print GAME OVER
	rcall checkRules
	rcall updateDir
	;rcall move ;in ISR
	rcall display
	rjmp main

move:
	ldi YH, HIGH(HEADXADDR)
	ldi YL, LOW(HEADXADDR)
	push LENGTH
	add LENGTH, LENGTH
	subi LENGTH, 2
	add YL, LENGTH
	pop LENGTH
	mov COUNTER_MOVE, LENGTH
	for_move:
		cpi COUNTER_MOVE, 1
		breq do_move
		ld POS_Y, -Y
		push POS_Y
		ld POS_X, -Y
		push POS_X
		dec COUNTER_MOVE
		rjmp for_move

	do_move:
		cpi V, 0b0000_0001
			breq move_right
		cpi V, 0b0000_1000
			breq move_left
		cpi V, 0b0000_0010
			breq move_down
		cpi V, 0b0000_0100
			breq move_up

		rjmp end_move

		move_right:
			rcall go_right
			rjmp end_move
		move_left:
			rcall go_left
			rjmp end_move
		move_up:
			rcall go_up
			rjmp end_move
		move_down:
			rcall go_down
			rjmp end_move
		end_move:
			ldi YH, HIGH(HEADXADDR)
			ldi YL, LOW(HEADXADDR)
			mov COUNTER_MOVE, LENGTH
			for_end_move:
				cpi COUNTER_MOVE, 1
				breq do_end_move
				st Y+, POS_X
				st Y+, POS_Y
				pop POS_X
				pop POS_Y
				dec COUNTER_MOVE
				rjmp for_end_move
		do_end_move:
			st Y+, POS_X
			st Y, POS_Y
			ret
	

display:
	ldi XH, HIGH(HEADXADDR)
	ldi XL, LOW(HEADXADDR)
	; plot the snake
	mov COUNTER_POS, LENGTH
	for_display:
		cpi COUNTER_POS, 0
		breq display_end
		push COUNTER_POS ; also used in plot_posX,Y
		ld POS, X+
		rcall plot_posX
		ld POS, X+
		rcall plot_posY
		rcall enableLatch
		pop COUNTER_POS ; recover from RAM
		dec COUNTER_POS
		rjmp for_display
	display_end:
		; plot the fruit
		lds POS, FRUITXADDR
		rcall plot_posX
		lds POS, FRUITYADDR
		rcall plot_posY
		rcall enableLatch
		ret

/*
#################
MOVING FUNCTIONS
#################
*/

go_up:
	cpi POS_Y, 0
	breq boundary_up
	rjmp do_go_up
	boundary_up:
		cpi POS_X, 40
		brmi up_from_top
		rjmp up_from_bottom

	up_from_top:
		ldi POS_Y, 6
		subi POS_X, 216 ; -216 = +40
		rjmp go_up_end

	up_from_bottom:
	 	ldi POS_Y, 6
		subi POS_X, 40 ; sub offset to change down to top screen
		rjmp go_up_end

	do_go_up:
		dec POS_Y
		rjmp go_up_end
	go_up_end:
		ret

go_down:
	cpi POS_Y, 6
	breq boundary_down
	rjmp do_go_down

	boundary_down:
		cpi POS_X, 40
		brmi down_from_top
		rjmp down_from_bottom

	down_from_top:
		ldi POS_Y, 0
		subi POS_X, 216 ; -216=+40 add offset to change top to down screen
		rjmp go_down_end

	down_from_bottom:
	 	ldi POS_Y, 0
		subi POS_X, 40 ; sub offset to change down to top screen
		rjmp go_down_end

	do_go_down:
		inc POS_Y
		rjmp go_down_end
	go_down_end:
		ret

go_left:
	cpi POS_X, 0
	breq boudary_up_left
	cpi POS_X, 40
	breq boudary_down_left
	rjmp do_go_left

	boudary_up_left:
		ldi POS_X, 39
		rjmp go_left_end

	boudary_down_left:
		ldi POS_X, X_MAX
		rjmp go_left_end	

	do_go_left:
		dec POS_X
		rjmp go_left_end
	go_left_end:
		ret

go_right:
	cpi POS_X, 39
	breq boudary_up_right
	cpi POS_X, X_MAX
	breq boudary_down_right
	rjmp do_go_right

	boudary_up_right:
		ldi POS_X, 0
		rjmp go_left_end

	boudary_down_right:
		ldi POS_X, 40
		rjmp go_left_end	

	do_go_right:
		inc POS_X
		rjmp go_right_end

	go_right_end:
		ret

/*
############################
DISPLAY LED MATRIX FUNCTIONS
############################
*/

plot_posX:
	ldi COUNTER_POS, X_MAX
	; to make 80 - POS, do the 3 following lines
/*	subi POS, 80 ; X_MAX + 1
	ldi R17, 0b1111_1111 ; xor with 1111_1111 reverse the bits
	eor POS, R17 ; it is done to take into account the fact that the first bit written are the last in the screen*/
	comparePosX:
		cp POS, COUNTER_POS
		breq foundPosX
		rcall write_0
	checkEndPlotX:
		cpi COUNTER_POS, 0
		breq endPlotX
		dec COUNTER_POS
		rjmp comparePosX
	foundPosX:
		rcall write_1
		rjmp checkEndPlotX
	endPlotX:
		ret

plot_posY:
	ldi COUNTER_POS, Y_MAX
/*	subi POS, 7 ; Y_MAX + 1
	ldi R17, 0b1111_1111 ; xor with 1111_1111 reverse the bits
	eor POS, R17 ; it is done to take into account the fact that the first bit written are the last in the screen*/
	rcall write_0 ; to complete the register of rows
	comparePosY:
		cp POS, COUNTER_POS
		breq foundPosY
		rcall write_0
	checkEndPlotY:
		cpi COUNTER_POS, 0
		breq endPlotY
		dec COUNTER_POS
		rjmp comparePosY
	foundPosY:
		rcall write_1
		rjmp checkEndPlotY
	endPlotY:
		ret


write_0:
	; will write a 0 on the shift register (8 bit register)
	; to do that: 
	; 1- generate your bit with PB3
	; 2- generate a clock rising/falling edge with PB5
	cbi PORTB,3
	sbi PORTB,5
	cbi PORTB,5
	ret

write_1:
	; will write a 1 on the shift register (8 bit register)
	; to do that: 
	; 1- generate your bit with PB3
	; 2- generate a clock rising/falling edge with PB5
	sbi PORTB,3
	sbi PORTB,5
	cbi PORTB,5
	ret

enableLatch:
	; will enable the output of the shift register
	; by setting then clearing PB4
	sbi PORTB,4
	rcall wait
	cbi PORTB,4
	ret

wait:
	in R16,TIFR0 ; read interrupt flag
	bst R16,0 ; copy bit 0 (TOV) in T flag
	brtc wait
	out TIFR0, R16
	ldi R16,COUNTER_OFFSET 
	out TCNT0,R16 ; set counter init
	ret ; exit subroutine and go back to rcall


/*
##########################
KEYBOARD READING FUNCTIONS
##########################
*/

updateDir:
	; 2 steps keyboard check
	clr SEL_KEY
	rcall KBCheck1
	rcall KBCheck2
	rcall selectKey
	rjmp compareKey
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

ISR:
	;cbi PORTC,2 ; switch led 2
	rcall move
	ldi R16, COUNTER_OFFSET_MOVE_H
	sts TCNT1H,R16
	ldi R16, COUNTER_OFFSET_MOVE_L
	sts TCNT1L,R16
	reti

/*
############################
RULES OF THE GAME
############################
*/

checkRules:
	rcall deathRules
	rcall eatRules
	ret

deathRules:
	; here POS_X and POS_Y are just registers with different meaning
	ldi YH, HIGH(HEADYADDR)
	ldi YL, LOW(HEADYADDR)
	inc YL ; to jump on body address
	mov COUNTER_MOVE, LENGTH
	for_death:
		lds POS_X, HEADXADDR
		cpi COUNTER_MOVE, 1
		breq death_ended
		ld POS_Y, Y+ ; POS_Y contains the X pos of next point
		cp POS_X, POS_Y
		breq collision_x
		inc YL ; to check next X
		dec COUNTER_MOVE
		rjmp for_death

		collision_x:
			; check for xy collision
			lds POS_X, HEADYADDR
			ld POS_Y, Y+ ; POS_Y contains the Y pos of body point
			cp POS_X, POS_Y
			breq on_death
			dec COUNTER_MOVE
			rjmp for_death

		on_death:
			; print game over
			ldi V, 0b0000_0000
			rjmp death_ended

	death_ended:
	ret


eatRules:
	; here POS_X and POS_Y are just registers with different meaning
	lds POS_X, HEADXADDR
	lds POS_Y, FRUITXADDR
	; check if matching in x positions
	cp POS_X, POS_Y
	breq match_pos_x
	rjmp eat_ended

	match_pos_x:
		; check if matching in y positions
		lds POS_X, HEADYADDR
		lds POS_Y, FRUITYADDR
		cp POS_X, POS_Y
		breq match_pos_xy
		rjmp eat_ended

	match_pos_xy:
		; if both x and y pos matched
		lds POS_X, FRUITXADDR
		lds POS_Y, FRUITYADDR
		rcall randomPos
		sts FRUITXADDR, POS_X
		sts FRUITYADDR, POS_Y
		inc LENGTH
		rjmp eat_ended

	eat_ended:
		ret

randomPos:
	dec POS_X
	ret
	