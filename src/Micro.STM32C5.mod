MODULE STM32C5 IN Micro;
(*
    RM0522, Reference manual STM32C5xxxx
*)
IMPORT SYSTEM;
IN Micro IMPORT ARMv8M;

TYPE ADDRESS = SYSTEM.ADDRESS;

CONST
    (* memory map *)
    BootStart* = ADDRESS(0H);
    FlashStart* = ADDRESS(8000000H);
    SRAMStart* = ADDRESS(20000000H);
    (* APB1 *)
        USART2* = ADDRESS(40004400H);
            USART2_CR1*   = ADDRESS(USART2 + 0);
            USART2_CR2*   = ADDRESS(USART2 + 4);
            USART2_CR3*   = ADDRESS(USART2 + 8);
            USART2_BRR*   = ADDRESS(USART2 + 0CH);
            USART2_GTPR*  = ADDRESS(USART2 + 10H);
            USART2_RTOR*  = ADDRESS(USART2 + 14H);
            USART2_RQR*   = ADDRESS(USART2 + 18H);
            USART2_ISR*   = ADDRESS(USART2 + 1CH);
            USART2_ICR*   = ADDRESS(USART2 + 20H);
            USART2_RDR*   = ADDRESS(USART2 + 24H);
            USART2_TDR*   = ADDRESS(USART2 + 28H);
            USART2_PRESC* = ADDRESS(USART2 + 2CH);
        USART3* = ADDRESS(40004800H);
            USART3_CR1*   = ADDRESS(USART3 + 0);
            USART3_CR2*   = ADDRESS(USART3 + 4);
            USART3_CR3*   = ADDRESS(USART3 + 8);
            USART3_BRR*   = ADDRESS(USART3 + 0CH);
            USART3_GTPR*  = ADDRESS(USART3 + 10H);
            USART3_RTOR*  = ADDRESS(USART3 + 14H);
            USART3_RQR*   = ADDRESS(USART3 + 18H);
            USART3_ISR*   = ADDRESS(USART3 + 1CH);
            USART3_ICR*   = ADDRESS(USART3 + 20H);
            USART3_RDR*   = ADDRESS(USART3 + 24H);
            USART3_TDR*   = ADDRESS(USART3 + 28H);
            USART3_PRESC* = ADDRESS(USART3 + 2CH);
        UART4* = ADDRESS(40004C00H);
            UART4_CR1*   = ADDRESS(UART4 + 0);
            UART4_CR2*   = ADDRESS(UART4 + 4);
            UART4_CR3*   = ADDRESS(UART4 + 8);
            UART4_BRR*   = ADDRESS(UART4 + 0CH);
            UART4_GTPR*  = ADDRESS(UART4 + 10H);
            UART4_RTOR*  = ADDRESS(UART4 + 14H);
            UART4_RQR*   = ADDRESS(UART4 + 18H);
            UART4_ISR*   = ADDRESS(UART4 + 1CH);
            UART4_ICR*   = ADDRESS(UART4 + 20H);
            UART4_RDR*   = ADDRESS(UART4 + 24H);
            UART4_TDR*   = ADDRESS(UART4 + 28H);
            UART4_PRESC* = ADDRESS(UART4 + 2CH);
        UART5* = ADDRESS(40005000H);
            UART5_CR1*   = ADDRESS(UART5 + 0);
            UART5_CR2*   = ADDRESS(UART5 + 4);
            UART5_CR3*   = ADDRESS(UART5 + 8);
            UART5_BRR*   = ADDRESS(UART5 + 0CH);
            UART5_GTPR*  = ADDRESS(UART5 + 10H);
            UART5_RTOR*  = ADDRESS(UART5 + 14H);
            UART5_RQR*   = ADDRESS(UART5 + 18H);
            UART5_ISR*   = ADDRESS(UART5 + 1CH);
            UART5_ICR*   = ADDRESS(UART5 + 20H);
            UART5_RDR*   = ADDRESS(UART5 + 24H);
            UART5_TDR*   = ADDRESS(UART5 + 28H);
            UART5_PRESC* = ADDRESS(UART5 + 2CH);
        USART6* = ADDRESS(40006400H);
            USART6_CR1*   = ADDRESS(USART6 + 0);
            USART6_CR2*   = ADDRESS(USART6 + 4);
            USART6_CR3*   = ADDRESS(USART6 + 8);
            USART6_BRR*   = ADDRESS(USART6 + 0CH);
            USART6_GTPR*  = ADDRESS(USART6 + 10H);
            USART6_RTOR*  = ADDRESS(USART6 + 14H);
            USART6_RQR*   = ADDRESS(USART6 + 18H);
            USART6_ISR*   = ADDRESS(USART6 + 1CH);
            USART6_ICR*   = ADDRESS(USART6 + 20H);
            USART6_RDR*   = ADDRESS(USART6 + 24H);
            USART6_TDR*   = ADDRESS(USART6 + 28H);
            USART6_PRESC* = ADDRESS(USART6 + 2CH);
        UART7* = ADDRESS(40007800H);
            UART7_CR1*   = ADDRESS(UART7 + 0);
            UART7_CR2*   = ADDRESS(UART7 + 4);
            UART7_CR3*   = ADDRESS(UART7 + 8);
            UART7_BRR*   = ADDRESS(UART7 + 0CH);
            UART7_GTPR*  = ADDRESS(UART7 + 10H);
            UART7_RTOR*  = ADDRESS(UART7 + 14H);
            UART7_RQR*   = ADDRESS(UART7 + 18H);
            UART7_ISR*   = ADDRESS(UART7 + 1CH);
            UART7_ICR*   = ADDRESS(UART7 + 20H);
            UART7_RDR*   = ADDRESS(UART7 + 24H);
            UART7_TDR*   = ADDRESS(UART7 + 28H);
            UART7_PRESC* = ADDRESS(UART7 + 2CH);
    (* APB2 *)
        USART1* = ADDRESS(40013800H);
            USART1_CR1*   = ADDRESS(USART1 + 0);
            USART1_CR2*   = ADDRESS(USART1 + 4);
            USART1_CR3*   = ADDRESS(USART1 + 8);
            USART1_BRR*   = ADDRESS(USART1 + 0CH);
            USART1_GTPR*  = ADDRESS(USART1 + 10H);
            USART1_RTOR*  = ADDRESS(USART1 + 14H);
            USART1_RQR*   = ADDRESS(USART1 + 18H);
            USART1_ISR*   = ADDRESS(USART1 + 1CH);
            USART1_ICR*   = ADDRESS(USART1 + 20H);
            USART1_RDR*   = ADDRESS(USART1 + 24H);
            USART1_TDR*   = ADDRESS(USART1 + 28H);
            USART1_PRESC* = ADDRESS(USART1 + 2CH);
    (* AHB1 *)
        FlashInterface*     = ADDRESS(40022000H); (* Flash interface register *)
			FLASH_ACR*      = ADDRESS(FlashInterface + 0);
    (* AHB2 *)
        GPIOA* = ADDRESS(42020000H);
            GPIOA_MODER*     = ADDRESS(GPIOA + 0);
            GPIOA_OTYPER*    = ADDRESS(GPIOA + 4);
            GPIOA_OSPEEDR*   = ADDRESS(GPIOA + 8);
            GPIOA_PUPDR*     = ADDRESS(GPIOA + 0CH);
            GPIOA_IDR*       = ADDRESS(GPIOA + 10H);
            GPIOA_ODR*       = ADDRESS(GPIOA + 14H);
            GPIOA_BSRR*      = ADDRESS(GPIOA + 18H);
            GPIOA_LCKR*      = ADDRESS(GPIOA + 1CH);
            GPIOA_AFRL*      = ADDRESS(GPIOA + 20H);
            GPIOA_AFRH*      = ADDRESS(GPIOA + 24H);
        GPIOB* = ADDRESS(42020400H);
            GPIOB_MODER*     = ADDRESS(GPIOB + 0);
            GPIOB_OTYPER*    = ADDRESS(GPIOB + 4);
            GPIOB_OSPEEDR*   = ADDRESS(GPIOB + 8);
            GPIOB_PUPDR*     = ADDRESS(GPIOB + 0CH);
            GPIOB_IDR*       = ADDRESS(GPIOB + 10H);
            GPIOB_ODR*       = ADDRESS(GPIOB + 14H);
            GPIOB_BSRR*      = ADDRESS(GPIOB + 18H);
            GPIOB_LCKR*      = ADDRESS(GPIOB + 1CH);
            GPIOB_AFRL*      = ADDRESS(GPIOB + 20H);
            GPIOB_AFRH*      = ADDRESS(GPIOB + 24H);
        GPIOC* = ADDRESS(42020800H);
            GPIOC_MODER*     = ADDRESS(GPIOC + 0);
            GPIOC_OTYPER*    = ADDRESS(GPIOC + 4);
            GPIOC_OSPEEDR*   = ADDRESS(GPIOC + 8);
            GPIOC_PUPDR*     = ADDRESS(GPIOC + 0CH);
            GPIOC_IDR*       = ADDRESS(GPIOC + 10H);
            GPIOC_ODR*       = ADDRESS(GPIOC + 14H);
            GPIOC_BSRR*      = ADDRESS(GPIOC + 18H);
            GPIOC_LCKR*      = ADDRESS(GPIOC + 1CH);
            GPIOC_AFRL*      = ADDRESS(GPIOC + 20H);
            GPIOC_AFRH*      = ADDRESS(GPIOC + 24H);
        GPIOD* = ADDRESS(42020C00H);
            GPIOD_MODER*     = ADDRESS(GPIOD + 0);
            GPIOD_OTYPER*    = ADDRESS(GPIOD + 4);
            GPIOD_OSPEEDR*   = ADDRESS(GPIOD + 8);
            GPIOD_PUPDR*     = ADDRESS(GPIOD + 0CH);
            GPIOD_IDR*       = ADDRESS(GPIOD + 10H);
            GPIOD_ODR*       = ADDRESS(GPIOD + 14H);
            GPIOD_BSRR*      = ADDRESS(GPIOD + 18H);
            GPIOD_LCKR*      = ADDRESS(GPIOD + 1CH);
            GPIOD_AFRL*      = ADDRESS(GPIOD + 20H);
            GPIOD_AFRH*      = ADDRESS(GPIOD + 24H);
        GPIOE* = ADDRESS(42021000H);
            GPIOE_MODER*     = ADDRESS(GPIOE + 0);
            GPIOE_OTYPER*    = ADDRESS(GPIOE + 4);
            GPIOE_OSPEEDR*   = ADDRESS(GPIOE + 8);
            GPIOE_PUPDR*     = ADDRESS(GPIOE + 0CH);
            GPIOE_IDR*       = ADDRESS(GPIOE + 10H);
            GPIOE_ODR*       = ADDRESS(GPIOE + 14H);
            GPIOE_BSRR*      = ADDRESS(GPIOE + 18H);
            GPIOE_LCKR*      = ADDRESS(GPIOE + 1CH);
            GPIOE_AFRL*      = ADDRESS(GPIOE + 20H);
            GPIOE_AFRH*      = ADDRESS(GPIOE + 24H);
        GPIOF* = ADDRESS(42021400H);
            GPIOF_MODER*     = ADDRESS(GPIOF + 0);
            GPIOF_OTYPER*    = ADDRESS(GPIOF + 4);
            GPIOF_OSPEEDR*   = ADDRESS(GPIOF + 8);
            GPIOF_PUPDR*     = ADDRESS(GPIOF + 0CH);
            GPIOF_IDR*       = ADDRESS(GPIOF + 10H);
            GPIOF_ODR*       = ADDRESS(GPIOF + 14H);
            GPIOF_BSRR*      = ADDRESS(GPIOF + 18H);
            GPIOF_LCKR*      = ADDRESS(GPIOF + 1CH);
            GPIOF_AFRL*      = ADDRESS(GPIOF + 20H);
            GPIOF_AFRH*      = ADDRESS(GPIOF + 24H);
        GPIOG* = ADDRESS(42021800H);
            GPIOG_MODER*     = ADDRESS(GPIOG + 0);
            GPIOG_OTYPER*    = ADDRESS(GPIOG + 4);
            GPIOG_OSPEEDR*   = ADDRESS(GPIOG + 8);
            GPIOG_PUPDR*     = ADDRESS(GPIOG + 0CH);
            GPIOG_IDR*       = ADDRESS(GPIOG + 10H);
            GPIOG_ODR*       = ADDRESS(GPIOG + 14H);
            GPIOG_BSRR*      = ADDRESS(GPIOG + 18H);
            GPIOG_LCKR*      = ADDRESS(GPIOG + 1CH);
            GPIOG_AFRL*      = ADDRESS(GPIOG + 20H);
            GPIOG_AFRH*      = ADDRESS(GPIOG + 24H);
        GPIOH* = ADDRESS(42021C00H);
            GPIOH_MODER*     = ADDRESS(GPIOH + 0);
            GPIOH_OTYPER*    = ADDRESS(GPIOH + 4);
            GPIOH_OSPEEDR*   = ADDRESS(GPIOH + 8);
            GPIOH_PUPDR*     = ADDRESS(GPIOH + 0CH);
            GPIOH_IDR*       = ADDRESS(GPIOH + 10H);
            GPIOH_ODR*       = ADDRESS(GPIOH + 14H);
            GPIOH_BSRR*      = ADDRESS(GPIOH + 18H);
            GPIOH_LCKR*      = ADDRESS(GPIOH + 1CH);
            GPIOH_AFRL*      = ADDRESS(GPIOH + 20H);
            GPIOH_AFRH*      = ADDRESS(GPIOH + 24H);
    (* AHB3 *)
        PWR* = ADDRESS(44020800H);
			PWR_PMCR*  = ADDRESS(PWR + 0);
            PWR_PMSR*  = ADDRESS(PWR + 4);
            PWR_WUSR*  = ADDRESS(PWR + 44H);
        EXTI* = ADDRESS(44022000H);
            EXTI_RTSR1*     = ADDRESS(EXTI + 0);
            EXTI_FTSR1*     = ADDRESS(EXTI + 4);
            EXTI_SWIER1*    = ADDRESS(EXTI + 8);
            EXTI_RPR1*      = ADDRESS(EXTI + 0CH);
            EXTI_FPR1*      = ADDRESS(EXTI + 010H);
            EXTI_PRIVCFGR1* = ADDRESS(EXTI + 018H);
            EXTI_RTSR2*     = ADDRESS(EXTI + 020H);
            EXTI_FTSR2*     = ADDRESS(EXTI + 024H);
            EXTI_SWIER2*    = ADDRESS(EXTI + 028H);
            EXTI_RPR2*      = ADDRESS(EXTI + 02CH);
            EXTI_FPR2*      = ADDRESS(EXTI + 030H);
            EXTI_PRIVCFGR2* = ADDRESS(EXTI + 038H);
            EXTI_EXTICR1*   = ADDRESS(EXTI + 060H);
            EXTI_EXTICR2*   = ADDRESS(EXTI + 064H);
            EXTI_EXTICR3*   = ADDRESS(EXTI + 068H);
            EXTI_EXTICR4*   = ADDRESS(EXTI + 06CH);
            EXTI_IMR1*      = ADDRESS(EXTI + 080H);
            EXTI_EMR1*      = ADDRESS(EXTI + 084H);
            EXTI_IMR2*      = ADDRESS(EXTI + 090H);
            EXTI_EMR2*      = ADDRESS(EXTI + 094H);
        RCC* = ADDRESS(44020C00H);
            RCC_CR1*          = ADDRESS(RCC + 0);
            RCC_CR2*          = ADDRESS(RCC + 4);
            RCC_CFGR1*        = ADDRESS(RCC + 01CH);
            RCC_CFGR2*        = ADDRESS(RCC + 020H);
            RCC_CIER*         = ADDRESS(RCC + 050H);
            RCC_CIFR*         = ADDRESS(RCC + 054H);
            RCC_CICR*         = ADDRESS(RCC + 058H);
            RCC_AHB1RSTR*     = ADDRESS(RCC + 060H);
            RCC_AHB2RSTR*     = ADDRESS(RCC + 064H);
            RCC_AHB4RSTR*     = ADDRESS(RCC + 06CH);
            RCC_APB1LRSTR*    = ADDRESS(RCC + 074H);
            RCC_APB1HRSTR*    = ADDRESS(RCC + 078H);
            RCC_APB2RSTR*     = ADDRESS(RCC + 07CH);
            RCC_APB3RSTR*     = ADDRESS(RCC + 080H);
            RCC_AHB1ENR*      = ADDRESS(RCC + 088H);
            RCC_AHB2ENR*      = ADDRESS(RCC + 08CH);
            RCC_AHB4ENR*      = ADDRESS(RCC + 094H);
            RCC_APB1LENR*     = ADDRESS(RCC + 09CH);
            RCC_APB1HENR*     = ADDRESS(RCC + 0A0H);
            RCC_APB2ENR*      = ADDRESS(RCC + 0A4H);
            RCC_APB3ENR*      = ADDRESS(RCC + 0A8H);
            RCC_AHB1LPENR*    = ADDRESS(RCC + 0B0H);
            RCC_AHB2LPENR*    = ADDRESS(RCC + 0B4H);
            RCC_AHB4LPENR*    = ADDRESS(RCC + 0BCH);
            RCC_APB1LLPENR*   = ADDRESS(RCC + 0C4H);
            RCC_APB1HLPENR*   = ADDRESS(RCC + 0C8H);
            RCC_APB2LPENR*    = ADDRESS(RCC + 0CCH);
            RCC_APB3LPENR*    = ADDRESS(RCC + 0D0H);
            RCC_CCIPR1*       = ADDRESS(RCC + 0D8H);
            RCC_CCIPR2*       = ADDRESS(RCC + 0DCH);
            RCC_CCIPR3*       = ADDRESS(RCC + 0E0H);
            RCC_RTCCR*        = ADDRESS(RCC + 0F0H);
            RCC_RSR*          = ADDRESS(RCC + 0F4H);
            RCC_PRIVCFGR*     = ADDRESS(RCC + 0114H);
    (* NVIC *)
    (* interrupt sources *)
        EXTI0Int* = 7;
        EXTI1Int* = 8;
        EXTI2Int* = 9;
        EXTI3Int* = 10;
        EXTI4Int* = 11;
        EXTI5Int* = 12;
        EXTI6Int* = 13;
        EXTI7Int* = 14;
        EXTI8Int* = 15;
        EXTI9Int* = 16;
        EXTI10Int* = 17;
        EXTI11Int* = 18;
        EXTI12Int* = 19;
        EXTI13Int* = 20;
        EXTI14Int* = 21;
        EXTI15Int* = 22;
        USART1Int* = 51;
        USART2Int* = 52;
        USART3Int* = 53;
        UART4Int* = 54;
        UART5Int* = 55;
        USART6Int* = 96;
        UART7Int* = 97;

VAR ^ cpuFreq ["_cpu_freq"]: INTEGER;
VAR ^ resetCause ["_reset_cause"]: INTEGER;

(** Enter light sleep *)
PROCEDURE SleepLight* ["sleep_light"]();
CONST
    (* SCR bits: *)
    SLEEPDEEP = 2;
    (* SYSTCSR bits: *)
    ENABLE = 0;
    (* PWR_PMCR bits: *)
    LPMS0 = 0;
VAR x: SET32;
BEGIN
    (* TODO : Clear pending interrupts *)
    SYSTEM.GET(ARMv8M.SYST_CSR, x);
    SYSTEM.PUT(ARMv8M.SYST_CSR, x - {ENABLE}); (* disable SYSTICK *)
    SYSTEM.GET(ARMv8M.SCR, x);
    SYSTEM.PUT(ARMv8M.SCR, x + {SLEEPDEEP}); (* enable deep sleep *)
    SYSTEM.GET(PWR_PMCR, x);
    SYSTEM.PUT(PWR_PMCR, x - {LPMS0 + 1, LPMS0}); (* stop 0 *)
    SYSTEM.ASM("wfi");
END SleepLight;

(** Enter deep sleep *)
PROCEDURE SleepDeep* ["sleep_deep"]();
CONST
    (* SCR bits: *)
    SLEEPDEEP = 2;
    (* SYSTCSR bits: *)
    ENABLE = 0;
    (* PWR_PMCR bits: *)
    LPMS0 = 0;
VAR x: SET32;
BEGIN
    (* TODO : Clear pending interrupts *)
    SYSTEM.GET(ARMv8M.SYST_CSR, x);
    SYSTEM.PUT(ARMv8M.SYST_CSR, x - {ENABLE}); (* disable SYSTICK *)
    SYSTEM.GET(ARMv8M.SCR, x);
    SYSTEM.PUT(ARMv8M.SCR, x + {SLEEPDEEP}); (* enable deep sleep *)
    SYSTEM.GET(PWR_PMCR, x);
    SYSTEM.PUT(PWR_PMCR, x + {LPMS0 + 1} - {LPMS0}); (* standby *)
    SYSTEM.GET(PWR_WUSR, x);
    SYSTEM.PUT(PWR_WUSR, x - {0 .. 6});
    SYSTEM.ASM("wfi");
END SleepDeep;

PROCEDURE Init*;
CONST
    (* PWR_PMCR bits: *)
    CSSF = 7;
    (* PWR_PMSR bits: *)
    SBF = 6; STOPF = 5;
    (* RCC_RSR bits: *)
    RMVF = 23; PINRSTF = 26; BORRSTF = 27; SFTRSTF = 28; IWDGRSTF = 29;
    WWDGRSTF = 30; LPWRRSTF = 31;
VAR x: SET32;
BEGIN
    (* default cpu frequency HSIDIV3 *)
    cpuFreq := 48000000;

    (* Set reset cause *)
    IF SYSTEM.BIT(PWR_PMSR, SBF) OR SYSTEM.BIT(PWR_PMSR, SBF) THEN
        resetCause := 4; (* RESET_DEEPSLEEP *)
        SYSTEM.GET(PWR_PMCR, x);
        SYSTEM.PUT(PWR_PMCR, x + {CSSF});
    ELSE
        SYSTEM.GET(RCC_RSR, x);
        IF PINRSTF IN x THEN resetCause := 2 (* RESET_HARD *)
        ELSIF SFTRSTF IN x THEN resetCause := 5 (* RESET_SOFT *)
        ELSIF BORRSTF IN x THEN resetCause := 1 (* RESET_PWRON *)
        ELSIF (IWDGRSTF IN x) OR (IWDGRSTF IN x) THEN resetCause := 3 (* RESET_WDT *)
        ELSE resetCause := 0 (* RESET_UNKNOWN *) END;
        SYSTEM.PUT(RCC_RSR, x + {RMVF});
    END;
END Init;

END STM32C5.
