MODULE ARMv7MTraps IN Micro;

	(* Alexander Shiryaev, 2014.09, 2017.03, 2019.10, 2023.06
       Modified by Tenko for use with ECS
    *)

	(* ARMv7-M *)

    (*
		TODO: init all other traps, extend TrapHandler

		NOTE:
			trap codes:
				1: index check
				2: type cast
				3: array size
				4: nil check
				5: nil check (procedure call)
				6: bad divisor (must be > 0)
				7: assert

				10: hard fault
				11: memory manage
				12: bus fault
				13: usage fault
	*)

    IMPORT SYSTEM, ARMv7M IN Micro;

    CONST
		rstCheckKey = 19847C2AH;
    
    TYPE
        Context* = RECORD-
            R0-     : UNSIGNED32;
            R1-     : UNSIGNED32;
            R2-     : UNSIGNED32;
            R3-     : UNSIGNED32;
            R12-    : UNSIGNED32;
            LR-     : UNSIGNED32;
            PC-     : UNSIGNED32;
            XPSR-   : UNSIGNED32;
        END;
        TrapHandler* = PROCEDURE (code: INTEGER; context- : Context);
        Trap* = RECORD
			code-: INTEGER;
            context-: Context;
		END;

	VAR
		nResets*: INTEGER;
		trapFlag*: BOOLEAN;
		trap*: Trap;
        debug* : BOOLEAN;
        trapHandler*: TrapHandler;
        rstCheck: INTEGER;
        
    PROCEDURE ^ Putchar ["putchar"] (character: INTEGER): INTEGER;

    PROCEDURE String(value-: ARRAY OF CHAR);
    VAR i: LENGTH; char: CHAR;
    BEGIN
        FOR i := 0 TO LEN (value) - 1 DO
            char := value[i];
            IF char = 0X THEN RETURN END;
            IGNORE(Putchar(ORD(char))); 
        END;
    END String;

    PROCEDURE Hex(value : UNSIGNED32);
    VAR
        i, dig : INTEGER;
    BEGIN
        IGNORE(Putchar(ORD('0')));
        FOR i := 0 TO 7 DO
            dig := INTEGER(SET(0FH) * SET(SYSTEM.LSH(value, -28 + 4*i)));
            IF dig > 9 THEN INC(dig, ORD('A') - 10)
            ELSE INC(dig, ORD('0')) END;
            IGNORE(Putchar(dig)); 
        END;
        IGNORE(Putchar(ORD('H')));
    END Hex;

    PROCEDURE Ln;
    BEGIN IGNORE(Putchar(0AH)); 
    END Ln;

	PROCEDURE DefaultTrapHandler* (code: INTEGER; context- : Context);
	BEGIN
		IF ~trapFlag THEN
			trap.code := code;
			trap.context := context;
			trapFlag := TRUE;
            IF debug THEN
                String('TRAP '); Hex(code); Ln;
                String('  R0   = '); Hex(context.R0); Ln;
                String('  R1   = '); Hex(context.R1); Ln;
                String('  R2   = '); Hex(context.R2); Ln;
                String('  R3   = '); Hex(context.R3); Ln;
                String('  R12  = '); Hex(context.R12); Ln;
                String('  LR   = '); Hex(context.LR); Ln;
                String('  PC   = '); Hex(context.PC); Ln;
                String('  XPSR = '); Hex(context.XPSR); Ln;
            END;
		END;
		rstCheck := rstCheckKey;
		(* system reset *)
			ARMv7M.DSB;
			SYSTEM.PUT(ARMv7M.AIRCR, SIGNED32(05FA0004H)); (* SYSRESETREQ *)
			ARMv7M.DSB;
			REPEAT UNTIL FALSE
	END DefaultTrapHandler;

    PROCEDURE SVCTrap ["isr_svc"];
	VAR
        ptr : SYSTEM.ADDRESS;
        context: POINTER TO Context;
	BEGIN
		SYSTEM.ASM("
            mov     r0, r11
            mov     r1, sp
            add     r1, r1, 16
            str	    r1, [r0, ptr]
        ");
        SYSTEM.PUT(SYSTEM.ADR(context), ptr);
        trapHandler(INTEGER(SET(context.XPSR) * SET(0FFH )), context^);
	END SVCTrap;
    
    PROCEDURE HardFaultTrap ["isr_hardfault"];
	VAR
        ptr : SYSTEM.ADDRESS;
        context: POINTER TO Context;
	BEGIN
		SYSTEM.ASM("
            mov     r0, r11
            mov     r1, sp
            str	    r1, [r0, ptr]
        ");
        SYSTEM.PUT(SYSTEM.ADR(context), ptr);
        trapHandler(0AH, context^);
	END HardFaultTrap;

    PROCEDURE MemManageTrap ["isr_memmanage"];
	VAR
        ptr : SYSTEM.ADDRESS;
        context: POINTER TO Context;
	BEGIN
		SYSTEM.ASM("
            mov     r0, r11
            mov     r1, sp
            str	    r1, [r0, ptr]
        ");
        SYSTEM.PUT(SYSTEM.ADR(context), ptr);
        trapHandler(0BH, context^);
	END MemManageTrap;
    
    PROCEDURE BusFaultTrap ["isr_busfault"];
	VAR
        ptr : SYSTEM.ADDRESS;
        context: POINTER TO Context;
	BEGIN
		SYSTEM.ASM("
            mov     r0, r11
            mov     r1, sp
            str	    r1, [r0, ptr]
        ");
        SYSTEM.PUT(SYSTEM.ADR(context), ptr);
        trapHandler(0CH, context^);
	END BusFaultTrap;

    PROCEDURE UsageFaultTrap ["isr_usagefault"];
	VAR
        ptr : SYSTEM.ADDRESS;
        context: POINTER TO Context;
	BEGIN
		SYSTEM.ASM("
            mov     r0, r11
            mov     r1, sp
            str	    r1, [r0, ptr]
        ");
        SYSTEM.PUT(SYSTEM.ADR(context), ptr);
        trapHandler(0DH, context^);
	END UsageFaultTrap;

    PROCEDURE SetTrapHandler* (newTrapHandler: TrapHandler);
	BEGIN
		trapHandler := newTrapHandler
	END SetTrapHandler;

    PROCEDURE ClearTrapFlag*;
	BEGIN
		trapFlag := FALSE
	END ClearTrapFlag;

	PROCEDURE Init*;
	BEGIN
        debug := FALSE;
		trapHandler := DefaultTrapHandler;
		IF rstCheck # rstCheckKey THEN
			nResets := 0;
			trapFlag := FALSE
		ELSE
			INC(nResets)
		END;
		rstCheck := 0; (* # rstCheckKey *)
	END Init;

END ARMv7MTraps.