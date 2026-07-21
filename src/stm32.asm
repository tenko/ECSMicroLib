; default functions to avoid linker error
; these functions are replaced by MCU dependent code

; standard free function, defaults to nop
.code free
    .replaceable
    .alignment    4
    bx.n  lr

; standard malloc function (bump allocator)
.code malloc
    .replaceable
    .alignment    4

    ldr.n   r2, offset (heap) + offset (heap) % 4
    ldr.n r0, [r2, 0]
    ldr.n r3, [sp, 0]

    ; round up to nearest word
    mov r1, 3
    add r4, r3, r1
    mov r1, 4
    rsb r1, 0
    and r3, r4, r1

    add.n r3, r3, r0
    str.n r3, [r2, 0]
    bx.n  lr

heap: .qbyte  @_heap_start

; standard abort function (infinite loop)
.code abort
    .replaceable
    .alignment    4
loop:
    b.n    loop

; standard _Exit function
.code _Exit
    .alignment    4
    bl       @abort

; standard getchar function, defaults to nop
.code getchar
    .replaceable
    .alignment    4
    bx.n   lr

; standard putchar function, defaults to nop
.code putchar
    .replaceable
    .alignment    4
    bx.n   lr

; delay idle function, defaults to wfi
.code delay_idle
    .replaceable
    .alignment    4
    wfi
    bx.n   lr
    
; delay seconds function, defaults to nop
.code delay_s
    .replaceable
    .alignment    4
    bx.n   lr
    
; delay ms function, defaults to nop
.code delay_ms
    .replaceable
    .alignment    4
    bx.n   lr
    
; delay us function, defaults to nop
.code delay_us
    .replaceable
    .alignment    4
    bx.n   lr
    
; ms ticks function, defaults to nop
.code ticks_ms
    .replaceable
    .alignment    4
    mov r0, 0
    bx.n   lr
    
; cpu ticks function, defaults to nop
.code ticks_cpu
    .replaceable
    .alignment    4
    mov r0, 0
    bx.n   lr
    
; cpu frequency
cpu_freq: .qbyte  0

; enable interrupts
.code irq_enable
    .replaceable
    .alignment    4
    cpsie i
    bx.n   lr

; disable interrupts
.code irq_disable
    .replaceable
    .alignment    4
    cpsid i
    bx.n   lr

; reset, defaults to nop
.code reset
    .replaceable
    .alignment    4
    bx.n   lr

; light sleep, defaults to nop
.code sleep_light
    .replaceable
    .alignment    4
    bx.n   lr

; deep sleep, defaults to nop
.code sleep_deep
    .replaceable
    .alignment    4
    bx.n   lr
