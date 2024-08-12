MODULE STM32F4Pins IN Micro;

	(*
		Alexander Shiryaev, 2016.04
        Modified by Tenko for use with ECS
        
		RM0090, Reference manual,
			STM32F4{0,1}{5,7}xx, STM32F4{2,3}{7,9}xx (PA..PK)

		RM0368, Reference manual,
			STM32F401x{B,C,D,E} (PA..PE, PH)

		RM0383, Reference manual,
			STM32F411x{C,E} (PA..PE, PH)

		RM0386, Reference manual,
			STM32F4{6,7}9xx (PA..PK)

		RM0390, Reference manual,
			STM32F446xx (PA..PH)

		RM0401, Reference manual,
			STM32F410 (PA..PC, PH)
	*)

	IMPORT SYSTEM;

    TYPE ADDRESS = SYSTEM.ADDRESS;

	CONST
		(* ports *)
			A* = 0; B* = 1; C* = 2; D* = 3; E* = 4; F* = 5; G* = 6; H* = 7;
			I* = 8; J* = 9; K* = 10;

		(* modes *)
			input* = 0; output* = 1; alt* = 2; analog* = 3;

		(* output types *)
			pushPull* = FALSE; openDrain* = TRUE;

		(* output speeds *)
			low* = 0; medium* = 1; fast* = 2; veryHigh* = 3;
				(* STM32F4{0,1}1, STM32F446: low, medium, fast, high *)
				(* STM32F4{0,1}{5,7}, STM32F4{2,3}{7,9},
					STM32F410, STM32F4{6,7}9: low, medium, high, very high *)

		(* pull resistors *)
			noPull* = 0; pullUp* = 1; pullDown* = 2;

		(* alternative functions *)
			AF0* = 0; AF1* = 1; AF2* = 2; AF3* = 3;
			AF4* = 4; AF5* = 5; AF6* = 6; AF7* = 7;
			AF8* = 8; AF9* = 9; AF10* = 10; AF11* = 11;
			AF12* = 12; AF13* = 13; AF14* = 14; AF15* = 15;

		(* AHB1 *)
			GPIOA* = ADDRESS(40020000H);
				GPIOAMODER*     = ADDRESS(GPIOA + 0);
				GPIOAOTYPER*    = ADDRESS(GPIOA + 4);
				GPIOAOSPEEDR*   = ADDRESS(GPIOA + 8);
				GPIOAPUPDR*     = ADDRESS(GPIOA + 0CH);
				GPIOAIDR*       = ADDRESS(GPIOA + 10H);
				GPIOAODR*       = ADDRESS(GPIOA + 14H);
				GPIOABSRR*      = ADDRESS(GPIOA + 18H);
				GPIOALCKR*      = ADDRESS(GPIOA + 1CH);
				GPIOAAFRL*      = ADDRESS(GPIOA + 20H);
				GPIOAAFRH*      = ADDRESS(GPIOA + 24H);
			GPIOB* = ADDRESS(40020400H);
			GPIOC* = ADDRESS(40020800H);
			GPIOD* = ADDRESS(40020C00H);
			GPIOE* = ADDRESS(40021000H);
			GPIOF* = ADDRESS(40021400H);
			GPIOG* = ADDRESS(40021800H);
			GPIOH* = ADDRESS(40021C00H);
			GPIOI* = ADDRESS(40022000H);
			GPIOJ* = ADDRESS(40022400H);
			GPIOK* = ADDRESS(40022800H);

		portSpacing = GPIOB - GPIOA;

		RCC = ADDRESS(40023800H);
		RCCAHB1ENR  = ADDRESS(RCC + 30H);
		RCCAHB1LPENR= ADDRESS(RCC + 50H);

	PROCEDURE Configure* (port, pin, mode: INTEGER; oType: BOOLEAN; oSpeed, pullType, af: INTEGER);
		VAR x: SET;
			r, y: ADDRESS;
            PROCEDURE PUT32(adr : ADDRESS; value : SIGNED32);
            BEGIN SYSTEM.PUT(adr, value) END PUT32;
            PROCEDURE GETS32(adr : ADDRESS; value : SET32);
            BEGIN SYSTEM.GET(adr, value) END GETS32;
            PROCEDURE PUTS32(adr : ADDRESS; value : SET32);
            BEGIN SYSTEM.PUT(adr, value) END PUTS32;
	BEGIN
		ASSERT(port >= A);
		ASSERT(port <= K);
		ASSERT(pin DIV 16 = 0);
		ASSERT(mode DIV 4 = 0);
		ASSERT(oSpeed DIV 4 = 0);
		ASSERT(pullType >= noPull);
		ASSERT(pullType <= pullDown);
		ASSERT(af DIV 16 = 0);

		y := pin * 2;

		(* enable clock for pin port *)
			GETS32(RCCAHB1ENR, x);
			PUTS32(RCCAHB1ENR, x + {port});

			GETS32(RCCAHB1LPENR, x);
			PUTS32(RCCAHB1LPENR, x + {port});

		r := GPIOAMODER + port * portSpacing;
		GETS32(r, x);
		PUT32(r, SYSTEM.VAL(INTEGER, x - {y,y+1}) + SYSTEM.LSH(mode, y));

		r := GPIOAOTYPER + port * portSpacing;
		GETS32(r, x);
		IF oType THEN PUTS32(r, x + {pin})
		ELSE PUTS32(r, x - {pin})
		END;

		r := GPIOAOSPEEDR + port * portSpacing;
		GETS32(r, x);
		PUT32(r, SYSTEM.VAL(INTEGER, x - {y,y+1}) + SYSTEM.LSH(oSpeed, y));

		r := GPIOAPUPDR + port * portSpacing;
		GETS32(r, x);
		PUT32(r, SYSTEM.VAL(INTEGER, x - {y,y+1}) + SYSTEM.LSH(pullType, y));

		IF mode = alt THEN y := (pin * 4) MOD 32;
			r := GPIOAAFRL + pin DIV 8 * 4 + port * portSpacing;
			GETS32(r, x);
			PUT32(r, SYSTEM.VAL(INTEGER, x - {y..y+3}) + SYSTEM.LSH(af, y))
		END
	END Configure;

END STM32F4Pins.
