MODULE Traps;
IMPORT SYSTEM;

TYPE
    Context = RECORD-
        R0     : UNSIGNED32;
        R1     : UNSIGNED32;
        R2     : UNSIGNED32;
        R3     : UNSIGNED32;
        R12    : UNSIGNED32;
        LR     : UNSIGNED32;
        PC     : UNSIGNED32;
        XPSR   : UNSIGNED32;
    END;

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
    FOR i := 0 TO 7 DO
        dig := INTEGER(SET(0FH) * SET(SYSTEM.LSH(value, -28 + 4*i)));
        IF dig > 9 THEN INC(dig, ORD('A') - 10)
        ELSE INC(dig, ORD('0')) END;
        IGNORE(Putchar(dig)); 
    END;
END Hex;

PROCEDURE Ln;
BEGIN IGNORE(Putchar(0AH)); 
END Ln;

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
    String('R0 = '); Hex(context.R0); Ln;
    String('R1 = '); Hex(context.R1); Ln;
    String('R2 = '); Hex(context.R2); Ln;
    String('R3 = '); Hex(context.R3); Ln;
    String('LR = '); Hex(context.LR); Ln;
    String('PC = '); Hex(context.PC); Ln;
    String('XPSR = '); Hex(context.XPSR); Ln;
END SVCTrap;

BEGIN
    SYSTEM.ASM("
        mov r0, 1
        mov r1, 2
        mov r2, 4
        mov r3, 5
        svc 0x17"
    );
    WHILE TRUE DO END;
END Traps.