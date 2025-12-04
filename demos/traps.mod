(** Test traps with a command line interface. *)
MODULE Test;
IMPORT SYSTEM;
IMPORT BoardConfig;

IN Micro IMPORT ARMv7M, ARMv7MTraps, Debug;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;

IN Std IMPORT ArrayOfChar, Integer;

CONST
    LF = 0AX; CR = 0DX;
    ESC = 01BX; DEL = 07FX;
    
    Uart = BoardConfig.Uart;
    
TYPE
    UartCLI = RECORD (Debug.CommandLine) END;
        
VAR
    bus : Uart.Bus;
    cli : UartCLI;
    x : CHAR;

(* ob trap *)
PROCEDURE ObTrap(code : INTEGER) : BOOLEAN;
VAR
    arr : ARRAY 2 OF CHAR;
    i : LENGTH;
    c : CHAR;
    b : BOOLEAN;
BEGIN
    IF code = 0 THEN
        b := FALSE;
        ASSERT(b = TRUE);
    ELSIF code = 1 THEN
        i := 2;
        CASE i OF
            0 : ;
          | 1 : ;
        END;
    ELSIF code = 2 THEN
        i := 2;
        c := arr[i];
    END;
    RETURN FALSE;
END ObTrap;
 
PROCEDURE ArmTrap(code : INTEGER): BOOLEAN;
VAR i : INTEGER;
BEGIN
    IF code = 0 THEN
        SYSTEM.ASM("
            mov     r1, 0x4000
            bx.n    r1
        ");
    ELSIF code = 1 THEN
        SYSTEM.ASM("bkpt 0");
    END;
    RETURN FALSE;
END ArmTrap;

PROCEDURE (VAR this : UartCLI) WriteChar(ch : CHAR);
BEGIN IGNORE(bus.WriteChar(ch)) END WriteChar;

PROCEDURE (VAR this : UartCLI) OnWelcome;
    PROCEDURE W(str- : ARRAY OF CHAR);
    BEGIN this.WriteStr(str) END W;
    PROCEDURE Begin;
    BEGIN this.WriteChar(ESC); W("[1;34m"); END Begin;
    PROCEDURE End;
    BEGIN this.WriteChar(CR); this.WriteChar(LF) END End;
BEGIN
    this.Clear;
    Begin; W("#################################"); End;
    Begin; W("        ECSMicroLib Demo         "); End;
    Begin; W("BOARD : "); this.Reset; W(BoardConfig.Board); End;
    Begin; W("MCU   : "); this.Reset; W(BoardConfig.MCU); End;
    Begin; W("Check 'help' command for more info"); End;
    Begin; W("#################################"); this.Reset; End;
END OnWelcome;

PROCEDURE (VAR this : UartCLI) OnHelpCommand();
    PROCEDURE W(str- : ARRAY OF CHAR);
    BEGIN this.WriteStr(str) END W;
    PROCEDURE End;
    BEGIN this.WriteChar(CR); this.WriteChar(LF) END End;
BEGIN
    this.WriteChar(ESC); W("[1;34mLine editing:"); this.Reset; End;
    W("Left Arrow       - Go left one character"); End;
    W("Right Arrow      - Go right one character"); End;
    W("Up Arrow         - Go back in command history"); End;
    W("Down Arrow       - Go forward in command history"); End;
    W("Backspace/Delete - Delete character to the left of cursor"); End;
    W("Return           - Try to execute input line"); End;
    this.WriteChar(ESC); W("[1;34mCommands:"); this.Reset; End;
    W("'clear'          - Clear screen"); End;
    W("'help'           - Help message"); End;
    W("'reset'          - Reset board"); End;
    W("'obtrap n        - Trigger oberon trap n"); End;
    W("'trap n          - Trigger trap 10.."); End;
    W("'quit'                       - Quit"); End;
    End;
END OnHelpCommand;

PROCEDURE (VAR this : UartCLI) OnCommand(): BOOLEAN;
VAR
    ret : BOOLEAN;
    result : HUGEINT;
BEGIN
    ret := FALSE;
    IF ArrayOfChar.Equal(this.line, "quit") THEN
        this.quit := TRUE;
        ret := TRUE;
    ELSIF ArrayOfChar.Equal(this.line, "clear") THEN
        this.Clear;
        ret := TRUE;
    ELSIF ArrayOfChar.Equal(this.line, "help") THEN
        this.OnHelpCommand;
        ret := TRUE;
    ELSIF ArrayOfChar.Equal(this.line, "reset") THEN
        ARMv7M.Reset;
        ret := TRUE;
    ELSIF ArrayOfChar.StartsWith(this.line, "trap ") THEN
        IF Integer.FromSubString(result, this.line, 5, this.len - 5) THEN
            ret := ArmTrap(INTEGER(result));
        END;
    ELSIF ArrayOfChar.StartsWith(this.line, "obtrap ") THEN
        TRACE(Integer.FromSubString(result, this.line, 7, this.len - 7));
        TRACE(result);
        IF Integer.FromSubString(result, this.line, 7, this.len - 7) THEN
            ret := ObTrap(INTEGER(result));
        END;
    END;
    RETURN ret
END OnCommand;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
        
    ARMv7MTraps.Init;
    ARMv7MTraps.debug := TRUE;
     
    SysTick.Init(BoardConfig.HCLK, 1000);
    
    BoardConfig.InitUart(bus, 19200, Uart.parityNone, Uart.stopBits1);
    Debug.Init(cli);
    TRACE("Start");
    REPEAT
        ARMv7M.WFI;
        IF (bus.Any() > 0) & bus.TXDone() THEN
            IF bus.ReadChar(x) THEN
                cli.ProcessChar(x)
            END;
        END;
    UNTIL FALSE
END Test.