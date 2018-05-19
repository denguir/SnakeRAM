/*
 * Display.inc
 *
 *  Created: 5/19/2018 2:09:20 PM
 *   Author: Vador
 */ 


 display:
	ldi XH, HIGH(HEADXADDR)
	ldi XL, LOW(HEADXADDR)
	; plot the snake
	mov COUNTER_POS, LENGTH
	for_display:
		cpi COUNTER_POS, 0
		breq display_end
		push COUNTER_POS ; also used in plot_posX,Y
		ld POS_X, X+
		rcall plot_posX
		ld POS_Y, X+
		rcall plot_posY
		rcall enableLatch
		pop COUNTER_POS ; recover from RAM
		dec COUNTER_POS
		rjmp for_display
	display_end:
		; plot the fruit and return
		lds POS_X, FRUITXADDR
		rcall plot_posX
		lds POS_Y, FRUITYADDR
		rcall plot_posY
		rcall enableLatch
		ret

plot_posX:
	ldi COUNTER_POS, X_MAX
	; to make 80 - POS, do the 3 following lines
/*	subi POS, 80 ; X_MAX + 1
	ldi R17, 0b1111_1111 ; xor with 1111_1111 reverse the bits
	eor POS, R17 ; it is done to take into account the fact that the first bit written are the last in the screen*/
	comparePosX:
		cp POS_X, COUNTER_POS
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
		cp POS_Y, COUNTER_POS
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
	sbi TIFR0, TOV0 ; set interrupt bit to 1
	loop_wait:
		sbis TIFR0, TOV0
		rjmp loop_wait
	ret

/*wait:
	in R16,TIFR0 ; read interrupt flag
	bst R16,0 ; copy bit 0 (TOV) in T flag
	brtc wait
	out TIFR0, R16
	ldi R16,COUNTER_OFFSET 
	out TCNT0,R16 ; set counter init
	ret */