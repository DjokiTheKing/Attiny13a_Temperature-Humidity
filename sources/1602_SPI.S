.extern spi_transfer
.extern delay_ms
.extern delay_us

.equ RS_PIN, 0x08
.equ NRS_PIN, 0xf7

.equ EN_PIN, 0x04
.equ NEN_PIN, 0xfB

.equ LATCH_PIN, 0

.section .data ; dynamic data to be stored in sram

.section .progmem ; read only data to be stored in flash

.section .text ; code

.global display_init
.type display_init, @function
display_init:
    andi r16, 0x03

    ; sleep for 40 ms
    ldi YH, 0
    ldi YL, 40
    rcall delay_ms

    ; pull rs and rw low 
    mov r24, r16
    rcall spi_transfer

    ; try to set 4bit mode - try 1
    ldi r24, 0x03
    rcall write4bits
    ; sleep for 5 ms
    ldi YH, 0
    ldi YL, 5
    rcall delay_ms

    ; try to set 4bit mode - try 2
    ldi r24, 0x03
    rcall write4bits
    ; sleep for 120 us
    ldi YH, 0
    ldi YL, 120
    rcall delay_us

    ; try to set 4bit mode - try 3
    ldi r24, 0x03
    rcall write4bits

    ldi r24, 0x02
    rcall write4bits

    ldi r24, 0x28
    ldi r25, 0
    rcall send

    ldi r24, 0x0C
    ldi r25, 0
    rcall send

    rcall display_clear

    ldi r24, 0x06
    ldi r25, 0
    rcall send

    ret

.global display_set_cursor
.type display_set_cursor, @function
display_set_cursor:
    push r23

    ldi r23, 0x40
    sbrc r25, 0
    add r24, r23
    ori r24, 0x80
    ldi r25, 0
    rcall send

    pop r23
    ret

.global display_clear
.type display_clear, @function
display_clear:
    ldi r24, 0x01
    ldi r25, 0
    rcall send

    ; sleep for 2 ms
    ldi YH, 0
    ldi YL, 2
    rcall delay_ms

    ret

.global display_write_string
.type display_write_string, @function
display_write_string:
    push r21
    mov r21, r24
    loop_write_string:
        lpm r24, Z+
        rcall display_write
        dec r21
        brne loop_write_string
    pop r21
    ret

.global display_write
.type display_write, @function
display_write:
    ldi r25, 1
    rcall send
    ret

.global display_write_half_hex
.type display_write_half_hex, @function
display_write_half_hex:
    push r23
    ldi r23, 0

    andi r24, 0x0F

    tst r24
    brne display_write_hex_int
    ldi r24, 0x30 ; ascii offset for numbers
    breq display_write_hex_finally

    display_write_hex_int:
    ldi r25, 9
    display_write_hex_loop_int:
        inc r23
        dec r24
        breq display_write_hex_loop_int_end
        dec r25
        brne display_write_hex_loop_int
    
    display_write_hex_loop_int_end:
        tst r24
        brne display_write_hex_char
        ldi r24, 0x30 ; ascii offset for numbers
        breq display_write_hex_finally

    display_write_hex_char:
        ldi r23, 0
        display_write_hex_loop_char:
            inc r23
            dec r24
            brne display_write_hex_loop_char
    dec r23
    ldi r24, 0x41 ; ascii offset for characters

    display_write_hex_finally:
        add r24, r23
        ldi r25, 1
        rcall send

    pop r23
    ret

.global display_write_hex
.type display_write_hex, @function
display_write_hex:
    push r22

    mov r22, r24
    
    swap r24
    rcall display_write_half_hex

    mov r24, r22
    rcall display_write_half_hex

    pop r22
    ret

.global display_write_fixed_8_8
.type display_write_fixed_8_8, @function
display_write_fixed_8_8:
    push r25
    push r24
    ldi r25, 0
    display_write_fixed_div_loop:
        subi r24, 10
        brlo display_write_fixed_div_loop_end
        inc r25
        rjmp display_write_fixed_div_loop
    display_write_fixed_div_loop_end:

    push r25
    
    tst r24
    breq skip_display_write_fixed_digit0

    ldi r24, 0x30
    add r24, r25
    rcall display_write
    rjmp display_write_fixed_digit1

    skip_display_write_fixed_digit0:
    ldi r24, 0x20
    rcall display_write

    display_write_fixed_digit1:

    pop r25

    push r23
    ldi r24, 0
    ldi r23, 10
    display_write_fixed_modulo_loop:
        add r24, r23
        dec r25
        brne display_write_fixed_modulo_loop

    pop r23
    pop r25

    sub r25, r24
    ldi r24, 0x30
    add r24, r25

    rcall display_write

    ldi r24, 0x2E
    rcall display_write

    pop r25
    push r23
    push r22
    ldi r22, 2
    display_write_fixed_mul_loop:
        ldi r24, 0
        ldi r23, 10 
        display_write_fixed_mul_loop_inner:
            add r25, r25
            brcc display_write_fixed_mul_loop_inner_zero
            inc r24
            display_write_fixed_mul_loop_inner_zero:
            dec r23
            brne display_write_fixed_mul_loop_inner
        ldi r23, 0x30
        add r24, r23
        push r25
        rcall display_write
        pop r25
        dec r22
        brne display_write_fixed_mul_loop
    pop r22
    pop r23
    ret

.type send, @function
send:
    push r22

    andi r16, NRS_PIN
    sbrc r25, 0
    ori r16, RS_PIN

    mov r22, r24
    mov r24, r16
    rcall spi_transfer

    mov r24, r22
    swap r24
    rcall write4bits

    mov r24, r22
    rcall write4bits

    pop r22
    ret

.type write4bits, @function
write4bits:
    swap r24
    andi r24, 0xf0
    andi r16, 0x0f
    or r16, r24

    mov r24, r16
    rcall spi_transfer
    
    ; pulse lcd en 
    ori r16, EN_PIN
    mov r24, r16
    rcall spi_transfer

    andi r16, NEN_PIN
    mov r24, r16
    rcall spi_transfer
    
    ; wait 37 us
    ldi YH, 0
    ldi YL, 37
    rcall delay_us
    ret
