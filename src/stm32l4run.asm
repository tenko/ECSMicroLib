; Only works on Cortex-M profile ARMv7-M and STM32L4
; RM0394, Reference manual STM32L41xxx/42xxx/43xxx/44xxx/45xxx/46xxx
; RM0351, Reference manual STM32L47xxx, STM32L48xxx, STM32L49xxx and STM32L4Axxx
; Flash/memory origin and size must be changed to values for target device configuration.
.code vector
    .required
    .origin 0x00000000                  ; Flash start address

    .qbyte 0x2000a000                   ; Stack = ram top (40K ram size for smallest device)
    .qbyte extent (@vector) + 1         ; Initial PC. (+1 for Thumb flag)
    .qbyte @isr_nmi + 1;                ; Non maskable interrupt.
    .qbyte @isr_hardfault + 1           ; All class of fault.
    .qbyte @isr_memmanage + 1           ; Memory management, ARMv7-M only.
    .qbyte @isr_busfault + 1            ; Pre-fetch fault, memory access fault, ARMv7-M only.
    .qbyte @isr_usagefault + 1          ; Undefined instruction or illegal state, ARMv7-M only.
    #repeat 4
        .qbyte 0x00                     ; Reserved
    #endrep
    .qbyte @isr_svc + 1                 ; System service call via SWI instruction.
    .qbyte @isr_debugmonitor + 1        ; Debug Monitor.
    .qbyte 0x00                         ; Reserved.
    .qbyte @isr_pendsvc + 1             ; Pendable request for system service.
    .qbyte @isr_systick + 1             ; System tick timer.

    ; Start of STM32L4
    .qbyte @isr_wwdg + 1                ; Window Watchdog interrupt
    .qbyte @isr_pvd + 1                 ; PVD through EXTI line detection interrupt
    .qbyte @isr_tamp_stamp + 1          ; Tamper and TimeStamp interrupts through the EXTI line
    .qbyte @isr_rtc_wkup + 1            ; RTC Wake-up interrupt through the EXTI line
    .qbyte @isr_flash + 1               ; Flash global interrupt
    .qbyte @isr_rcc + 1                 ; RCC global interrupt
    .qbyte @isr_exti0 + 1               ; EXTI Line0 interrupt 
    .qbyte @isr_exti1 + 1               ; EXTI Line1 interrupt
    .qbyte @isr_exti2 + 1               ; EXTI Line2 interrupt
    .qbyte @isr_exti3 + 1               ; EXTI Line3 interrupt
    .qbyte @isr_exti4 + 1               ; EXTI Line4 interrupt
    .qbyte @isr_dma1_channel1 + 1       ; DMA1 channel 1 interrupt
    .qbyte @isr_dma1_channel2 + 1       ; DMA1 channel 2 interrupt
    .qbyte @isr_dma1_channel3 + 1       ; DMA1 channel 3 interrupt
    .qbyte @isr_dma1_channel4 + 1       ; DMA1 channel 4 interrupt
    .qbyte @isr_dma1_channel5 + 1       ; DMA1 channel 5 interrupt
    .qbyte @isr_dma1_channel6 + 1       ; DMA1 channel 6 interrupt
    .qbyte @isr_dma1_channel7 + 1       ; DMA1 channel 7 interrupt
    .qbyte @isr_adc + 1                 ; ADC1 and ADC2 global interrupts
    .qbyte @isr_can1_tx + 1             ; CAN1 TX interrupts
    .qbyte @isr_can1_rx0 + 1            ; CAN1 RX0 interrupts
    .qbyte @isr_can1_rx1 + 1            ; CAN1 RX1 interrupts
    .qbyte @isr_can1_sce + 1            ; CAN1 SCE interrupt
    .qbyte @isr_exti9_5 + 1             ; EXTI Line[9:5] interrupts
    .qbyte @isr_tim1_brk_tim9 + 1       ; TIM1 Break interrupt and TIM9 global interrupt
    .qbyte @isr_tim1_up_tim10 + 1       ; TIM1 Update interrupt and TIM10 global interrupt
    .qbyte @isr_tim1_trg_com_tim11  + 1 ; TIM1 Trigger and Commutation interrupts and TIM11 global interrupt
    .qbyte @isr_tim1_cc + 1             ; TIM1 Capture Compare interrupt
    .qbyte @isr_tim2 + 1                ; TIM2 global interrupt
    .qbyte @isr_tim3 + 1                ; TIM3 global interrupt
    .qbyte 0x00                         ; Reserved.
    .qbyte @isr_i2c1_ev + 1             ; I2C1 event interrupt
    .qbyte @isr_i2c1_er + 1             ; I2C1 error interrupt
    .qbyte @isr_i2c2_ev + 1             ; I2C2 event interrupt
    .qbyte @isr_i2c2_er + 1             ; I2C2 error interrupt
    .qbyte @isr_spi1 + 1                ; SPI1 global interrupt
    .qbyte @isr_spi2 + 1                ; SPI2 global interrupt
    .qbyte @isr_usart1 + 1              ; USART1 global interrupt
    .qbyte @isr_usart2 + 1              ; USART2 global interrupt
    .qbyte @isr_usart3 + 1              ; USART3 global interrupt
    .qbyte @isr_exti15_10 + 1           ; EXTI Line[15:10] interrupts
    .qbyte @isr_rtc_alarm + 1           ; RTC Alarms (A and B) through EXTI line interrupt
    .qbyte 0x00                         ; Reserved.
    .qbyte 0x00                         ; Reserved.
    .qbyte 0x00                         ; Reserved.
    .qbyte 0x00                         ; Reserved.
    .qbyte 0x00                         ; Reserved.
    .qbyte 0x00                         ; Reserved.
    .qbyte 0x00                         ; Reserved.
    .qbyte @isr_sdmmc1 + 1              ; SDMMC1 global interrupt
    .qbyte 0x00                         ; Reserved.
    .qbyte @isr_spi3 + 1                ; SPI3 global interrupt
    .qbyte @isr_uart4 + 1               ; UART4 global interrupt
    .qbyte 0x00                         ; Reserved.
    .qbyte @isr_tim6_dac + 1            ; TIM6 global and DAC1 underrun interrupts
    .qbyte @isr_tim7 + 1                ; TIM7 global interrupt
    .qbyte @isr_dma2_channel1 + 1       ; DMA2 channel 1 interrupt
    .qbyte @isr_dma2_channel2 + 1       ; DMA2 channel 2 interrupt
    .qbyte @isr_dma2_channel3 + 1       ; DMA2 channel 3 interrupt
    .qbyte @isr_dma2_channel4 + 1       ; DMA2 channel 4 interrupt
    .qbyte @isr_dma2_channel5 + 1       ; DMA2 channel 5 interrupt
    .qbyte @isr_dfsdm1_flt0 + 1         ; DFSDM1_FLT0 global interrupt
    .qbyte @isr_dfsdm1_flt1 + 1         ; DFSDM1_FLT1 global interrupt
    .qbyte 0x00                         ; Reserved.
    .qbyte @isr_comp + 1                ; COMP1/COMP2(1) through EXTI lines 21/22 interrupts
    .qbyte @isr_lptim1 + 1              ; LPTIM1 global interrupt
    .qbyte @isr_lptim2 + 1              ; LPTIM2 global interrupt
    .qbyte @isr_otg_fs + 1              ; USB On The Go FS global interrupt
    .qbyte @isr_dma2_channel6 + 1       ; DMA2 channel 6 interrupt
    .qbyte @isr_dma2_channel7 + 1       ; DMA2 channel 7 interrupt
    .qbyte @isr_lpuart1 + 1             ; LPUART1 global interrupt
    .qbyte @isr_quadspi + 1             ; QUADSPI global interrupt
    .qbyte @isr_i2c3_ev + 1             ; I2C3 event interrupt
    .qbyte @isr_i2c3_er + 1             ; I2C3 error interrupt
    .qbyte @isr_sai1 + 1                ; SAI1 global interrupt
    .qbyte 0x00                         ; Reserved.
    .qbyte @isr_swpmi1 + 1              ; SWPMI1 global interrupt
    .qbyte @isr_tsc + 1                 ; TSC global interrupt
    .qbyte @isr_lcd + 1                 ; LCD global interrupt
    .qbyte @isr_aes + 1                 ; AES global interrupt
    .qbyte @isr_rng + 1                 ; RNG global interrupt
    .qbyte @isr_fpu + 1                 ; FPU global interrupt
    .qbyte @isr_crs + 1                 ; CRS interrupt
    .qbyte @isr_i2c4_ev + 1             ; I2C4 event interrupt, wakeup through EXTI line 40
    .qbyte @isr_i2c4_er + 1             ; I2C4 error interrupt
    #repeat 27                          ; Pad to 128 word size
        .qbyte 0x00                     ; Reserved
    #endrep

#define exception_code
	.code #0
		.replaceable
        .alignment    4
        bkpt    0x00        ; try to go to debugger
loop:   b.n    loop         ; loop forever if return from bkpt
#enddef
	exception_code	isr_nmi
    exception_code	isr_hardfault
    exception_code	isr_memmanage
    exception_code	isr_busfault
    exception_code	isr_usagefault
#undef exception_code

#define isr_code
	.code #0
		.replaceable
        .alignment    4
        bx.n	 lr   ; ignore interrupt
#enddef
    isr_code    isr_svc
    isr_code    isr_debugmonitor
    isr_code    isr_pendsvc
    isr_code	isr_systick
	isr_code	isr_wwdg
    isr_code	isr_pvd
    isr_code	isr_tamp_stamp
    isr_code	isr_rtc_wkup
    isr_code	isr_flash
    isr_code	isr_rcc
    isr_code	isr_exti0
    isr_code	isr_exti1
    isr_code	isr_exti2
    isr_code	isr_exti3
    isr_code	isr_exti4
    isr_code	isr_dma1_channel1
    isr_code	isr_dma1_channel2
    isr_code	isr_dma1_channel3
    isr_code	isr_dma1_channel4
    isr_code	isr_dma1_channel5
    isr_code	isr_dma1_channel6
    isr_code	isr_dma1_channel7
    isr_code	isr_adc
    isr_code	isr_can1_tx
    isr_code	isr_can1_rx0
    isr_code	isr_can1_rx1
    isr_code	isr_can1_sce
    isr_code	isr_exti9_5
    isr_code	isr_tim1_brk_tim9
    isr_code	isr_tim1_up_tim10
    isr_code	isr_tim1_trg_com_tim11
    isr_code	isr_tim1_cc
    isr_code	isr_tim2
    isr_code	isr_tim3
    isr_code	isr_i2c1_ev
    isr_code	isr_i2c1_er
    isr_code	isr_i2c2_ev
    isr_code	isr_i2c2_er
    isr_code	isr_spi1
    isr_code	isr_spi2
    isr_code	isr_usart1
    isr_code	isr_usart2
    isr_code	isr_usart3
    isr_code	isr_exti15_10
    isr_code	isr_rtc_alarm
    isr_code	isr_sdmmc1
    isr_code	isr_spi3
    isr_code	isr_uart4
    isr_code	isr_tim6_dac
    isr_code	isr_tim7
    isr_code	isr_dma2_channel1
    isr_code	isr_dma2_channel2
    isr_code	isr_dma2_channel3
    isr_code	isr_dma2_channel4
    isr_code	isr_dma2_channel5
    isr_code	isr_dfsdm1_flt0
    isr_code	isr_dfsdm1_flt1
    isr_code	isr_comp
    isr_code	isr_lptim1
    isr_code	isr_lptim2
    isr_code	isr_otg_fs
    isr_code	isr_dma2_channel6
    isr_code	isr_dma2_channel7
    isr_code	isr_lpuart1
    isr_code	isr_quadspi
    isr_code	isr_i2c3_ev
    isr_code	isr_i2c3_er
    isr_code	isr_sai1
    isr_code	isr_swpmi1
    isr_code	isr_tsc
    isr_code	isr_lcd
    isr_code	isr_aes
    isr_code	isr_rng
    isr_code	isr_fpu
    isr_code    isr_crs
    isr_code    isr_i2c4_ev
    isr_code    isr_i2c4_er
#undef isr_code

.data ram
	.required
	.origin	    0x20000000 ; ram start
    .require	_init_ram

.initdata _init_ram
    .alignment    4

    mov     r0, 0
	ldr	    r1, [pc, offset (start)]
    ldr     r2, [pc, offset (ext)]
    b       cond
start:  .qbyte	0x20000000
ext:    .qbyte  extent (@_trailer)
loop:    
    str     r0, [r1]
    add     r1, r1, 4
cond:
    cmp     r1, r2
    bcc     loop

; last section
.trailer _trailer

; standard abort function
.code abort
    .replaceable
    .alignment    4
loop:
    b.n    loop

; standard _Exit function
.code _Exit
    .alignment    4
	bl       @abort

; standard getchar function
.code getchar
    .replaceable
    .alignment    4
    bx.n	 lr

; standard free function
.code free
    .replaceable
    .alignment    4
	bx.n	lr

; standard malloc function
.code malloc
    .replaceable
    .alignment    4

    ldr.n   r2, offset (heap) + offset (heap) % 4
	ldr.n	r0, [r2, 0]
	ldr.n	r3, [sp, 0]

    ; round up to nearest word
    mov	r1, 3
	add	r4, r3, r1
    mov	r1, 4
	rsb	r1, 0
	and	r3, r4, r1

	add.n	r3, r3, r0
	str.n	r3, [r2, 0]
	bx.n	lr

heap:	.qbyte	@_heap_start

; heap start
.data _heap_start

	.alignment	4
	.reserve	4
	.require	_init_heap

.initdata _init_heap
    .alignment    4

	ldr	    r0, [pc, offset (heap)]
    ldr     r3, [pc, offset (start)]

    ; round up to nearest word
    mov	r1, 3
	add	r4, r3, r1
    mov	r1, 4
	rsb	r1, 0
	and	r3, r4, r1
    
	str	    r3, [r0, 0]
	b	    skip
heap:   .qbyte	@_heap_start
start:  .qbyte  extent (@_trailer)
skip:

; standard putchar function
.code putchar
    .replaceable
    .alignment    4
    bx.n	 lr

; system idle function, defaults to nop
.code sysidle
    .replaceable
    .alignment    4
    bx.n	 lr
