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

; define constants
.equ COUNTER_OFFSET = 231
.equ COUNTER_OFFSET_MOVE_L = 0xCB
.equ COUNTER_OFFSET_MOVE_H = 0xF3

.equ HEADXADDR = 0x0100
.equ TAILXADDR = 0x0104
.equ TAILYHEAD = 0x010F

; define map size
.equ X_MAX = 79
.equ Y_MAX = 6
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

	; head 


	ldi V, 0b0000_0001 ; left Vx, Vy - righth
	;rcall go_right ; initial velocity

	; config display timer 
	ldi R16,COUNTER_OFFSET 
	out TCNT0,R16 ; set counter init
	ldi R16,0b0000_0011 ; set prescaler to 64 (COUNTER_OFFSET = 231 -> f = 10kHz)
	out TCCR0B,R16 ; timer is configured with prescaler 
	;(timer begins)

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
	rcall updateDir
	;rcall move
	rcall display
	rjmp main

move:
	lds POS_Y, 0x0103
	push POS_Y
	lds POS_X, 0x0102
	push POS_X

	lds POS_Y, 0x0101
	push POS_Y
	lds POS_X, 0x0100
	push POS_X

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
		sts 0x0100, POS_X
		sts 0x0101, POS_Y
		pop POS_X
		pop POS_Y
		sts 0x0102, POS_X
		sts 0x0103, POS_Y
		pop POS_X
		pop POS_Y
		sts 0x0104, POS_X
		sts 0x0105, POS_Y
		ret

display:
	; head
	lds POS, 0x0100
	rcall plot_posX
	lds POS, 0x0101
	rcall plot_posY
	rcall enableLatch
	; body
	lds POS, 0x0102
	rcall plot_posX
	lds POS, 0x0103
	rcall plot_posY
	rcall enableLatch
	; tail
	lds POS, 0x0104
	rcall plot_posX
	lds POS, 0x0105
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
	brpl do_go_up
	cpi POS_X, 40
	brmi up_from_top
	rjmp up_from_bottom

	up_from_top:
		ldi POS_Y, 6
		adiw POS_X, 40 ; add offset to change top to down screen
		rjmp go_up_end

	up_from_bottom:
	 	ldi POS_Y, 6
		subi POS_X, 40 ; sub offset to change down to top screen
		rjmp go_up_end

	do_go_up:
		dec POS_Y
		rjmp go_down_end
	go_up_end:
		ret

go_down:
	cpi POS_Y, 6
	brmi do_go_down

	cpi POS_X, 40
	brmi down_from_top
	rjmp down_from_bottom

	down_from_top:
		ldi POS_Y, 0
		adiw POS_X, 40 ; add offset to change top to down screen
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
	; if down screen
	cpi POS_X, 40
	brlo do_go_left ; why not brpl ??
	breq go_to_XMAX
	rjmp go_left2
	go_to_XMAX:
		ldi POS_X, X_MAX
		rjmp go_left_end
	; if top screen
	go_left2:
		cpi POS_X, 0
		brpl do_go_left
		breq go_to_X39
		go_to_X39:
			ldi POS_X, 39
			rjmp go_left_end
	do_go_left:
		dec POS_X
		rjmp go_left_end
	go_left_end:
		ret


go_right:
	; if top screen
	cpi POS_X, 39
	brmi do_go_right
	breq go_to_X0
	rjmp go_right2
	go_to_X0:
		ldi POS_X, 0
		rjmp go_right_end
	; if down screen
	go_right2:
		cpi POS_X, X_MAX
		brmi do_go_right
		breq go_to_X40
		go_to_X40:
			ldi POS_X, 40
			rjmp go_right_end
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
	;sbi PINB,1 ; switch buzzer
	;cbi PORTC,2 ; switch led 2
	rcall move
	ldi R16, COUNTER_OFFSET_MOVE_H
	sts TCNT1H,R16
	ldi R16, COUNTER_OFFSET_MOVE_L
	sts TCNT1L,R16
	reti
