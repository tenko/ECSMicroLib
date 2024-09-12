MODULE STM32F4Flash IN Micro;

	(*
		Alexander Shiryaev, 2015.01, 2016.06, 2017.10, 2023.06
        Modified by Tenko for use with ECS
        
		RM0090, Reference manual,
			STM32F405xx/07xx, STM32F415xx/17xx,
			[ STM32F42xxx, STM32F43xxx ]

		RM0390, Reference manual,
			STM32F446xx

		stm32f4xx_flash.c
	*)

	IMPORT SYSTEM;
    IN Micro IMPORT MCU := STM32F4;

	CONST
		(* FLASHSR bits: *)
			EOP = 0;
			OPERR = 1; WRPERR = 4; PGAERR = 5; PGPERR = 6; PGSERR = 7;
			BSY = 16;
		(* FLASHCR bits: *)
			PG = 0; SER = 1; MER = 2; STRT = 16; LOCK = 31;
		(* OPTCR bits:*)
			OPTLOCK = 0; OPTSTRT = 1;
        (* res *)
			complete* = 0; busy* = 1; writeError* = 2;
				writeProtected* = 3; operationError* = 4;
    
    PROCEDURE UnLock*;
		CONST
			FLASHKEY1 = SIGNED32(45670123H);
			FLASHKEY2 = SIGNED32(0CDEF89ABH);
	BEGIN
		IF SYSTEM.BIT(MCU.FLASH_CR, LOCK) THEN
			SYSTEM.PUT(MCU.FLASH_KEYR, FLASHKEY1);
			SYSTEM.PUT(MCU.FLASH_KEYR, FLASHKEY2)
		END
	END UnLock;

    PROCEDURE Lock*;
		VAR x: SET;
	BEGIN
		SYSTEM.GET(MCU.FLASH_CR, x);
		SYSTEM.PUT(MCU.FLASH_CR, x + {LOCK})
	END Lock;
    
    PROCEDURE GetStatus (): INTEGER;
		VAR res: INTEGER;
			s: SET;
	BEGIN
		SYSTEM.GET(MCU.FLASH_SR, s);
		IF BSY IN s THEN res := busy
		ELSIF WRPERR IN s THEN res := writeProtected
		ELSIF s * {PGAERR,PGPERR,PGSERR} # {} THEN res := writeError
		ELSIF OPERR IN s THEN res := operationError
		ELSE res := complete
		END;
	RETURN res
	END GetStatus;

    PROCEDURE WaitForLastOperation (): INTEGER;
		VAR res: INTEGER;
	BEGIN REPEAT res := GetStatus() UNTIL res # busy;
	RETURN res
	END WaitForLastOperation;

    (*
		device voltage must be in range 2.7--3.6 V
	*)
	PROCEDURE EraseSector* (sector: INTEGER; VAR res: INTEGER);
		CONST SNB = {3..6};
		VAR x: SET;
	BEGIN
		ASSERT(sector >= 0);
		ASSERT(sector <= 11);
		res := WaitForLastOperation();
		IF res = complete THEN
			SYSTEM.GET(MCU.FLASH_CR, x);
			SYSTEM.PUT(MCU.FLASH_CR, x + {9} - {8}); (* PSIZE := x32 *)

			SYSTEM.GET(MCU.FLASH_CR, x);
			SYSTEM.PUT(MCU.FLASH_CR, x + {SER}
				- SNB + SYSTEM.VAL(SET, sector * 8));

			SYSTEM.GET(MCU.FLASH_CR, x);
			SYSTEM.PUT(MCU.FLASH_CR, x + {STRT});

			res := WaitForLastOperation();

			SYSTEM.GET(MCU.FLASH_CR, x);
			SYSTEM.PUT(MCU.FLASH_CR, x - {SER});

			SYSTEM.GET(MCU.FLASH_CR, x);
			SYSTEM.PUT(MCU.FLASH_CR, x - SNB)
		END
	END EraseSector;

    (*
		programs a word (32-bit) at a specified address

		device voltage must be in range 2.7--3.6 V

		if an erase and a program operations are requested simustaneously,
			the erase operation is performed before the program one

		adr: specifies the address to be programmed. This parameter can be any
			address in Program memory zone or in OTP zone
		data: specifies the data to be programmed
	*)
	PROCEDURE Write* (adr: SYSTEM.ADDRESS; data: INTEGER; VAR res: INTEGER);
		VAR x: SET;
	BEGIN
		res := WaitForLastOperation();
		IF res = complete THEN (* proceed to program the new data *)
			SYSTEM.GET(MCU.FLASH_CR, x);
			SYSTEM.PUT(MCU.FLASH_CR, x + {9} - {8}); (* PSIZE := x32 *)

			SYSTEM.GET(MCU.FLASH_CR, x);
			SYSTEM.PUT(MCU.FLASH_CR, x + {PG}); (* !PG *)

			SYSTEM.PUT(adr, data);

			res := WaitForLastOperation();

			SYSTEM.GET(MCU.FLASH_CR, x);
			SYSTEM.PUT(MCU.FLASH_CR, x - {PG}) (* !~PG *)
		END
	END Write;

    PROCEDURE OBUnLock*;
		CONST
			FLASHOPTKEY1 = SIGNED32(08192A3BH);
			FLASHOPTKEY2 = SIGNED32(4C5D6E7FH);
	BEGIN
		IF SYSTEM.BIT(MCU.FLASH_OPTCR, OPTLOCK) THEN
			SYSTEM.PUT(MCU.FLASH_OPTKEYR, FLASHOPTKEY1);
			SYSTEM.PUT(MCU.FLASH_OPTKEYR, FLASHOPTKEY2)
		END
	END OBUnLock;

    PROCEDURE OBLock*;
		VAR x: SET;
	BEGIN
		SYSTEM.GET(MCU.FLASH_OPTCR, x);
		SYSTEM.PUT(MCU.FLASH_OPTCR, x + {OPTLOCK})
	END OBLock;

    PROCEDURE OBWrite* (x: SET; VAR res: INTEGER);
	BEGIN
		ASSERT(x * {OPTSTRT,OPTLOCK} = {});

		res := WaitForLastOperation();
		IF res = complete THEN
			SYSTEM.PUT(MCU.FLASH_OPTCR, x);

			SYSTEM.GET(MCU.FLASH_OPTCR, x);
			SYSTEM.PUT(MCU.FLASH_OPTCR, x + {OPTSTRT});

			res := WaitForLastOperation()
		END
	END OBWrite;

    PROCEDURE SizeKiB* (): INTEGER;
		VAR x: INTEGER;
	BEGIN
		SYSTEM.GET(MCU.FlashSizeKiBAdr, x);
	RETURN x MOD 10000H
	END SizeKiB;

END STM32F4Flash.