;
; Keyboard.inc
;
; Created: 5/19/2018 2:04:01 PM
; Author : Vador
;

checkKeyboard:
    ; 4 steps keyboard check
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
    sbi PORTD,4
    nop

    ; check row 3
    cbi PORTD,5
    sbi PORTD,4
    sbi PORTD,6
    sbi PORTD,7
    nop
    sbis PIND,1
    rjmp K3pressed
    sbi PORTD,5
    nop
end_keyboard:
    ret

K0pressed:
    ; set direction to left
    cpi V,0b0000_0001
    breq end_keyboard
    ldi V, 0b0000_1000
    rjmp end_keyboard
K3pressed:
    ; set direction to up
    cpi V,0b0000_0010
    breq end_keyboard
    ldi V, 0b0000_0100
    rjmp end_keyboard
KBpressed:
    ; set direction to down
    cpi V,0b0000_0100
    breq end_keyboard
    ldi V, 0b0000_0010
    rjmp end_keyboard
KCpressed:
    ; set direction to right
    cpi V,0b0000_1000
    breq end_keyboard
    ldi V, 0b0000_0001
    rjmp end_keyboard

KApressed:
    ; begin button
    rcall initialConditions

    lds RANDOM_POS, TCNT1L
    rcall randomXpos
    sts FRUITXADDR, RANDOM_POS
    lds RANDOM_POS, TCNT1H
    rcall randomYpos
    sts FRUITYADDR, RANDOM_POS
    rjmp end_keyboard



