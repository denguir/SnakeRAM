/*
 * RandomGen.inc
 *
 *  Created: 5/19/2018 2:12:22 PM
 *   Author: Vador
 */ 

 randomXpos:
	; performs a modulo 80 of the random register
	cpi RANDOM_POS, 80
	brlo randXend
	subi RANDOM_POS, 80
	rjmp randomXpos
	randXend:
		ret

randomYpos:
	; performs a modulo 7 of the random register
	cpi RANDOM_POS, 7
	brlo randYend
	subi RANDOM_POS, 7
	rjmp randomYpos
	randYend:
		ret

nextRandomPos:
	; pseudo random number generator using Fibonacci series

	; random x
	lds POS_X, FRUITXADDR
	lds POS_Y, FRUITXADDR2
	push POS_X
	add POS_X, POS_Y
	mov RANDOM_POS, POS_X
	pop POS_X
	rcall randomXpos
	sts FRUITXADDR, RANDOM_POS
	sts FRUITXADDR2, POS_X
	
	; random y
	lds POS_Y, FRUITYADDR
	lds POS_X, FRUITYADDR2
	push POS_Y
	add POS_Y, POS_X
	mov RANDOM_POS, POS_Y
	pop POS_Y
	rcall randomYpos
	sts FRUITYADDR, RANDOM_POS
	sts FRUITYADDR2, POS_Y
	ret