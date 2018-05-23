/*
 * Move.inc
 *
 *  Created: 5/19/2018 2:04:01 PM
 *   Author: Vador
 */ 

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
		subi POS_X, 216 ; -216 = +40 (offset to change top to down screen)
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
		subi POS_X, 216 ; -216=+40 (offset to change top to down screen)
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
		rjmp go_right_end

	boudary_down_right:
		ldi POS_X, 40
		rjmp go_right_end	

	do_go_right:
		inc POS_X
		rjmp go_right_end

	go_right_end:
		ret