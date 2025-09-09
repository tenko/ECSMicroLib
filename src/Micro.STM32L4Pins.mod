MODULE STM32L4Pins IN Micro;

	(*
		Alexander Shiryaev, 2016.04
        Modified by Tenko for use with ECS

        RM0394, Reference manual,
            STM32L41xxx/42xxx/43xxx/44xxx/45xxx/46xxx

        RM0351, Reference manual,
            STM32L47xxx, STM32L48xxx, STM32L49xxx and STM32L4Axxx
	*)

	IMPORT SYSTEM;
    IN Micro IMPORT ARMv7M, MCU := STM32L4;

	CONST
		(* ports *)
			A* = 0; B* = 1; C* = 2; D* = 3; E* = 4; F = 5; G = 6; H* = 7;

		(* modes *)
			input* = 0; output* = 1; alt* = 2; analog* = 3;

		(* output types *)
			pushPull* = FALSE; openDrain* = TRUE;

		(* output speeds *)
			low* = 0; medium* = 1; fast* = 2; veryHigh* = 3;

		(* pull resistors *)
			noPull* = 0; pullUp* = 1; pullDown* = 2;

		(* alternative functions *)
			AF0* = 0; AF1* = 1; AF2* = 2; AF3* = 3;
			AF4* = 4; AF5* = 5; AF6* = 6; AF7* = 7;
			AF8* = 8; AF9* = 9; AF10* = 10; AF11* = 11;
			AF12* = 12; AF13* = 13; AF14* = 14; AF15* = 15;

		portSpacing = MCU.GPIOB - MCU.GPIOA;

    TYPE
        ADDRESS = SYSTEM.ADDRESS;
        Pin* = RECORD
            BASE : ADDRESS;
            port-, pin- : INTEGER;
        END;

	PROCEDURE (VAR p : Pin) Init* (port, pin, mode: INTEGER; oType: BOOLEAN; oSpeed, pullType, af: INTEGER);
		VAR x: SET;
			r, y: ADDRESS;
	BEGIN
		ASSERT(port >= A);
		ASSERT(port <= H);
        ASSERT((port # F) & (port # G));
		ASSERT(pin DIV 16 = 0);
		ASSERT(mode DIV 4 = 0);
		ASSERT(oSpeed DIV 4 = 0);
		ASSERT(pullType >= noPull);
		ASSERT(pullType <= pullDown);
		ASSERT(af DIV 16 = 0);

        p.port := port; p.pin := pin;
        p.BASE := MCU.GPIOA + port * portSpacing;

		y := pin * 2;

		(* enable clock for pin port *)
		SYSTEM.GET(MCU.RCC_AHB2ENR, x);
		SYSTEM.PUT(MCU.RCC_AHB2ENR, x + {port});

		SYSTEM.GET(MCU.RCC_AHB2SMENR, x);
		SYSTEM.PUT(MCU.RCC_AHB2SMENR, x + {port});

		r := MCU.GPIOA_MODER + port * portSpacing;
		SYSTEM.GET(r, x);
		SYSTEM.PUT(r, SYSTEM.VAL(SIGNED32, x - {y,y+1}) + SYSTEM.LSH(mode, y));

		r := MCU.GPIOA_OTYPER + port * portSpacing;
		SYSTEM.GET(r, x);
		IF oType THEN SYSTEM.PUT(r, x + {pin})
		ELSE SYSTEM.PUT(r, x - {pin})
		END;

		r := MCU.GPIOA_OSPEEDR + port * portSpacing;
		SYSTEM.GET(r, x);
		SYSTEM.PUT(r, SYSTEM.VAL(SIGNED32, x - {y,y+1}) + SYSTEM.LSH(oSpeed, y));

		r := MCU.GPIOA_PUPDR + port * portSpacing;
		SYSTEM.GET(r, x);
		SYSTEM.PUT(r, SYSTEM.VAL(SIGNED32, x - {y,y+1}) + SYSTEM.LSH(pullType, y));

		IF mode = alt THEN y := (pin * 4) MOD 32;
			r := MCU.GPIOA_AFRL + pin DIV 8 * 4 + port * portSpacing;
			SYSTEM.GET(r, x);
			SYSTEM.PUT(r, SYSTEM.VAL(SIGNED32, x - {y..y+3}) + SYSTEM.LSH(af, y))
		END
	END Init;

    PROCEDURE (VAR p : Pin) On*;
    BEGIN SYSTEM.PUT(p.BASE + 18H, {p.pin}); (* BSRR *)
    END On;

    PROCEDURE (VAR p : Pin) Off*;
    BEGIN SYSTEM.PUT(p.BASE + 18H, {p.pin + 16}); (* BSRR *)
    END Off;

    PROCEDURE (VAR p : Pin) Value*(): BOOLEAN;
    VAR s : SET32;
    BEGIN
        SYSTEM.GET(p.BASE + 10H, s); (* IDR *)
        RETURN (s * {p.pin}) # {}
    END Value;

    PROCEDURE (VAR p : Pin) Toggle*;
    BEGIN IF p.Value() THEN p.Off() ELSE p.On() END
    END Toggle;
    
END STM32L4Pins.
