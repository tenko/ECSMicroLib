MODULE STM32F4IWDG IN Micro;

	(*
		Alexander Shiryaev, 2018.05
        Modified by Tenko for use with ECS
        
		RM0090, Reference manual,
			STM32F4{0,1}{5,7}xx, STM32F4{2,3}{7,9}xx
	*)
    IMPORT SYSTEM;
    IN Micro IMPORT MCU := STM32F4;

    CONST
		(* PR values: *)
			PR4* = 0; PR8* = 1; PR16* = 2; PR32* = 3; PR64* = 4; PR128* = 5; PR256* = 6;
			PRMax* = 7;
		(* RL values: *)
			RLMax* = 0FFFH;

    PROCEDURE Update*;
	BEGIN
		SYSTEM.PUT(MCU.IWDG_KR, SIGNED32(0AAAAH))
	END Update;

    PROCEDURE Init* (PR, RL: INTEGER);
		CONST
			(* RCCCSR bits: *)
				LSION = 0; LSIRDY = 1;
			(* IWDGSR bits: *)
				PVU = 0; RVU = 1;
		VAR x: SET;
	BEGIN
		ASSERT(PR DIV 8 = 0);
		ASSERT(RL DIV 1000H = 0);

		(* enable LSI *)
			SYSTEM.GET(MCU.RCC_CSR, x);
			SYSTEM.PUT(MCU.RCC_CSR, x + {LSION});
			REPEAT UNTIL SYSTEM.BIT(MCU.RCC_CSR, LSIRDY);

		(* setup IWDG *)

			(* enable write access *)
				SYSTEM.PUT(MCU.IWDG_KR, SIGNED32(5555H));

			(* setup PR *)
				REPEAT UNTIL ~SYSTEM.BIT(MCU.IWDG_SR, PVU);
				SYSTEM.PUT(MCU.IWDG_PR, PR);

			(* setup RLR *)
				REPEAT UNTIL ~SYSTEM.BIT(MCU.IWDG_SR, RVU);
				SYSTEM.PUT(MCU.IWDG_RLR, RL);

		(* reload IWDG *)
			SYSTEM.PUT(MCU.IWDG_KR, SIGNED32(0AAAAH));

		(* start IWDG *)
			SYSTEM.PUT(MCU.IWDG_KR, SIGNED32(0CCCCH))
	END Init;

END STM32F4IWDG.