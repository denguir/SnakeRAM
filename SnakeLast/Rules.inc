/*
 * Rules.inc
 *
 *  Created: 5/19/2018 2:11:17 PM
 *   Author: Vador
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
		rcall nextRandomPos
		inc LENGTH
		rjmp eat_ended

	eat_ended:
		ret