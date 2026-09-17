(** Test uart with a command line interface. *)
MODULE Test;
IMPORT BoardConfig;

IN Micro IMPORT Machine;
IN Micro IMPORT Debug;

IN Std IMPORT ArrayOfChar;

CONST
    LF = 0AX; CR = 0DX;
    ESC = 01BX; DEL = 07FX;
    
    SysTick = BoardConfig.SysTick;
    Uart = BoardConfig.Uart;
    Pins = BoardConfig.Pins;
    
    BLINK = 250;
    
TYPE
    UartCLI = RECORD (Debug.CommandLine) END;
        
VAR
    pin : Pins.Pin;
    bus : Uart.Bus;
    cli : UartCLI;
    t0 : UNSIGNED32;
    x : CHAR;
    blink : BOOLEAN;

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
    W("Tab              - Try to complete partial input"); End;
    W("Return           - Try to execute input line"); End;
    this.WriteChar(ESC); W("[1;34mCommands:"); this.Reset; End;
    W("'clear'                      - Clear screen"); End;
    W("'help'                       - Help message"); End;
    W("'led [on|off|toggle|blink]'  - Set led mode"); End;
    W("'quit'                       - Quit"); End;
END OnHelpCommand;

PROCEDURE (VAR this : UartCLI) OnComplete(): BOOLEAN;
VAR
	len : LENGTH;
	
	PROCEDURE Check(prefix-, cmd- : ARRAY OF CHAR): BOOLEAN;
	BEGIN
		IF ArrayOfChar.Compare(prefix, this.line) = 0 THEN
			this.SetLine(cmd);
			this.RedrawLine;
			RETURN TRUE
		END;
		RETURN FALSE
	END Check;
BEGIN
	len := ArrayOfChar.Length(this.line);
	IF len = 1 THEN
		IF Check("q", "quit") THEN RETURN TRUE END;
		IF Check("c", "clear") THEN RETURN TRUE END;
		IF Check("h", "help") THEN RETURN TRUE END;
		IF Check("l", "led ") THEN RETURN TRUE END;
	ELSIF len = 2 THEN
		IF Check("qu", "quit") THEN RETURN TRUE END;
		IF Check("cl", "clear") THEN RETURN TRUE END;
		IF Check("he", "help") THEN RETURN TRUE END;
		IF Check("le", "led ") THEN RETURN TRUE END;
	ELSIF len = 3 THEN
		IF Check("qui", "quit") THEN RETURN TRUE END;
		IF Check("cle", "clear") THEN RETURN TRUE END;
		IF Check("hel", "help") THEN RETURN TRUE END;
	ELSIF len = 4 THEN
		IF Check("clea", "clear") THEN RETURN TRUE END;
	END;
	RETURN FALSE;
END OnComplete;

PROCEDURE (VAR this : UartCLI) OnCommand(): BOOLEAN;
VAR ret : BOOLEAN;
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
    ELSIF ArrayOfChar.Equal(this.line, "led on") THEN
        pin.On;
        blink := FALSE;
        ret := TRUE;
    ELSIF ArrayOfChar.Equal(this.line, "led off") THEN
        pin.Off;
        blink := FALSE;
        ret := TRUE;
    ELSIF ArrayOfChar.Equal(this.line, "led toggle") THEN
        pin.Toggle;
        blink := FALSE;
        ret := TRUE;
    ELSIF ArrayOfChar.Equal(this.line, "led blink") THEN
        blink := TRUE;
        ret := TRUE;
    END;
    RETURN ret
END OnCommand;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
    
    pin.Init(BoardConfig.USER_LED1_PORT, BoardConfig.USER_LED1_PIN, Pins.output,
             Pins.pushPull, Pins.medium, Pins.noPull, Pins.AF0);
    
    blink := FALSE;
    t0 := SysTick.GetTicks();
    
    BoardConfig.InitUart(bus, 19200, Uart.parityNone, Uart.stopBits1);
    Debug.Init(cli);
    TRACE("Start");
    REPEAT
        Machine.Idle;
        IF blink & (SysTick.GetTicks() - t0 > BLINK) THEN
            pin.Toggle;
            t0 := SysTick.GetTicks();
        END;
        IF (bus.Any() > 0) & bus.TXDone() THEN
            IF bus.ReadChar(x) THEN
                cli.ProcessChar(x)
            END;
        END;
    UNTIL FALSE
END Test.