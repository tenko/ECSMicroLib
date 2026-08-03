(** Trap handlers

	NOTE:
		Oberon trap codes:
			0: Failed assertion
			1: Unmatched case label
			2: Invalid array element index	Array designators
			3: Failed type guard
			4: Unsatisfied type test
        
        System trap code:
			0A: hard fault
			0B: memory manage
			0C: bus fault
			0D: usage fault

Alexander Shiryaev, 2014.09, 2017.03, 2019.10, 2023.06

Modified by Tenko for use with ECS   
*)
MODULE ArchArmTraps IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ArchArm;
IN Micro IMPORT HardFault := ArchArmException("isr_hardfault");
IN Micro IMPORT MemManage := ArchArmException("isr_memmanage");
IN Micro IMPORT BusFault := ArchArmException("isr_busfault");
IN Micro IMPORT UsageFault := ArchArmException("isr_usagefault");
IN Micro IMPORT SVC := ArchArmException("isr_svc");

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
        ext-: UNSIGNED32;
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

PROCEDURE DefaultTrapHandler* (code: INTEGER; context- : Context);
VAR
    u16 : UNSIGNED16;
    u32 : UNSIGNED32;
    
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
BEGIN
	IF ~trapFlag THEN
		trapFlag := TRUE;
        trap.ext := 0;
        IF code = 0DH THEN
            SYSTEM.GET(ArchArm.UFSR, u16);
            IF SET(u16) * {0} # {} THEN
                SYSTEM.GET(context.PC, u16); (* Fetch UDF *)
                code := INTEGER(SET(u16) * SET(0FH));
            ELSE
                trap.ext := u16;
            END;
        ELSIF code = 0AH THEN
            SYSTEM.GET(ArchArm.HFSR, trap.ext);
        ELSIF code = 0BH THEN
            SYSTEM.GET(ArchArm.MMFAR, trap.ext);
        ELSIF code = 0CH THEN
            SYSTEM.GET(ArchArm.BFAR, trap.ext);
        END;
		trap.code := code;
		trap.context := context;
		
        IF debug THEN
            IF code < 0AH THEN
			   String("ECSOberon : ");
			   IF code = 0 THEN String("Failed assertion")
			   ELSIF code = 1 THEN String("Unmatched case label")
			   ELSIF code = 2 THEN String("Invalid array element index Array designators")
			   ELSIF code = 3 THEN String("Failed type guard")
			   ELSIF code = 3 THEN String("Unsatisfied type test")
			   ELSE String("Unknown") END;
			   Ln;
			   String('  LR   = '); Hex(context.LR); Ln;
               String('  PC   = '); Hex(context.PC); Ln;
            ELSE
                String('TRAP '); Hex(code); Ln;
                IF code >= 0AH THEN
                    IF code = 0DH THEN String('  UFSR   = ')
                    ELSIF code = 0AH THEN String('  HFSR   = ')
                    ELSIF code = 0BH THEN String('  MMFAR   = ')
                    ELSIF code = 0CH THEN String('  BFAR   = ') END;
                    Hex(trap.ext); Ln;
                END;
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
	END;
	rstCheck := rstCheckKey;
	(* Running under debugger control? *)
    IF SYSTEM.BIT(SYSTEM.ADDRESS(ArchArm.SCB_DHCSR), 0) THEN
        SYSTEM.ASM("bkpt 0x01");
    ELSE ArchArm.Reset END;
	WHILE TRUE DO END;
END DefaultTrapHandler;

(* Procedure here use the original stack which might fail if stack failure is a stack overflow *)
PROCEDURE HardFaultTrap;
VAR
    ptr : SYSTEM.ADDRESS;
    context: POINTER TO Context;
BEGIN
	SYSTEM.ASM("
        mov     r0, r11
        mov     r1, sp
        add     r1, r1, 16 ; Adjust for locals stack
        str	    r1, [r0, ptr]
    ");
    SYSTEM.PUT(SYSTEM.ADR(context), ptr);
    trapHandler(0AH, context^);
END HardFaultTrap;

PROCEDURE MemManageTrap;
VAR
    ptr : SYSTEM.ADDRESS;
    context: POINTER TO Context;
BEGIN
	SYSTEM.ASM("
        mov     r0, r11
        mov     r1, sp
        add     r1, r1, 16 ; Adjust for locals stack
        str	    r1, [r0, ptr]
    ");
    SYSTEM.PUT(SYSTEM.ADR(context), ptr);
    trapHandler(0BH, context^);
END MemManageTrap;

PROCEDURE BusFaultTrap;
VAR
    ptr : SYSTEM.ADDRESS;
    context: POINTER TO Context;
BEGIN
	SYSTEM.ASM("
        mov     r0, r11
        mov     r1, sp
        add     r1, r1, 16 ; Adjust for locals stack
        str	    r1, [r0, ptr]
    ");
    SYSTEM.PUT(SYSTEM.ADR(context), ptr);
    trapHandler(0CH, context^);
END BusFaultTrap;

PROCEDURE UsageFaultTrap;
VAR
    ptr : SYSTEM.ADDRESS;
    context: POINTER TO Context;
BEGIN
	SYSTEM.ASM("
        mov     r0, r11
        mov     r1, sp
        add     r1, r1, 16 ; Adjust for locals stack
        str	    r1, [r0, ptr]
    ");
    SYSTEM.PUT(SYSTEM.ADR(context), ptr);
    trapHandler(0DH, context^);
END UsageFaultTrap;

PROCEDURE SVCTrap;
VAR
    ptr : SYSTEM.ADDRESS;
    context: POINTER TO Context;
BEGIN
	SYSTEM.ASM("
        mov     r0, r11
        mov     r1, sp
        add     r1, r1, 16 ; Adjust for locals stack
        str	    r1, [r0, ptr]
    ");
    SYSTEM.PUT(SYSTEM.ADR(context), ptr);
    trapHandler(INTEGER(SET(context.XPSR) * SET(0FFH )), context^);
END SVCTrap;

(* Set system trap handler *)
PROCEDURE SetTrapHandler* (newTrapHandler: TrapHandler);
BEGIN trapHandler := newTrapHandler
END SetTrapHandler;

(* Mark trap as handled *)
PROCEDURE ClearTrapFlag*;
BEGIN trapFlag := FALSE
END ClearTrapFlag;

(* Setup trap handlers and handle reset *)
PROCEDURE Init*;
CONST USGFAULTENA = 18;
VAR s : SET32;
BEGIN
    (* Catch UsageFault *)
    SYSTEM.GET(ArchArm.SHCSR, s);
    s := s + {USGFAULTENA};
    SYSTEM.PUT(ArchArm.SHCSR, s);
    
    debug := FALSE;
	trapHandler := DefaultTrapHandler;
	HardFault.SetHandle(HardFaultTrap);
    MemManage.SetHandle(MemManageTrap);
    BusFault.SetHandle(BusFaultTrap);
    UsageFault.SetHandle(UsageFaultTrap);
    SVC.SetHandle(SVCTrap);
    
	IF rstCheck # rstCheckKey THEN
		nResets := 0;
		trapFlag := FALSE
	ELSE
		INC(nResets)
	END;
	rstCheck := 0;
END Init;

END ArchArmTraps.