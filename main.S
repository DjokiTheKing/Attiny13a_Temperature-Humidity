#define __SFR_OFFSET 0
#include <avr/io.h>

.equ MOSI_PIN, 2
.equ CLK_PIN, 1
.equ CS_PIN, 0

.extern spi_transfer

.extern delay_ms
.extern delay_us

.extern display_init
.extern display_set_cursor
.extern display_write
.extern display_write_string
.extern display_write_hex
.extern display_clear
.extern display_write_fixed_8_8

.extern i2c_init
.extern i2c_send_start
.extern i2c_send_stop
.extern i2c_send_addr
.extern i2c_write
.extern i2c_read

.section .data

.section .progmem
dev_NACK: .ascii "NACK"
temp_start: .ascii "TEMP:  "
temp_end: .ascii "  C"
humid_start: .ascii "HUMID: "
humid_end: .ascii "% Rh"

.section .text

.global test_ack
.type test_ack, @function
test_ack:
    tst r24
    brne NACK_P
    ret

NACK_P:
    rcall display_clear

    ldi r24, 0
    ldi r25, 0
    rcall display_set_cursor

    rcall i2c_send_stop
    ldi r24, 4
    ldi ZL, lo8(dev_NACK)
    ldi ZH, hi8(dev_NACK)
    rcall display_write_string
    rjmp prog_end

.global aht20_send_addr
.type aht20_send_addr, @function
aht20_send_addr:
    ldi r24, 0x38
    rcall i2c_send_addr
    rcall test_ack
    ret

.global aht20_write_and_test
.type aht20_write_and_test, @function
aht20_write_and_test:
    rcall i2c_write
    rcall test_ack
    ret

.global aht20_get_status
.type aht20_get_status, @function
aht20_get_status:
    ; send status command 0x71
    rcall i2c_send_start 

    ldi r25, 0x00
    rcall aht20_send_addr

    ldi r24, 0x71
    rcall aht20_write_and_test

    rcall i2c_send_stop
    
    ; read status byte
    rcall i2c_send_start

    ldi r25, 0x01
    rcall aht20_send_addr

    ldi r25, 0x00
    rcall i2c_read

    rcall i2c_send_stop 
    ret

.global aht20_wait_busy_clear
.type aht20_wait_busy_clear, @function
aht20_wait_busy_clear:
    rcall aht20_get_status
    sbrc r24, 7      ; if busy bit set
    rjmp aht20_wait_busy_clear
    ret

.global aht20_calibrate
.type aht20_calibrate, @function
aht20_calibrate:
    rcall i2c_send_start

    ldi r25, 0x00
    rcall aht20_send_addr
    
    ldi r24, 0xbe
    rcall aht20_write_and_test

    ldi r24, 0x08
    rcall aht20_write_and_test

    ldi r24, 0x00
    rcall aht20_write_and_test

    rcall i2c_send_stop

    ; wait 10 ms for calibration
    ldi YH, 0
    ldi YL, 10
    rcall delay_ms
    ret

.global multiply_int
.type multiply_int, @function
multiply_int:
    push r20
    push r19
    push r18

    ldi r20, 0
    ldi r19, 0
    ldi r18, 0

    multiply_int_loop:
        add r20, r24
        adc r19, r23
        adc r18, r22
        dec r25
        brne multiply_int_loop

    mov r24, r20
    mov r23, r19
    mov r22, r18

    pop r17
    pop r18
    pop r19
    ret

.global init_prog
.type init_prog, @function
init_prog:
    ldi YH, 0
    ldi YL, 20
    rcall delay_ms

    rcall i2c_init
    rcall display_init

    ldi r24, 0
    ldi r25, 0
    rcall display_set_cursor

    ; wait for sensor ready
    rcall aht20_wait_busy_clear

    ; check if it's calibrated and if not calibrate it
    sbrs r24, 3         
    rcall aht20_calibrate

    ; wait for sensor ready
    rcall aht20_wait_busy_clear
    ret

.global main
.type main, @function
main:
    wdr
    ; Clear WDRF in MCUSR
    in    r16, MCUSR
    mov   r17, r16
    andi  r16, ~(1<<WDRF)
    out   MCUSR, r16
    ; Write logical one to WDCE and WDE
    ; Keep old prescaler setting to prevent unintentional time-out
    in    r16, WDTCR
    ori   r16, (1<<WDCE) | (1<<WDE)
    out   WDTCR, r16
    ; Turn off WDT
    ldi   r16, (0<<WDE)
    out   WDTCR, r16

    ldi r16, 0x00

    sbi DDRB, MOSI_PIN
    sbi DDRB, CLK_PIN
    sbi DDRB, CS_PIN
    cbi PORTB, CS_PIN

    rcall i2c_init

    sbrs r17, WDRF
    rcall init_prog
    
measure:
    ; send read command
    rcall i2c_send_start

    ldi r25, 0x00
    rcall aht20_send_addr ; +1

    ldi r24, 0xAC
    rcall aht20_write_and_test ; +1

    ldi r24, 0x33
    rcall aht20_write_and_test ; +1

    ldi r24, 0x00
    rcall aht20_write_and_test

    rcall i2c_send_stop

    ldi YH, 0
    ldi YL, 85
    rcall delay_ms

    ; wait for sensor ready
    rcall aht20_wait_busy_clear

    ; read data 
    rcall i2c_send_start

    ldi r25, 0x01
    rcall aht20_send_addr

    ldi r25, 0x01
    rcall i2c_read
    ldi r23, 4

measure_read_loop:
    ldi r25, 0x01
    rcall i2c_read
    push r24
    dec r23
    brne measure_read_loop

    ldi r25, 0x00
    rcall i2c_read

    rcall i2c_send_stop

    ldi r24, 0
    ldi r25, 0
    rcall display_set_cursor

    ldi r24, 7
    ldi ZL, lo8(temp_start)
    ldi ZH, hi8(temp_start)
    rcall display_write_string

    ; skip temperature data and convert humidity data
    pop r23
    pop r22
    ldi r21, 4
    temperature_ror:
        ror r22
        ror r23
        ror r24
        dec r21
        brne temperature_ror
    
    ldi r22, 0

    ldi r25, 200
    rcall multiply_int

    subi r22, 50

    mov r24, r22
    mov r25, r23
    rcall display_write_fixed_8_8

    ldi r24, 3
    ldi ZL, lo8(temp_end)
    ldi ZH, hi8(temp_end)
    rcall display_write_string

    ldi r24, 0
    ldi r25, 1
    rcall display_set_cursor

    ldi r24, 7
    ldi ZL, lo8(humid_start)
    ldi ZH, hi8(humid_start)
    rcall display_write_string

    pop r24
    pop r23
    ldi r22, 0

    ldi r25, 100

    rcall multiply_int

    mov r24, r22
    mov r25, r23
    rcall display_write_fixed_8_8

    ldi r24, 4
    ldi ZL, lo8(humid_end)
    ldi ZH, hi8(humid_end)
    rcall display_write_string

prog_end:
    wdr
    in    r16, WDTCR
    ori   r16, (1<<WDCE) | (1<<WDE)
    out   WDTCR, r16
    ldi   r16, (1<<WDE) | (1<<WDP3) | (1<<WDP0)
    out   WDTCR, r16

    in r16, MCUCR
    andi r16, ~(1<<SM0)
    ori r16, (1<<SM1) | (1<<SE)
    out MCUCR, r16

    sleep