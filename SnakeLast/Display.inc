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

 displayScore:
	ret

displayGameOver:
	; enable columns of row 1
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_1110
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_1110
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_1110
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	; enable row 1
	rcall enable_row_1
	rcall enableLatch

	; enable columns of row 2
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_1011
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	; enable row 2
	rcall enable_row_2
	rcall enableLatch

	; enable columns of row 3
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0101
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	; enable row 3
	rcall enable_row_3
	rcall enableLatch

	; enable columns of row 4
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_1110
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0001_0011
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	; enable row 4
	rcall enable_row_4
	rcall enableLatch

	; enable columns of row 5
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0100
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	; enable row 5
	rcall enable_row_5
	rcall enableLatch

	; enable columns of row 6
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0010
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_1010
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	; enable row 6
	rcall enable_row_6
	rcall enableLatch

	; enable columns of row 7
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0000_0100
	rcall write_symbol
	ldi SYMBOL, 0b0000_1110
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_0001
	rcall write_symbol
	ldi SYMBOL, 0b0001_1111
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	ldi SYMBOL, 0b0000_0000
	rcall write_symbol
	; enable row 7
	rcall enable_row_7
	rcall enableLatch
	ret

enable_row_1:
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_1
	ret

enable_row_2:
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_1
	rcall write_0
	ret

enable_row_3:
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_1
	rcall write_0
	rcall write_0
	ret

enable_row_4:
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_1
	rcall write_0
	rcall write_0
	rcall write_0
	ret

enable_row_5:
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_1
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	ret

enable_row_6:
	rcall write_0
	rcall write_0
	rcall write_1
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	ret
	
enable_row_7:
	rcall write_0
	rcall write_1
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	rcall write_0
	ret

; all print functions will display a specific character 
; on one single cell of the matrix led (cell = 7 rows x 5 cols)

write_symbol:
	; load the value on register SYMBOL and convert it on led symbol
	; ex : if SYMBOL = 0b01000 -> turn on the second led of selected cell 
	symb0:
		sbrs SYMBOL,0 ; skip if bit set
		rjmp symb0_is_0
		symb0_is_1:
			rcall write_1
	symb1:
		sbrs SYMBOL,1 ; skip if bit set
		rjmp symb1_is_0
		symb1_is_1:
			rcall write_1
	symb2:
		sbrs SYMBOL,2 ; skip if bit set
		rjmp symb2_is_0
		symb2_is_1:
			rcall write_1
	symb3:
		sbrs SYMBOL,3 ; skip if bit set
		rjmp symb3_is_0
		symb3_is_1:
			rcall write_1
	symb4:
		sbrs SYMBOL,4 ; skip if bit set
		rjmp symb4_is_0
		symb4_is_1:
			rcall write_1
			rjmp symb_ended

	symb0_is_0:
		rcall write_0
		rjmp symb1

	symb1_is_0:
		rcall write_0
		rjmp symb2

	symb2_is_0:
		rcall write_0
		rjmp symb3

	symb3_is_0:
		rcall write_0
		rjmp symb4

	symb4_is_0:
		rcall write_0
		rjmp symb_ended
	
	symb_ended:
		ret