; RM0522, Reference manual STM32C5xxxx
.code vector
    .required
    .origin {BOOTSTART}                 ; Flash start address

    .qbyte {RAMSTART} + {RAMSIZE}       ; Stack = ram top
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

    ; Start of STM32C5
    .qbyte @isr_wwdg + 1                ; Window Watchdog interrupt
    .qbyte @isr_pvd + 1                 ; PVD global interrupt
    .qbyte @isr_rtc + 1                 ; RTC global interrupt
    .qbyte @isr_tamp + 1                ; Tamper global interrupt
    .qbyte @isr_ramcfg + 1              ; RAM configuration global interrupt
    .qbyte @isr_flash + 1               ; Flash global interrupt
    .qbyte @isr_rcc + 1                 ; RCC global interrupt
    .qbyte @isr_exti0 + 1               ; EXTI Line0 interrupt 
    .qbyte @isr_exti1 + 1               ; EXTI Line1 interrupt
    .qbyte @isr_exti2 + 1               ; EXTI Line2 interrupt
    .qbyte @isr_exti3 + 1               ; EXTI Line3 interrupt
    .qbyte @isr_exti4 + 1               ; EXTI Line4 interrupt
    .qbyte @isr_exti5 + 1               ; EXTI Line5 interrupt
    .qbyte @isr_exti6 + 1               ; EXTI Line6 interrupt
    .qbyte @isr_exti7 + 1               ; EXTI Line7 interrupt
    .qbyte @isr_exti8 + 1               ; EXTI Line8 interrupt
    .qbyte @isr_exti9 + 1               ; EXTI Line9 interrupt
    .qbyte @isr_exti10 + 1              ; EXTI Line10 interrupt
    .qbyte @isr_exti11 + 1              ; EXTI Line11 interrupt
    .qbyte @isr_exti12 + 1              ; EXTI Line12 interrupt
    .qbyte @isr_exti13 + 1              ; EXTI Line13 interrupt
    .qbyte @isr_exti14 + 1              ; EXTI Line14 interrupt
    .qbyte @isr_exti15 + 1              ; EXTI Line15 interrupt
    .qbyte @isr_lpdma1_channel0 + 1     ; LPDMA1 channel0 global interrupt
    .qbyte @isr_lpdma1_channel1 + 1     ; LPDMA1 channel1 global interrupt
    .qbyte @isr_lpdma1_channel2 + 1     ; LPDMA1 channel2 global interrupt
    .qbyte @isr_lpdma1_channel3 + 1     ; LPDMA1 channel3 global interrupt
    .qbyte @isr_lpdma1_channel4 + 1     ; LPDMA1 channel4 global interrupt
    .qbyte @isr_lpdma1_channel5 + 1     ; LPDMA1 channel5 global interrupt
    .qbyte @isr_lpdma1_channel6 + 1     ; LPDMA1 channel6 global interrupt
    .qbyte @isr_lpdma1_channel7 + 1     ; LPDMA1 channel7 global interrupt
    .qbyte @isr_iwdg + 1                ; Independent watchdog interrupt
    .qbyte @isr_adc1 + 1                ; ADC1 global interrupt
    .qbyte @isr_adc2 + 1                ; ADC2 global interrupt
    .qbyte @isr_fdcan1_it0 + 1          ; FDCAN1 Interrupt 0
    .qbyte @isr_fdcan1_it1 + 1          ; FDCAN1 Interrupt 1
    .qbyte @isr_tim1_brk_err + 1        ; TIM1 Break/TIM1 transition error/TIM1 Index error
    .qbyte @isr_tim1_up + 1             ; TIM1 update
    .qbyte @isr_tim1_trg + 1            ; TIM1 trigger and commutation/TIM1 direction change interrupt/TIM1 Index
    .qbyte @isr_tim1_cc + 1             ; TIM1 capture compare interrupt
    .qbyte @isr_tim2 + 1                ; TIM1 global interrupt
    .qbyte @isr_tim5 + 1                ; TIM5 global interrupt
    .qbyte @isr_tim6 + 1                ; TIM6 global interrupt
    .qbyte @isr_tim7 + 1                ; TIM7 global interrupt
    .qbyte @isr_i2c1_ev + 1             ; I2C1 event interrupt
    .qbyte @isr_i2c1_er + 1             ; I2C1 error interrupt
    .qbyte @isr_i3c1_ev + 1             ; I3C1 event interrupt
    .qbyte @isr_i3c1_er + 1             ; I3C1 error interrupt
    .qbyte @isr_spi1 + 1                ; SPI1 global interrupt
    .qbyte @isr_spi2 + 1                ; SPI2 global interrupt
    .qbyte @isr_spi3 + 1                ; SPI3 global interrupt
    .qbyte @isr_usart1 + 1              ; USART1 global interrupt
    .qbyte @isr_usart2 + 1              ; USART2 global interrupt
    .qbyte @isr_usart3 + 1              ; USART3 global interrupt
    .qbyte @isr_usart4 + 1              ; USART4 global interrupt
    .qbyte @isr_usart5 + 1              ; USART5 global interrupt
    .qbyte @isr_lpuart1 + 1             ; LPUART1 global interrupt
    .qbyte @isr_lptim1 + 1              ; LPTIM1 global interrupt
    .qbyte @isr_tim12 + 1               ; TIM12 global interrupt
    .qbyte @isr_tim15 + 1               ; TIM15 global interrupt
    .qbyte @isr_tim16 + 1               ; TIM16 global interrupt
    .qbyte @isr_tim17 + 1               ; TIM17 global interrupt
    .qbyte @isr_usb_fs + 1              ; USB FS global interrupt
    .qbyte @isr_crs + 1                 ; Clock recovery system global interrupt
    .qbyte @isr_rng + 1                 ; RNG global interrupt
    .qbyte @isr_fpu + 1                 ; Floating point interrupt
    .qbyte @isr_icache + 1              ; Instruction cache global interrupt
    .qbyte @isr_cordic + 1              ; CORDIC interrupt
    .qbyte @isr_aes + 1                 ; AES global interrupt
    .qbyte @isr_hash + 1                ; HASH interrupt
    .qbyte @isr_i2c2_ev + 1             ; I2C2 event interrupt
    .qbyte @isr_i2c2_er + 1             ; I2C2 error interrupt
    .qbyte @isr_tim8_brk_err + 1        ; TIM8 Break/TIM8 transition error/TIM8 Index error
    .qbyte @isr_tim8_up + 1             ; TIM8 update
    .qbyte @isr_tim8_trg + 1            ; TIM8 trigger and commutation/TIM8 direction change interrupt/TIM8 Index
    .qbyte @isr_tim8_cc + 1             ; TIM8 capture compare interrupt
    .qbyte @isr_comp1 + 1               ; COMP1 global interrupt OR COMP1 through EXTI line
    .qbyte @isr_dac1 + 1                ; DAC1 global interrupt
    .qbyte @isr_lpdma2_channel0 + 1     ; LPDMA2 channel0 global interrupt
    .qbyte @isr_lpdma2_channel1 + 1     ; LPDMA2 channel1 global interrupt
    .qbyte @isr_lpdma2_channel2 + 1     ; LPDMA2 channel2 global interrupt
    .qbyte @isr_lpdma2_channel3 + 1     ; LPDMA2 channel3 global interrupt
    .qbyte @isr_lpdma2_channel4 + 1     ; LPDMA2 channel4 global interrupt
    .qbyte @isr_lpdma2_channel5 + 1     ; LPDMA2 channel5 global interrupt
    .qbyte @isr_lpdma2_channel6 + 1     ; LPDMA2 channel6 global interrupt
    .qbyte @isr_lpdma2_channel7 + 1     ; LPDMA2 channel7 global interrupt
    .qbyte @isr_fdcan2_it0 + 1          ; FDCAN2 Interrupt 0
    .qbyte @isr_fdcan2_it1 + 1          ; FDCAN2 Interrupt 1
    .qbyte @isr_comp2 + 1               ; COMP2 global interrupt OR COMP2 through EXTI line
    .qbyte @isr_tim3 + 1                ; TIM3 global interrupt
    .qbyte @isr_tim4 + 1                ; TIM4 global interrupt
    .qbyte @isr_xspi1 + 1               ; XSPI1 global interrupt
    .qbyte @isr_saes + 1                ; SAES global interrupt
    .qbyte @isr_pka + 1                 ; PKA global interrupt
    .qbyte @isr_eth1 + 1                ; ETH interrupt
    .qbyte @isr_eth1_wkup + 1           ; ETH interrupt Ethernet wakeup interrupt through EXTI line
    .qbyte @isr_usart6 + 1              ; USART6 global interrupt
    .qbyte @isr_uart7 + 1               ; UART7 global interrupt
    .qbyte @isr_adc3 + 1                ; ADC3 global interrupt
    #repeat 12                          ; Pad to 128 word size
        .qbyte 0x00                     ; Reserved
    #endrep
                                        ; Oberon code starts here
#define exception_code
  .code #0
    .replaceable
        .alignment    4
        bkpt    0x00        ; try to go to debugger
loop:   b.n    loop         ; loop forever if return from bkpt
#enddef
    exception_code  isr_nmi
    exception_code  isr_hardfault
    exception_code  isr_memmanage
    exception_code  isr_busfault
    exception_code  isr_usagefault
#undef exception_code

#define isr_code
  .code #0
    .replaceable
        .alignment    4
        bx.n   lr   ; ignore interrupt
#enddef
    isr_code  isr_svc
    isr_code  isr_debugmonitor
    isr_code  isr_pendsvc
    isr_code  isr_systick
    isr_code  isr_wwdg       
    isr_code  isr_pvd        
    isr_code  isr_rtc        
    isr_code  isr_tamp       
    isr_code  isr_ramcfg     
    isr_code  isr_flash      
    isr_code  isr_rcc        
    isr_code  isr_exti0      
    isr_code  isr_exti1      
    isr_code  isr_exti2      
    isr_code  isr_exti3      
    isr_code  isr_exti4      
    isr_code  isr_exti5      
    isr_code  isr_exti6      
    isr_code  isr_exti7      
    isr_code  isr_exti8      
    isr_code  isr_exti9      
    isr_code  isr_exti10     
    isr_code  isr_exti11     
    isr_code  isr_exti12     
    isr_code  isr_exti13     
    isr_code  isr_exti14     
    isr_code  isr_exti15     
    isr_code  isr_lpdma1_channel0
    isr_code  isr_lpdma1_channel1
    isr_code  isr_lpdma1_channel2
    isr_code  isr_lpdma1_channel3
    isr_code  isr_lpdma1_channel4
    isr_code  isr_lpdma1_channel5
    isr_code  isr_lpdma1_channel6
    isr_code  isr_lpdma1_channel7
    isr_code  isr_iwdg       
    isr_code  isr_adc1       
    isr_code  isr_adc2       
    isr_code  isr_fdcan1_it0 
    isr_code  isr_fdcan1_it1 
    isr_code  isr_tim1_brk_err
    isr_code  isr_tim1_up    
    isr_code  isr_tim1_trg   
    isr_code  isr_tim1_cc    
    isr_code  isr_tim2       
    isr_code  isr_tim5       
    isr_code  isr_tim6       
    isr_code  isr_tim7       
    isr_code  isr_i2c1_ev    
    isr_code  isr_i2c1_er    
    isr_code  isr_i3c1_ev    
    isr_code  isr_i3c1_er    
    isr_code  isr_spi1       
    isr_code  isr_spi2       
    isr_code  isr_spi3       
    isr_code  isr_usart1     
    isr_code  isr_usart2     
    isr_code  isr_usart3     
    isr_code  isr_usart4     
    isr_code  isr_usart5     
    isr_code  isr_lpuart1    
    isr_code  isr_lptim1     
    isr_code  isr_tim12      
    isr_code  isr_tim15      
    isr_code  isr_tim16      
    isr_code  isr_tim17      
    isr_code  isr_usb_fs     
    isr_code  isr_crs        
    isr_code  isr_rng        
    isr_code  isr_fpu        
    isr_code  isr_icache     
    isr_code  isr_cordic     
    isr_code  isr_aes        
    isr_code  isr_hash       
    isr_code  isr_i2c2_ev    
    isr_code  isr_i2c2_er    
    isr_code  isr_tim8_brk_err
    isr_code  isr_tim8_up    
    isr_code  isr_tim8_trg   
    isr_code  isr_tim8_cc    
    isr_code  isr_comp1      
    isr_code  isr_dac1       
    isr_code  isr_lpdma2_channel0
    isr_code  isr_lpdma2_channel1
    isr_code  isr_lpdma2_channel2
    isr_code  isr_lpdma2_channel3
    isr_code  isr_lpdma2_channel4
    isr_code  isr_lpdma2_channel5
    isr_code  isr_lpdma2_channel6
    isr_code  isr_lpdma2_channel7
    isr_code  isr_fdcan2_it0 
    isr_code  isr_fdcan2_it1 
    isr_code  isr_comp2      
    isr_code  isr_tim3       
    isr_code  isr_tim4       
    isr_code  isr_xspi1      
    isr_code  isr_saes       
    isr_code  isr_pka        
    isr_code  isr_eth1       
    isr_code  isr_eth1_wkup  
    isr_code  isr_usart6     
    isr_code  isr_uart7      
    isr_code  isr_adc3
#undef isr_code

.data ram
  .required
  .origin     {RAMSTART}
    .require  _init_ram

.initdata _init_ram
    .alignment    4

    mov     r0, 0
    ldr     r1, [pc, offset (start)]
    ldr     r2, [pc, offset (ext)]
    b       cond
start:  .qbyte  {RAMSTART}
ext:    .qbyte  extent (@_trailer)
loop:    
    str     r0, [r1]
    add     r1, r1, 4
cond:
    cmp     r1, r2
    bcc     loop

; last section
.trailer _trailer

; heap start
.data _heap_start

  .alignment  4
  .reserve  4
  .require  _init_heap

.initdata _init_heap
    .alignment    4

    ldr     r0, [pc, offset (heap)]
    ldr     r3, [pc, offset (start)]

    ; round up to nearest word
    mov r1, 3
    add r4, r3, r1
    mov r1, 4
    rsb r1, 0
    and r3, r4, r1
    
    str     r3, [r0, 0]
    b     skip
heap:   .qbyte  @_heap_start
start:  .qbyte  extent (@_trailer)
skip:
