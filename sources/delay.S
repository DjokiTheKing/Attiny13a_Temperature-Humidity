.section .text

.global delay_ms
.type delay_ms, @function

delay_ms:
    ldi XL, 96
    ldi XH, 9
    loop_ms:
        sbiw X, 0x01
        brne loop_ms
    sbiw Y, 0x01
    brne delay_ms
    ret


.global delay_us
.type delay_us, @function

delay_us:
    nop
    nop
    nop
    nop
    nop
    nop
    sbiw Y, 0x01
    brne delay_us
    ret
