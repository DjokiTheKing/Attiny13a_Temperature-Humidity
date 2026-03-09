#define __SFR_OFFSET 0
#include <avr/io.h>

.equ SDA_PIN, 3
.equ SCL_PIN, 4

.section .text

.global i2c_init
.type i2c_init, @function
i2c_init:
    sbi DDRB, SDA_PIN
    sbi DDRB, SCL_PIN 
    
    cbi PORTB, SDA_PIN
    cbi PORTB, SCL_PIN

    cbi DDRB, SDA_PIN
    cbi DDRB, SCL_PIN
    ret

.global i2c_send_start
.type i2c_send_start, @function
i2c_send_start:
    sbi DDRB, SDA_PIN
    nop
    nop
    sbi DDRB, SCL_PIN
    ret

.global i2c_send_stop
.type i2c_send_stop, @function
i2c_send_stop:
    cbi DDRB, SCL_PIN
    nop
    nop
    cbi DDRB, SDA_PIN
    ret

.global i2c_send_addr
.type i2c_send_addr, @function
i2c_send_addr:
    lsl r24
    or r24, r25

    ldi r25, 8
    i2c_loop_addr:
        cbi DDRB, SDA_PIN ; SDA high

        sbrs r24, 7
        sbi DDRB, SDA_PIN ; SDA low

        lsl r24

        cbi DDRB, SCL_PIN ; SCL high

        ; Delay for SCL high
        ldi YH, 0
        ldi YL, 1
        rcall delay_us

        sbi DDRB, SCL_PIN ; SCL low

        dec r25 ; Decrement loop counter
        brne i2c_loop_addr ; loop if loop counter > 0

    cbi DDRB, SDA_PIN ; SDA high
    cbi DDRB, SCL_PIN ; SCL high

    ; Delay for SCL high
    ldi YH, 0
    ldi YL, 1
    rcall delay_us
    
    sbic PINB, SDA_PIN ; SDA read
    ori r24, 0x01

    sbi DDRB, SCL_PIN ; SCL low

    ret

.global i2c_write
.type i2c_write, @function
i2c_write:
    ldi r25, 8
    i2c_loop_write:
        cbi DDRB, SDA_PIN ; SDA high

        sbrs r24, 7
        sbi DDRB, SDA_PIN ; SDA low

        lsl r24

        cbi DDRB, SCL_PIN ; SCL high

        ; Delay for SCL high
        ldi YH, 0
        ldi YL, 1
        rcall delay_us

        sbi DDRB, SCL_PIN ; SCL low
        
        dec r25 ; Decrement loop counter
        brne i2c_loop_write ; loop if loop counter > 0

    cbi DDRB, SDA_PIN ; SDA high
    cbi DDRB, SCL_PIN ; SCL high

    ; Delay for SCL high
    ldi YH, 0
    ldi YL, 1
    rcall delay_us

    sbic PINB, SDA_PIN ; SDA read
    ori r24, 0x01

    sbi DDRB, SCL_PIN ; SCL low
    ret

.global i2c_read
.type i2c_read, @function
i2c_read:
    push r25
    ldi r25, 8
    i2c_loop_read:
        cbi DDRB, SCL_PIN ; SCL high

        lsl r24 

        ; Delay for SCL high
        ldi YH, 0
        ldi YL, 1
        rcall delay_us

        sbic PINB, SDA_PIN ; SDA read
        ori r24, 0x01

        sbi DDRB, SCL_PIN ; SCL low

        dec r25 ; Decrement loop counter
        brne i2c_loop_read ; loop if loop counter > 0

    pop r25
    sbrs r25, 0
    rjmp i2c_read_nack
i2c_read_ack:
    ; SEND ACK
    sbi DDRB, SDA_PIN ; SDA low
    cbi DDRB, SCL_PIN ; SCL high

    ; Delay for SCL high
    ldi YH, 0
    ldi YL, 1
    rcall delay_us

    sbi DDRB, SCL_PIN ; SCL low
    cbi DDRB, SDA_PIN ; SDA high
    ret
i2c_read_nack:
    ; SEND ACK
    cbi DDRB, SDA_PIN ; SDA high
    cbi DDRB, SCL_PIN ; SCL high

    ; Delay for SCL high
    ldi YH, 0
    ldi YL, 1
    rcall delay_us

    sbi DDRB, SCL_PIN ; SCL low
    ret