MODULE STM32C5System IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT MCU := STM32C5;

CONST
	(* CPU clock *)
	HCLK* = 144000000;
	HSI* = 1; HSE* = 2; PSI = 3;
	flashLatency = 4; hFreq = 2;

	(* RTC clock *)
	LSI* = 2; LSE* = 1;
	DriveLow* = 0; DriveMedLow* = 1;
	DriveMedHigh* = 2; DriveHighest* = 3;

VAR ^ cpuFreq ["_cpu_freq"]: INTEGER;

(**
	Set CPU clock to 144MHz with PSI clock.
	src: HSI | HSE
	fHSE is ignored if src is HSI.
	NOTE:
		should be called only once the RCC clock configuration
		is reset to the default reset state (done in Init)
*)
PROCEDURE SetClock* (src, fHSE: INTEGER);
CONST
	(* RCC_CR1 bits: *)
	HSISON = 0; HSISRDY = 4; PSISON = 8; PSIDIV3ON = 9;
	PSIKON = 10; PSISRDY = 12; HSEON = 16; HSERDY = 17;
	(* RCC_CR2 bits: *)
	PSIKDIV0 = 8; PSIREFSRC0 = 16; PSIREFSRC1 = 17;
	PSIREF0 = 20; PSIFREQ0 = 28;
VAR
    x: SET32;
	refFreq : INTEGER;
BEGIN
	ASSERT((src = HSI) OR (src = HSE));

	IF src = HSE THEN
		IF fHSE = 32768 THEN
			refFreq := 0;
		ELSIF fHSE = 8'000'000 THEN
			refFreq := 1;
		ELSIF fHSE = 16'000'000 THEN
			refFreq := 2;
		ELSIF fHSE = 24'000'000 THEN
			refFreq := 3;
		ELSIF fHSE = 25'000'000 THEN
			refFreq := 4;
		ELSIF fHSE = 32'000'000 THEN
			refFreq := 5;
		ELSIF fHSE = 48'000'000 THEN
			refFreq := 6;
		ELSIF fHSE = 50'000'000 THEN
			refFreq := 7;
		ELSE
			RETURN
		END;
	END;

	SYSTEM.GET(MCU.RCC_CR1, x);
	IF src = HSI THEN
		(* Set flash read latency and flash signal delay for 144MHz *)
		SYSTEM.GET(MCU.FLASH_ACR, x);
    	SYSTEM.PUT(MCU.FLASH_ACR, x - {0 .. 5} + SET32(flashLatency) + SET32(hFreq * 16));

		SYSTEM.PUT(MCU.RCC_CR1, x + {HSISON});
		REPEAT UNTIL SYSTEM.BIT(MCU.RCC_CR1, HSISRDY);
	ELSE
		SYSTEM.PUT(MCU.RCC_CR1, x + {HSEON});
		REPEAT UNTIL SYSTEM.BIT(MCU.RCC_CR1, HSERDY);
	END;

	SYSTEM.GET(MCU.RCC_CFGR1, x);
    SYSTEM.PUT(MCU.RCC_CFGR1, x - {0 .. 1} + SET32(src));
	REPEAT SYSTEM.GET(MCU.RCC_CFGR1, x) UNTIL x * {3,4} = SET32(src * 8);
	IF src = HSI THEN RETURN END;

	(* Disable PSI/PSIDIV3/PSIK *)
	SYSTEM.GET(MCU.RCC_CR1, x);
	SYSTEM.PUT(MCU.RCC_CR1, x - {PSISON});
	SYSTEM.PUT(MCU.RCC_CR1, x - {PSIDIV3ON});
	SYSTEM.PUT(MCU.RCC_CR1, x - {PSIKON});
	WHILE SYSTEM.BIT(MCU.RCC_CR1, PSISRDY) DO END;

	SYSTEM.GET(MCU.RCC_CR2, x);
	SYSTEM.PUT(MCU.RCC_CR2, x - {PSIREFSRC0, PSIREFSRC1}); (* HSE reference clock *)
	SYSTEM.GET(MCU.RCC_CR2, x);
	SYSTEM.PUT(MCU.RCC_CR2, x - {PSIREF0 .. PSIREF0 + 3} + SET32(refFreq * 100000H)); (* Set reference frequency *)
	SYSTEM.GET(MCU.RCC_CR2, x);
	SYSTEM.PUT(MCU.RCC_CR2, x - {PSIFREQ0 + 1} + {PSIFREQ0}); (* Target frequency 144MHz *)
	SYSTEM.GET(MCU.RCC_CR2, x);
    SYSTEM.PUT(MCU.RCC_CR2, x - {PSIKDIV0 .. PSIKDIV0 + 3}); (* Select division equal to 1 *)

	(* Enable PSI *)
	SYSTEM.GET(MCU.RCC_CR1, x);
	SYSTEM.PUT(MCU.RCC_CR1, x + {PSISON});
	REPEAT UNTIL SYSTEM.BIT(MCU.RCC_CR1, PSISRDY);

	(* Set flash read latency and flash signal delay for 144MHz *)
	SYSTEM.GET(MCU.FLASH_ACR, x);
    SYSTEM.PUT(MCU.FLASH_ACR, x - {0 .. 5} + SET32(flashLatency) + SET32(hFreq * 16));
	
	(* Switch to PSI *)
	SYSTEM.GET(MCU.RCC_CFGR1, x);
    SYSTEM.PUT(MCU.RCC_CFGR1, x - {0 .. 1} + SET32(PSI));
	REPEAT SYSTEM.GET(MCU.RCC_CFGR1, x) UNTIL x * {3,4} = SET32(PSI * 8);

	cpuFreq := 144'000'000;
END SetClock;

(**
	Set RTC clock
	src: LSI | LSE
	drive is ignored if src is LSI.
*)
PROCEDURE SetRTCClock*(src, drive: INTEGER);
CONST
	(* RCC_APB3ENR bits: *)
	RTCAPBEN = 21;
	(* PWR_RTCCR bits: *)
	DRTCP = 0;
	(* RCC_RTCCR bits: *)
	LSEON = 0; LSERDY = 1; LSEDRV0 = 3; RTCSEL0 = 8;
	RTCEN = 15; RTCDRST = 16; LSION = 26; LSIRDY = 27;
VAR
    x: SET32;
BEGIN
	ASSERT((src = LSI) OR (src = LSE));
	ASSERT((src # LSE) OR (drive >= DriveLow));
	ASSERT((src # LSE) OR (drive <= DriveHighest));
	IF src = LSE THEN
		(* Disable LSE and wait for the oscillator to be stopped *)
		SYSTEM.GET(MCU.RCC_RTCCR, x);
		SYSTEM.PUT(MCU.RCC_RTCCR, x - {LSEON});
		REPEAT UNTIL ~SYSTEM.BIT(MCU.RCC_RTCCR, LSERDY);
		(* Set LSE oscillator drive strength *)
		SYSTEM.GET(MCU.RCC_RTCCR, x);
		SYSTEM.PUT(MCU.RCC_RTCCR, x - {LSEDRV0+1, LSEDRV0} + SET32(drive * 8));
		(* Enable LSE and wait for the oscillator to be ready *)
		SYSTEM.GET(MCU.RCC_RTCCR, x);
		SYSTEM.PUT(MCU.RCC_RTCCR, x + {LSEON});
		REPEAT UNTIL SYSTEM.BIT(MCU.RCC_RTCCR, LSERDY);
	ELSE
		IF ~SYSTEM.BIT(MCU.RCC_RTCCR, LSIRDY) THEN
			(* Enable LSI and wait for the oscillator to be ready *)
			SYSTEM.GET(MCU.RCC_RTCCR, x);
			SYSTEM.PUT(MCU.RCC_RTCCR, x + {LSION});
			REPEAT UNTIL SYSTEM.BIT(MCU.RCC_RTCCR, LSIRDY);
		END;
	END;
END SetRTCClock;

END STM32C5System.