#define __SFR_OFFSET 0
#include <avr/io.h>

.equ MOSI_PIN, 2
.equ CLK_PIN, 1
.equ CS_PIN, 0

.section .text

.global spi_transfer
.type spi_transfer, @function
spi_transfer:
    ; CS LOW
    cbi PORTB, CS_PIN

    ; loop counter
    ldi r25, 8
    spi_loop_transfer:
        ; clear MOSI
        cbi PORTB, MOSI_PIN

        ; check and set MOSI
        sbrc r24, 7
        sbi PORTB, MOSI_PIN
        
        ; clock high
        sbi PORTB, CLK_PIN

        ; shift left
        lsl r24

        ; decrement loop counter
        dec r25

        ; clock low
        cbi PORTB, CLK_PIN

        ; branch if loop counter != 0
        brne spi_loop_transfer
        
    ; CS HIGH
    sbi PORTB, CS_PIN
    ret
